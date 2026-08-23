#!/usr/bin/env bash
# ===========================================================================
#  build-macos-apple-silicon.sh
#
#  macOS build script for ANY Apple Silicon Mac (M1, M2, M3, M4, M5, …).
#  • Qt5 + Qt5WebEngine come exclusively from /opt/anaconda3 (conda-forge).
#  • cmake and ninja are taken from Homebrew (or Anaconda if present).
#  • boost, fmt, spdlog, and all other native C++ libs come from Homebrew.
#
#  Usage:
#    chmod +x build-macos-apple-silicon.sh
#    ./build-macos-apple-silicon.sh            # Release build (default)
#    CMAKE_BUILD_TYPE=Debug ./build-macos-apple-silicon.sh   # Debug build
#    ./build-macos-apple-silicon.sh --refresh-coins          # re-fetch GLEECBTC/coins
# ===========================================================================
set -euo pipefail

# ── helpers ─────────────────────────────────────────────────────────────────
log()  { printf '\033[1;36m>>> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!!! %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# ── CLI flags ─────────────────────────────────────────────────────────────────
#   --refresh-coins   Force a fresh checkout of vendor/coins (GLEECBTC/coins)
#                     before building, so the bundled coin list / electrum
#                     registry reflects the latest weekly changes.
REFRESH_COINS=0
for arg in "$@"; do
    case "$arg" in
        --refresh-coins) REFRESH_COINS=1 ;;
        -h|--help)
            echo "Usage: $0 [--refresh-coins]"
            echo "  --refresh-coins   Re-fetch vendor/coins (GLEECBTC/coins) so the bundled"
            echo "                     coin configuration is up to date before building."
            exit 0 ;;
        *) die "Unknown argument: $arg (use --help for usage)" ;;
    esac
done

# ── Apple-Silicon detection ─────────────────────────────────────────────────
ARCH="$(uname -m)"
[ "$ARCH" = "arm64" ] || die "This script is for Apple Silicon only (got arch=$ARCH)."

# Detect the specific chip for informational purposes
CHIP_BRAND="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'Unknown Apple Silicon')"
log "Detected Apple Silicon: ${CHIP_BRAND}  (arch=${ARCH})"

# Verify we are on macOS
[ "$(uname -s)" = "Darwin" ] || die "This script is macOS-only."
MACOS_VERSION="$(sw_vers -productVersion 2>/dev/null || echo 'unknown')"
log "macOS version: ${MACOS_VERSION}"

# ── project root & build dir ───────────────────────────────────────────────
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${ROOT_DIR}/build-macos-apple-silicon"
: "${CMAKE_BUILD_TYPE:=Release}"
export CMAKE_BUILD_TYPE
export CMAKE_OSX_ARCHITECTURES="arm64"
export CMAKE_OSX_DEPLOYMENT_TARGET="11.0"

log "Project root : ${ROOT_DIR}"
log "Build dir    : ${BUILD_DIR}"
log "Build type   : ${CMAKE_BUILD_TYPE}"

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
unset DYLD_INSERT_LIBRARIES 2>/dev/null || true

# ── Anaconda3 (Qt5 + Qt5WebEngine) ─────────────────────────────────────────
# The ONLY Qt5 that works for this project lives in /opt/anaconda3.
# Homebrew Qt and miniconda Qt are NOT sufficient (missing WebEngine, wrong
# rpath layout, or version mismatches).
ANACONDA_PREFIX="/opt/anaconda3"
[ -d "${ANACONDA_PREFIX}" ] || die "Anaconda3 not found at ${ANACONDA_PREFIX}. Install it from https://www.anaconda.com/download"

# Prefer a dedicated conda env with a *single aligned* Qt version (e.g.
# qt-main 5.15.15 + qt-webengine 5.15.15) because a mismatched pair in the
# base env (e.g. qt-main 5.15.2 + qt-webengine 5.15.9) crashes QtWebEngine's
# GPU thread at runtime. Create it with:
#   conda create -p /opt/anaconda3/envs/qt51515 -c conda-forge \
#       "qt-main=5.15.15" "qt-webengine=5.15.15"
QT_ENVS=(
    "${ANACONDA_PREFIX}/envs/qt51515"
    "${ANACONDA_PREFIX}/envs/qt51512"
    "${ANACONDA_PREFIX}"
)
QT_PREFIX=""
for candidate in "${QT_ENVS[@]}"; do
    if [ -x "${candidate}/bin/qmake" ] && [ -f "${candidate}/lib/cmake/Qt5/Qt5Config.cmake" ]; then
        QT_PREFIX="${candidate}"
        break
    fi
