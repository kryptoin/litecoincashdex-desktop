#!/usr/bin/env bash
# macOS build: Qt5/cmake/ninja from Anaconda3 (/opt/anaconda3); boost and other
# native libs from Homebrew only (no Homebrew Qt).
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${ROOT_DIR}/build-macos-anaconda3"
: "${CMAKE_BUILD_TYPE:=Release}"
export CMAKE_BUILD_TYPE
export CMAKE_OSX_ARCHITECTURES="arm64"
export CMAKE_OSX_DEPLOYMENT_TARGET="11.0"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
unset DYLD_INSERT_LIBRARIES

# --- Anaconda3 (Qt5 + cmake/ninja) ---
# Note: Qt5 is installed in /opt/anaconda3 via `conda install qt=5.15.9`
# See docs/python-version.md for details on the dual conda environment setup.
ANACONDA_PREFIX="/opt/anaconda3"
QT_PREFIX="${ANACONDA_PREFIX}"
CMAKE_BIN="${ANACONDA_PREFIX}/bin/cmake"
NINJA_BIN="${ANACONDA_PREFIX}/bin/ninja"

# Anaconda's qt5 package layout: locate qmake and the Qt5 CMake config directory
QT_QMAKE="$(find "${ANACONDA_PREFIX}/bin" -maxdepth 1 -type f \( -iname "qmake" \) 2>/dev/null | head -n1)"
QT_CMAKE_CONFIG="$(find "${ANACONDA_PREFIX}/lib" -maxdepth 4 -iname "Qt5Config.cmake" 2>/dev/null | head -n1)"
QT_CMAKE_DIR="$(dirname "${QT_CMAKE_CONFIG:-}")"

if [ -z "${QT_QMAKE}" ] || [ ! -x "${QT_QMAKE}" ]; then
  echo "Anaconda3 Qt5 qmake not found under ${ANACONDA_PREFIX}/bin; please install qt into anaconda3, e.g.:" >&2
  echo "  conda install -p /opt/anaconda3 qt=5.15.9 cmake ninja" >&2
  exit 1
fi
if [ -z "${QT_CMAKE_CONFIG:-}" ] || [ ! -d "${QT_CMAKE_DIR}" ]; then
  echo "Qt5Config.cmake not found anywhere under ${ANACONDA_PREFIX}/lib; please install qt into anaconda3, e.g.:" >&2
  echo "  conda install -p /opt/anaconda3 qt=5.15.9 cmake ninja" >&2
  exit 1
fi
if [ ! -x "${CMAKE_BIN}" ]; then
  echo "Anaconda3 cmake not found at ${CMAKE_BIN}; install it with: conda install -p /opt/anaconda3 cmake" >&2
  exit 1
fi
if [ ! -x "${NINJA_BIN}" ]; then
  echo "Anaconda3 ninja not found at ${NINJA_BIN}; install it with: conda install -p /opt/anaconda3 ninja" >&2
  exit 1
fi

# --- Homebrew (boost + misc libs only, no Qt) ---
if command -v brew >/dev/null 2>&1; then
  HOMEBREW_PREFIX="$(brew --prefix)"
else
  echo "Homebrew not found; install it first: https://brew.sh" >&2
  exit 1
fi

# Strip any old miniconda3, ~/Qt, homebrew qt@5, or stale anaconda3 entries from PATH
export PATH="$(echo "$PATH" | tr ':' '\n' | grep -vE "(^${HOME}/miniconda3($|/)|^${HOME}/Qt($|/)|^${HOMEBREW_PREFIX}/Cellar/qt@5($|/)|^${HOMEBREW_PREFIX}/opt/qt@5($|/)|^${ANACONDA_PREFIX}($|/))" | tr '\n' ':')"
export PATH="${ANACONDA_PREFIX}/bin:${HOMEBREW_PREFIX}/bin:${PATH}"

# QT_CMAKE_ROOT is the "cmake" directory that holds Qt5/, Qt5WebEngineCore/, etc.
QT_CMAKE_ROOT="$(dirname "${QT_CMAKE_DIR}")"
export Qt5_DIR="${QT_CMAKE_DIR}"
export QT_ROOT="${QT_PREFIX}"
export QT_INSTALL_CMAKE_PATH="${QT_CMAKE_ROOT}"
# Qt5 WebEngine cmake packages
for comp in Qt5WebEngineCore Qt5WebEngineWidgets Qt5WebChannel; do
  if [ -d "${QT_CMAKE_ROOT}/${comp}" ]; then
    export "${comp}_DIR=${QT_CMAKE_ROOT}/${comp}"
  fi
