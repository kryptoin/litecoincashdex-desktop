#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${ROOT_DIR}/build-macos-homebrew"
: "${CMAKE_BUILD_TYPE:=Release}"

export CMAKE_BUILD_TYPE
export CMAKE_OSX_ARCHITECTURES="arm64"
export CMAKE_OSX_DEPLOYMENT_TARGET="11.0"

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

unset DYLD_INSERT_LIBRARIES

if command -v brew >/dev/null 2>&1; then
  HOMEBREW_PREFIX="$(brew --prefix)"
  QT_PREFIX="$HOME/miniconda3/envs/magenta_env"
  QT_QMAKE="${QT_PREFIX}/bin/qmake"
  QT_CMAKE_DIR="${QT_PREFIX}/lib/cmake/Qt5"

  if [ -x "${QT_QMAKE}" ]; then
    echo "Using Anaconda Qt from ${QT_PREFIX}"
  else
    echo "Anaconda Qt qmake not found; falling back to Homebrew Qt" >&2
    QT_PREFIX="$(brew --prefix qt@5)"
    QT_QMAKE="${QT_PREFIX}/bin/qmake"
    QT_CMAKE_DIR="${QT_PREFIX}/lib/cmake/Qt5"
  fi

  export PATH="$(echo "$PATH" | tr ':' '\n' | grep -vE '(/opt/homebrew/opt/qt@5($|/)|/opt/homebrew/Cellar/qt@5($|/))' | tr '\n' ':')"
  export PATH="${QT_PREFIX}/bin:${HOMEBREW_PREFIX}/bin:${PATH}"

  export Qt5_DIR="${QT_CMAKE_DIR}"
  export QT_ROOT="${QT_PREFIX}"
  export QT_INSTALL_CMAKE_PATH="${QT_PREFIX}/lib/cmake"
  export Qt5WebEngine_DIR="${QT_PREFIX}/lib/cmake/Qt5WebEngine"
  export QT_PLUGIN_PATH="${QT_PREFIX}/plugins"
  export QT_QPA_PLATFORM_PLUGIN_PATH="${QT_PREFIX}/plugins/platforms"
  export QMAKE="${QT_QMAKE}"

  export CMAKE_PREFIX_PATH="${HOMEBREW_PREFIX}:${HOMEBREW_PREFIX}/opt/boost@1.85:${HOMEBREW_PREFIX}/opt/boost@1.85/lib/cmake:${HOMEBREW_PREFIX}/opt/entt/lib/EnTT/cmake:${QT_PREFIX}"
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
  export QML2_IMPORT_PATH="${QT_PREFIX}/qml"
  export QML_IMPORT_PATH="${QT_PREFIX}/qml"
  unset CONDA_PREFIX CONDA_DEFAULT_ENV CONDA_SHLVL

  for pkg in cmake ninja pkg-config boost fmt nlohmann-json spdlog range-v3 cpprestsdk doctest entt libsodium openssl howard-hinnant-date secp256k1 taskflow; do
    if brew info "$pkg" >/dev/null 2>&1; then
      echo "Installing Homebrew package: $pkg"
      brew install "$pkg" >/dev/null 2>&1 || true
    else
      echo "Skipping unavailable Homebrew package: $pkg"
    fi
  done
else
  echo "Homebrew not found; install it first: https://brew.sh" >&2
  exit 1
fi

cmake -S "${ROOT_DIR}" -B "${BUILD_DIR}" \
  -G Ninja \
  -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
  -DCMAKE_OSX_ARCHITECTURES="${CMAKE_OSX_ARCHITECTURES}" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="${CMAKE_OSX_DEPLOYMENT_TARGET}" \
  -DCMAKE_PREFIX_PATH="${HOMEBREW_PREFIX}:${QT_PREFIX}:${HOMEBREW_PREFIX}/opt/boost@1.85" \
  -DQT_QMAKE_EXECUTABLE="${QT_QMAKE}" \
  -DQt5_DIR="${QT_CMAKE_DIR}" \
  -Dfmt_DIR="${HOMEBREW_PREFIX}/lib/cmake/fmt" \
  -Dspdlog_DIR="${HOMEBREW_PREFIX}/lib/cmake/spdlog" \
  -DAD_SKIP_FETCHCONTENT=OFF
echo
echo "Configured build directory: ${BUILD_DIR}"
echo "Binary should be at: ${BUILD_DIR}/bin/litecoincashdex"