done
if [ -z "${QT_PREFIX}" ]; then
    die "No suitable Qt5 found under ${ANACONDA_PREFIX}.
Create an aligned Qt env with:
  conda create -p /opt/anaconda3/envs/qt51515 -c conda-forge 'qt-main=5.15.15' 'qt-webengine=5.15.15'"
fi
log "Qt prefix       : ${QT_PREFIX}"

# ---- Locate Qt5 cmake config ------------------------------------------
QT_CMAKE_CONFIG="$(find "${QT_PREFIX}/lib" -maxdepth 5 -name "Qt5Config.cmake" 2>/dev/null | head -n1)"
if [ -z "${QT_CMAKE_CONFIG:-}" ]; then
    die "Qt5Config.cmake not found under ${QT_PREFIX}/lib.
Install Qt5 into the env with:
  conda create -p /opt/anaconda3/envs/qt51515 -c conda-forge 'qt-main=5.15.15' 'qt-webengine=5.15.15'"
fi
QT_CMAKE_DIR="$(dirname "${QT_CMAKE_CONFIG}")"
QT_CMAKE_ROOT="$(dirname "${QT_CMAKE_DIR}")"
log "Qt5Config.cmake : ${QT_CMAKE_CONFIG}"
log "Qt5 cmake root  : ${QT_CMAKE_ROOT}"

# ---- Locate qmake -----------------------------------------------------
QT_QMAKE=""
for candidate in "${QT_PREFIX}/bin/qmake" "${QT_PREFIX}/bin/bin/qmake"; do
    if [ -x "$candidate" ]; then QT_QMAKE="$candidate"; break; fi
done
[ -n "${QT_QMAKE}" ] || die "qmake not found in ${QT_PREFIX}. Install qt-main into the env."
log "qmake           : ${QT_QMAKE}"

# ---- Verify Qt5 libraries exist ---------------------------------------
if [ ! -f "${QT_PREFIX}/lib/libQt5Core.dylib" ]; then
    die "Qt5 libraries missing from ${QT_PREFIX}/lib.
Install with: conda create -p /opt/anaconda3/envs/qt51515 -c conda-forge 'qt-main=5.15.15' 'qt-webengine=5.15.15'"
fi
QT_VERSION="$("${QT_QMAKE}" -query QT_VERSION 2>/dev/null || echo 'unknown')"
log "Qt5 version     : ${QT_VERSION}"

# ── cmake and ninja ────────────────────────────────────────────────────────
# Prefer Anaconda versions if they exist, otherwise fall back to Homebrew.
CMAKE_BIN=""
NINJA_BIN=""
for p in "${ANACONDA_PREFIX}/bin/cmake" "$(command -v cmake 2>/dev/null || true)"; do
    if [ -n "$p" ] && [ -x "$p" ]; then CMAKE_BIN="$p"; break; fi
done
for p in "${ANACONDA_PREFIX}/bin/ninja" "$(command -v ninja 2>/dev/null || true)"; do
    if [ -n "$p" ] && [ -x "$p" ]; then NINJA_BIN="$p"; break; fi
done
[ -n "${CMAKE_BIN}" ] || die "cmake not found. Install via: brew install cmake"
[ -n "${NINJA_BIN}" ] || die "ninja not found. Install via: brew install ninja"
log "cmake           : ${CMAKE_BIN}  ($("${CMAKE_BIN}" --version | head -1))"
log "ninja           : ${NINJA_BIN}  ($(${NINJA_BIN} --version))"

# ── Homebrew (boost + misc native libs, NO Qt) ─────────────────────────────
if command -v brew >/dev/null 2>&1; then
    HOMEBREW_PREFIX="$(brew --prefix)"
else
    die "Homebrew not found. Install it from https://brew.sh"
fi
log "Homebrew prefix : ${HOMEBREW_PREFIX}"