done
export QT_PLUGIN_PATH="${ANACONDA_PREFIX}/plugins"
export QT_QPA_PLATFORM_PLUGIN_PATH="${ANACONDA_PREFIX}/plugins/platforms"
export QMAKE="${QT_QMAKE}"
export QML2_IMPORT_PATH="${ANACONDA_PREFIX}/qml"
export QML_IMPORT_PATH="${ANACONDA_PREFIX}/qml"

export CMAKE_PREFIX_PATH="${QT_CMAKE_ROOT}:${ANACONDA_PREFIX}:${HOMEBREW_PREFIX}/opt/boost@1.85:${HOMEBREW_PREFIX}/opt/boost@1.85/lib/cmake:${HOMEBREW_PREFIX}/opt/entt/lib/EnTT/cmake"
export PKG_CONFIG_PATH="${HOMEBREW_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export LDFLAGS="-L${HOMEBREW_PREFIX}/lib ${LDFLAGS:-}"
export CPPFLAGS="-I${HOMEBREW_PREFIX}/include -I${HOMEBREW_PREFIX}/opt/entt/include ${CPPFLAGS:-}"
export fmt_DIR="${HOMEBREW_PREFIX}/lib/cmake/fmt"
export spdlog_DIR="${HOMEBREW_PREFIX}/lib/cmake/spdlog"
export BOOST_ROOT="${HOMEBREW_PREFIX}/opt/boost@1.85"
export Boost_ROOT="${HOMEBREW_PREFIX}/opt/boost@1.85"
export Boost_NO_BOOST_CMAKE=OFF
export Boost_DIR="${HOMEBREW_PREFIX}/opt/boost@1.85/lib/cmake"
export Boost_NO_SYSTEM_PATHS=ON
export CMAKE_FIND_PACKAGE_PREFER_CONFIG=ON

# Make sure a stray conda env activation doesn't fight with the base anaconda3 paths above
unset CONDA_PREFIX CONDA_DEFAULT_ENV CONDA_SHLVL
export SSL_CERT_FILE="${ANACONDA_PREFIX}/ssl/cert.pem"

for pkg in boost fmt nlohmann-json spdlog range-v3 cpprestsdk doctest entt libsodium openssl howard-hinnant-date secp256k1 taskflow pkg-config; do
  if brew info "$pkg" >/dev/null 2>&1; then
    echo "Installing Homebrew package: $pkg"
    brew install "$pkg" >/dev/null 2>&1 || true
  else
    echo "Skipping unavailable Homebrew package: $pkg"
  fi
done

"${CMAKE_BIN}" -S "${ROOT_DIR}" -B "${BUILD_DIR}" \
  -G Ninja \
  -DCMAKE_MAKE_PROGRAM="${NINJA_BIN}" \
  -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
  -DCMAKE_OSX_ARCHITECTURES="${CMAKE_OSX_ARCHITECTURES}" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="${CMAKE_OSX_DEPLOYMENT_TARGET}" \
  -DCMAKE_PREFIX_PATH="${QT_CMAKE_ROOT}:${ANACONDA_PREFIX}:${HOMEBREW_PREFIX}/opt/boost@1.85" \
  -DQT_QMAKE_EXECUTABLE="${QT_QMAKE}" \
  -DQt5_DIR="${QT_CMAKE_DIR}" \
  -Dfmt_DIR="${HOMEBREW_PREFIX}/lib/cmake/fmt" \
  -Dspdlog_DIR="${HOMEBREW_PREFIX}/lib/cmake/spdlog" \
  -DAD_SKIP_FETCHCONTENT=OFF

echo
echo "Configured build directory: ${BUILD_DIR}"
echo "App bundle should be at: ${BUILD_DIR}/bin/litecoincashdex.app"

# Build the project
echo
echo "Building..."
"${NINJA_BIN}" -C "${BUILD_DIR}" -j"$(sysctl -n hw.ncpu)" 2>&1
echo
echo "Build complete. App bundle should be at: ${BUILD_DIR}/bin/litecoincashdex.app"

# copy kdf each build
cp assets/tools/kdf/mm2_cheetah \
   build-macos-anaconda3/bin/litecoincashdex.app/Contents/Resources/assets/tools/kdf/mm2_cheetah
chmod +x build-macos-anaconda3/bin/litecoincashdex.app/Contents/Resources/assets/tools/kdf/mm2_cheetah