# ── Detect best Boost version ──────────────────────────────────────────────
# Try boost@1.85 first (the version the project was developed against),
# then fall back to whatever versioned or unversioned boost is available.
BOOST_PREFIX=""
for candidate in \
    "${HOMEBREW_PREFIX}/opt/boost@1.85" \
    "${HOMEBREW_PREFIX}/opt/boost@1.86" \
    "${HOMEBREW_PREFIX}/opt/boost@1.87" \
    "${HOMEBREW_PREFIX}/opt/boost@1.88" \
    "${HOMEBREW_PREFIX}/opt/boost@1.90" \
    "${HOMEBREW_PREFIX}/opt/boost"; do
    if [ -d "$candidate/lib" ] && [ -d "$candidate/include" ]; then
        BOOST_PREFIX="$candidate"
        break
    fi
done
[ -n "${BOOST_PREFIX}" ] || die "No Boost installation found in Homebrew. Install with: brew install boost"
BOOST_VERSION_HEADER="${BOOST_PREFIX}/include/boost/version.hpp"
if [ -f "${BOOST_VERSION_HEADER}" ]; then
    BOOST_VER="$(grep '#define BOOST_LIB_VERSION' "${BOOST_VERSION_HEADER}" 2>/dev/null | head -1 | awk '{print $3}' | tr -d '"')"
else
    BOOST_VER="unknown"
fi
log "Boost prefix    : ${BOOST_PREFIX}  (version: ${BOOST_VER})"

# ── Sanitise PATH ──────────────────────────────────────────────────────────
# Remove miniconda3, ~/Qt, homebrew qt@5, and stale paths to avoid conflicts
export PATH="$(echo "$PATH" | tr ':' '\n' \
  | grep -vE "(^${HOME}/miniconda3($|/)|^${HOME}/Qt($|/)|^${HOMEBREW_PREFIX}/Cellar/qt@5($|/)|^${HOMEBREW_PREFIX}/opt/qt@5($|/))" \
  | tr '\n' ':')"
export PATH="${QT_PREFIX}/bin:${ANACONDA_PREFIX}/bin:${HOMEBREW_PREFIX}/bin:${PATH}"

# ── Qt5 environment variables ──────────────────────────────────────────────
export Qt5_DIR="${QT_CMAKE_DIR}"
export QT_ROOT="${QT_PREFIX}"
export QT_INSTALL_CMAKE_PATH="${QT_CMAKE_ROOT}"

# Qt5 WebEngine cmake packages
for comp in Qt5WebEngineCore Qt5WebEngineWidgets Qt5WebChannel Qt5WebEngine; do
    if [ -d "${QT_CMAKE_ROOT}/${comp}" ]; then
        export "${comp}_DIR=${QT_CMAKE_ROOT}/${comp}"
        log "  ${comp}_DIR -> ${QT_CMAKE_ROOT}/${comp}"
    fi
done

# Qt plugin / QML paths — detect actual locations from qmake
QT_PLUGIN_DIR="$("${QT_QMAKE}" -query QT_INSTALL_PLUGINS 2>/dev/null || echo "${QT_PREFIX}/plugins")"
QT_QML_DIR="$("${QT_QMAKE}" -query QT_INSTALL_QML 2>/dev/null || echo "${QT_PREFIX}/qml")"
export QT_PLUGIN_PATH="${QT_PLUGIN_DIR}"
export QT_QPA_PLATFORM_PLUGIN_PATH="${QT_PLUGIN_DIR}/platforms"
export QMAKE="${QT_QMAKE}"
export QML2_IMPORT_PATH="${QT_QML_DIR}"
export QML_IMPORT_PATH="${QT_QML_DIR}"

# ── CMAKE_PREFIX_PATH & pkg-config ─────────────────────────────────────────
export CMAKE_PREFIX_PATH="${QT_CMAKE_ROOT}:${QT_PREFIX}:${BOOST_PREFIX}:${BOOST_PREFIX}/lib/cmake:${HOMEBREW_PREFIX}/opt/entt/lib/EnTT/cmake"
export PKG_CONFIG_PATH="${HOMEBREW_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export LDFLAGS="-L${HOMEBREW_PREFIX}/lib ${LDFLAGS:-}"
export CPPFLAGS="-I${HOMEBREW_PREFIX}/include -I${HOMEBREW_PREFIX}/opt/entt/include ${CPPFLAGS:-}"
export fmt_DIR="${HOMEBREW_PREFIX}/lib/cmake/fmt"
export spdlog_DIR="${HOMEBREW_PREFIX}/lib/cmake/spdlog"
export BOOST_ROOT="${BOOST_PREFIX}"
export Boost_ROOT="${BOOST_PREFIX}"
export Boost_NO_BOOST_CMAKE=OFF
export Boost_DIR="${BOOST_PREFIX}/lib/cmake"
export Boost_NO_SYSTEM_PATHS=ON
export CMAKE_FIND_PACKAGE_PREFER_CONFIG=ON

# Prevent stray conda env activation from fighting with paths
unset CONDA_PREFIX CONDA_DEFAULT_ENV CONDA_SHLVL 2>/dev/null || true
export SSL_CERT_FILE="${ANACONDA_PREFIX}/ssl/cert.pem"

# ── Install Homebrew dependencies (idempotent) ─────────────────────────────
log "Checking / installing Homebrew dependencies..."
BREW_DEPS=(
    boost fmt nlohmann-json spdlog range-v3 cpprestsdk doctest entt
    libsodium openssl howard-hinnant-date secp256k1 taskflow pkg-config cmake ninja
)
for pkg in "${BREW_DEPS[@]}"; do
    if brew list --formula "$pkg" >/dev/null 2>&1; then
        : # already installed
    elif brew info "$pkg" >/dev/null 2>&1; then
        log "  Installing ${pkg}..."
        brew install "$pkg" >/dev/null 2>&1 || warn "brew install ${pkg} failed (non-fatal)"
    else
        warn "  Skipping unavailable Homebrew package: ${pkg}"
    fi
done

# ── Build libwallycore if not installed ───────────────────────────────────
WALLY_INSTALL_DIR="${ROOT_DIR}/libwally-core-install"
if [ ! -f "${WALLY_INSTALL_DIR}/lib/libwallycore.a" ]; then
    log "libwallycore not found in ${WALLY_INSTALL_DIR}. Building libwallycore..."
    WALLY_BUILD_DIR="${ROOT_DIR}/build-macos-lwc-r1.5.6"
    [ -d "${WALLY_BUILD_DIR}" ] || die "libwally-core source not found at ${WALLY_BUILD_DIR}"
    (
        cd "${WALLY_BUILD_DIR}"
        ln -sf _CMakeLists.txt CMakeLists.txt
        ln -sf _cmake cmake
        ln -sf _CMakeLists.txt src/CMakeLists.txt
        # Clone secp256k1-zkp submodule if missing
        if [ ! -f "src/secp256k1/CMakeLists.txt" ]; then
            log "secp256k1-zkp submodule missing. Cloning..."
            rm -rf src/secp256k1
            git clone --depth 1 https://github.com/BlockstreamResearch/secp256k1-zkp.git src/secp256k1
        fi
        # Download missing headers from upstream libwally-core 1.5.6
        # (The local source tree is missing these)
        for hdr in wally_address.h wally_script.h wally_transaction.h; do
            if [ ! -f "include/${hdr}" ]; then
                log "Downloading missing header: ${hdr}"
                curl -sL "https://raw.githubusercontent.com/ElementsProject/libwally-core/release_1.5.6/include/${hdr}" -o "include/${hdr}"
            fi
        done
        rm -rf build
        "${CMAKE_BIN}" -S . -B build \
            -DCMAKE_INSTALL_PREFIX="${WALLY_INSTALL_DIR}" \
            -DWALLYCORE_INSTALL=ON \
            -DCMAKE_OSX_ARCHITECTURES="arm64"
        "${CMAKE_BIN}" --build build --target install
    )
    log "libwallycore build completed."
fi

# ── detect install_name_tool ───────────────────────────────────────────────
INSTALL_NAME_TOOL="$(command -v install_name_tool 2>/dev/null || echo "${ANACONDA_PREFIX}/bin/install_name_tool")"
[ -x "${INSTALL_NAME_TOOL}" ] || INSTALL_NAME_TOOL="/usr/bin/install_name_tool"
log "install_name_tool: ${INSTALL_NAME_TOOL}"

# ── Download / verify KDF daemon (mm2_cheetah) ──────────────────────────────
# The KDF daemon is a precompiled binary published separately from the main
# app. We download (or reuse a cached copy) and store it in
#   assets/tools/kdf/mm2_cheetah
# so that it is available for bundling and for future rebuilds.
KDF_BINARY_URL="https://github.com/GLEECBTC/komodo-defi-framework/releases/download/v2.6.0-beta/kdf-macos-universal2-475cdb4.zip"
KDF_BINARY_PATH="${ROOT_DIR}/assets/tools/kdf/mm2_cheetah"
KDF_BINARY_SHA="475cdb4"  # Used as a marker / version identifier

if [ -f "${KDF_BINARY_PATH}" ]; then
    log "KDF daemon (mm2_cheetah) already present at ${KDF_BINARY_PATH}"
else
    log "KDF daemon (mm2_cheetah) not found. Downloading from ${KDF_BINARY_URL}..."
    mkdir -p "${ROOT_DIR}/assets/tools/kdf"
    KDF_ZIP_TMP="$(mktemp -d)/kdf-macos-universal2.zip"
    TMP_EXTRACT_DIR="$(dirname ${KDF_ZIP_TMP})"
    if curl -fL --progress-bar -o "${KDF_ZIP_TMP}" "${KDF_BINARY_URL}"; then
        log "Extracting KDF daemon from zip..."
        unzip -o "${KDF_ZIP_TMP}" -d "${TMP_EXTRACT_DIR}"
        # The zip may contain the binary named 'kdf' or 'mm2_cheetah', possibly inside a subdirectory
        FOUND_KDF="$(find "${TMP_EXTRACT_DIR}" -type f \( -name "kdf" -o -name "mm2_cheetah" \) ! -name "*.txt" ! -name "*.md" | head -n1)"
        if [ -n "${FOUND_KDF}" ]; then
            cp "${FOUND_KDF}" "${KDF_BINARY_PATH}"
            chmod +x "${KDF_BINARY_PATH}"
            log "KDF daemon placed at ${KDF_BINARY_PATH}"
        else
            rm -rf "${TMP_EXTRACT_DIR}"
            rm -f "${KDF_ZIP_TMP}"
            die "KDF daemon binary not found inside downloaded zip. The zip may use a different filename. Please download it manually from ${KDF_BINARY_URL} and place it at ${KDF_BINARY_PATH}"
        fi
        rm -f "${KDF_ZIP_TMP}"
        rm -rf "${TMP_EXTRACT_DIR}"
    else
        rm -f "${KDF_ZIP_TMP}"
        rm -rf "${TMP_EXTRACT_DIR}"
        die "Failed to download KDF daemon from ${KDF_BINARY_URL}. Please download it manually and place at ${KDF_BINARY_PATH}"
    fi
fi

[ -f "${KDF_BINARY_PATH}" ] || die "KDF daemon (mm2_cheetah) is required at ${KDF_BINARY_PATH}. Cannot continue."
log "KDF daemon  : ${KDF_BINARY_PATH}  (arch: $(file -b "${KDF_BINARY_PATH}" | awk '{print $2" "$4}'))"

# ── Clone vendor/coins submodule content ────────────────────────────────────
# This project is not always checked out as a git repo, so the `vendor/coins`
# git submodule (GLEECBTC/coins, a fork of jl777/coins) may be empty.  Clone it
# directly so the build has access to utils/coins_config_tcp.json, coins, and
# icons/.  We only do this if the required file is missing.
COINS_SUBMODULE_DIR="${ROOT_DIR}/vendor/coins"
COINS_SUBMODULE_URL="https://github.com/GLEECBTC/coins.git"

# --refresh-coins: discard any existing checkout so we re-fetch the latest
# weekly coin list / electrum registry instead of reusing a stale one.
if [ "${REFRESH_COINS}" -eq 1 ] && [ -d "${COINS_SUBMODULE_DIR}" ]; then
    log "Refresh requested: removing existing vendor/coins checkout..."
    rm -rf "${COINS_SUBMODULE_DIR}"
fi

if [ -f "${COINS_SUBMODULE_DIR}/utils/coins_config_tcp.json" ]; then
    log "vendor/coins already populated."
else
    log "vendor/coins submodule missing. Cloning from ${COINS_SUBMODULE_URL}..."
    rm -rf "${COINS_SUBMODULE_DIR}"
    mkdir -p "${COINS_SUBMODULE_DIR}"
    git clone --depth 1 "${COINS_SUBMODULE_URL}" "${COINS_SUBMODULE_DIR}" || \
        die "Failed to clone vendor/coins from ${COINS_SUBMODULE_URL}. Please populate it manually."
    [ -f "${COINS_SUBMODULE_DIR}/utils/coins_config_tcp.json" ] || \
        die "vendor/coins cloned but utils/coins_config_tcp.json still missing."
    log "vendor/coins populated."
fi

# ══════════════════════════════════════════════════════════════════════════
#  CONFIGURE
# ══════════════════════════════════════════════════════════════════════════
log "Configuring with cmake..."
"${CMAKE_BIN}" -S "${ROOT_DIR}" -B "${BUILD_DIR}" \
    -G Ninja \
    -DCMAKE_MAKE_PROGRAM="${NINJA_BIN}" \
    -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
    -DCMAKE_OSX_ARCHITECTURES="${CMAKE_OSX_ARCHITECTURES}" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${CMAKE_OSX_DEPLOYMENT_TARGET}" \
    -DCMAKE_PREFIX_PATH="${QT_CMAKE_ROOT};${QT_PREFIX};${BOOST_PREFIX}" \
    -DQT_QMAKE_EXECUTABLE="${QT_QMAKE}" \
    -DQt5_DIR="${QT_CMAKE_DIR}" \
    -Dfmt_DIR="${HOMEBREW_PREFIX}/lib/cmake/fmt" \
    -Dspdlog_DIR="${HOMEBREW_PREFIX}/lib/cmake/spdlog" \
    -DAD_SKIP_FETCHCONTENT=OFF

log "Configured.  Build dir: ${BUILD_DIR}"
log "App bundle will be at : ${BUILD_DIR}/bin/litecoincashdex.app"

# ══════════════════════════════════════════════════════════════════════════
#  BUILD
# ══════════════════════════════════════════════════════════════════════════
NCPU="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
log "Building with ${NCPU} parallel jobs..."
"${NINJA_BIN}" -C "${BUILD_DIR}" -j"${NCPU}" 2>&1
log "Build complete."

# ══════════════════════════════════════════════════════════════════════════
#  POST-BUILD: bundle KDF, QtWebEngine, QML, codesign
# ══════════════════════════════════════════════════════════════════════════
APP_BUNDLE="${BUILD_DIR}/bin/litecoincashdex.app"

# ── Copy KDF binary ────────────────────────────────────────────────────────
if [ -f "${ROOT_DIR}/assets/tools/kdf/mm2_cheetah" ]; then
    log "Copying KDF (mm2_cheetah) into app bundle..."
    sleep 1
    mkdir -p "${APP_BUNDLE}/Contents/Resources/assets/tools/kdf"
    cp "${ROOT_DIR}/assets/tools/kdf/mm2_cheetah" \
       "${APP_BUNDLE}/Contents/Resources/assets/tools/kdf/mm2_cheetah"
    chmod +x "${APP_BUNDLE}/Contents/Resources/assets/tools/kdf/mm2_cheetah"

    # The --deep codesign below does NOT individually sign binaries that live
    # under Contents/Resources (they are treated as sealed resources, not nested
    # code).  Ad-hoc sign the KDF daemon on its own so it is a valid, runnable
    # code object when the app launches it via QProcess.  Without this, a stricter
    # Gatekeeper / hardened-runtime configuration can refuse to exec it, which
    # surfaces to the user as "KDF did not initialize".
    log "Ad-hoc signing KDF daemon binary..."
    codesign --force --sign - \
        "${APP_BUNDLE}/Contents/Resources/assets/tools/kdf/mm2_cheetah" 2>&1 \
        || warn "codesign of KDF daemon failed (non-fatal)"
fi

# ── Bundle QtWebEngineProcess ──────────────────────────────────────────────
# NOTE: the conda Qt used here is a *dylib* (non-framework) build — there is no
# QtWebEngineCore.framework.  QtWebEngine::subProcessPath() for a dylib build
# only looks for "QtWebEngineProcess" in applicationDirPath() (Contents/MacOS)
# and QLibraryInfo::LibraryExecutablesPath.  Deploying it inside a synthetic
# framework's Versions/A/Helpers/... is therefore wrong and the browser process
# dies with "Could not find QtWebEngineProcess" as soon as a web view is shown.
QTWEBENGINE_PROCESS=""
for candidate in \
    "${QT_PREFIX}/libexec/QtWebEngineProcess" \
    "$("${QT_QMAKE}" -query QT_INSTALL_LIBEXECS 2>/dev/null || true)/QtWebEngineProcess"; do
    if [ -f "$candidate" ]; then QTWEBENGINE_PROCESS="$candidate"; break; fi
done

if [ -n "${QTWEBENGINE_PROCESS}" ]; then
    log "Bundling QtWebEngineProcess to Contents/MacOS from ${QTWEBENGINE_PROCESS}..."
    mkdir -p "${APP_BUNDLE}/Contents/MacOS"
    cp "${QTWEBENGINE_PROCESS}" "${APP_BUNDLE}/Contents/MacOS/QtWebEngineProcess"
    chmod +x "${APP_BUNDLE}/Contents/MacOS/QtWebEngineProcess"
    # Ensure the Qt libs in Contents/Frameworks are resolvable from here.
    "${INSTALL_NAME_TOOL}" -add_rpath "@executable_path/../Frameworks" \
       "${APP_BUNDLE}/Contents/MacOS/QtWebEngineProcess" 2>/dev/null || true
else
    warn "QtWebEngineProcess binary not found; web views will crash at runtime"
fi

# ── Copy QtWebEngine QML imports ───────────────────────────────────────────
if [ -d "${QT_QML_DIR}" ]; then
    log "Bundling full Qt QML module tree..."
    mkdir -p "${APP_BUNDLE}/Contents/Resources/qml"
    cp -R "${QT_QML_DIR}/." "${APP_BUNDLE}/Contents/Resources/qml/"
fi

# ── Point the app at the aligned Qt at runtime ─────────────────────────────
# The binary links Qt with @rpath.  Ensure the aligned Qt env's lib dir is
# searched *first* so we never accidentally load the mismatched base-env Qt
# (e.g. qt-main 5.15.2 + qt-webengine 5.15.9) that crashes WebEngine's GPU
# thread. install_name_tool -add_rpath appends, so drop the base-env entry
# and re-add it after the aligned env to control ordering.
APP_EXE="${APP_BUNDLE}/Contents/MacOS/litecoincashdex"
if [ "${QT_PREFIX}" != "${ANACONDA_PREFIX}" ]; then
    log "Reordering app rpath: ${QT_PREFIX}/lib first (aligned Qt)..."
    "${INSTALL_NAME_TOOL}" -delete_rpath "${QT_PREFIX}/lib"      "${APP_EXE}" 2>/dev/null || true
    "${INSTALL_NAME_TOOL}" -delete_rpath "${ANACONDA_PREFIX}/lib" "${APP_EXE}" 2>/dev/null || true
    "${INSTALL_NAME_TOOL}" -add_rpath "${QT_PREFIX}/lib"         "${APP_EXE}"
    "${INSTALL_NAME_TOOL}" -add_rpath "${ANACONDA_PREFIX}/lib"    "${APP_EXE}"
fi

# ── Re-sign app bundle (ad-hoc) ───────────────────────────────────────────
log "Re-signing app bundle (ad-hoc)..."
codesign --force --deep --sign - "${APP_BUNDLE}" 2>&1

log "═══════════════════════════════════════════════════════════════"
log "BUILD SUCCESSFUL"
log "  Chip : ${CHIP_BRAND}"
log "  Qt   : ${QT_VERSION} (from ${QT_PREFIX})"
log "  Boost: ${BOOST_VER} (from ${BOOST_PREFIX})"
log "  App  : ${APP_BUNDLE}"
log "═══════════════════════════════════════════════════════════════"
