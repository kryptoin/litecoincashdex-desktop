#!/usr/bin/env bash
# ===========================================================================
#  package-macos.sh
#
#  macOS packaging script for Apple Silicon (arm64) DMG deployment.
#  Takes a built litecoincashdex.app and produces a self-contained,
#  signed, notarized DMG.
#
#  Usage:
#    ./package-macos.sh [--sign] [--notarize] [--dmg] [--all]
#
#  Prerequisites:
#    - Built app at build-macos-apple-silicon/bin/litecoincashdex.app
#    - Developer ID Application certificate in keychain (for --sign)
#    - Notarytool profile configured (for --notarize)
# ===========================================================================
set -euo pipefail

# ── helpers ─────────────────────────────────────────────────────────────────
log()   { printf '\033[1;36m>>> %s\033[0m\n' "$*"; }
warn()  { printf '\033[1;33m!!! %s\033[0m\n' "$*" >&2; }
die()   { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }
step()  { printf '\n\033[1;34m[%d/%d] %s\033[0m\n' "$STEP" "$TOTAL_STEPS" "$*"; ((STEP++)); }

# ── parse arguments ──────────────────────────────────────────────────────────
DO_QT_DEPLOY=0
DO_NATIVE_DEPS=0
DO_VERIFY=0
DO_SIGN=0
DO_NOTARIZE=0
DO_DMG=0
DO_ALL=0

for arg in "$@"; do
    case $arg in
        --qt-deploy)   DO_QT_DEPLOY=1 ;;
        --native-deps) DO_NATIVE_DEPS=1 ;;
        --verify)      DO_VERIFY=1 ;;
        --sign)        DO_SIGN=1 ;;
        --notarize)    DO_NOTARIZE=1 ;;
        --dmg)         DO_DMG=1 ;;
        --all)         DO_ALL=1 ;;
        *) die "Unknown argument: $arg" ;;
    esac
done

if [ $DO_ALL -eq 1 ]; then
    DO_QT_DEPLOY=1
    DO_NATIVE_DEPS=1
    DO_VERIFY=1
    DO_SIGN=1
    DO_NOTARIZE=1
    DO_DMG=1
fi

# If no flags given, default to full pipeline
if [ $DO_QT_DEPLOY -eq 0 ] && [ $DO_NATIVE_DEPS -eq 0 ] && [ $DO_VERIFY -eq 0 ] && [ $DO_SIGN -eq 0 ] && [ $DO_NOTARIZE -eq 0 ] && [ $DO_DMG -eq 0 ]; then
    DO_QT_DEPLOY=1
    DO_NATIVE_DEPS=1
    DO_VERIFY=1
    DO_SIGN=1
    DO_NOTARIZE=1
    DO_DMG=1
fi

# ── configuration ────────────────────────────────────────────────────────────
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${ROOT_DIR}/build-macos-apple-silicon"
APP="${BUILD_DIR}/bin/litecoincashdex.app"
MAIN_EXE="${APP}/Contents/MacOS/litecoincashdex"
KDF="${APP}/Contents/Resources/assets/tools/kdf/mm2_cheetah"
FRAMEWORKS="${APP}/Contents/Frameworks"
PLUGINS="${APP}/Contents/PlugIns"
RESOURCES="${APP}/Contents/Resources"
HELPERS="${APP}/Contents/Helpers"

HOMEBREW_PREFIX="$(brew --prefix 2>/dev/null || echo /opt/homebrew)"
ANACONDA_PREFIX="/opt/anaconda3"
MACDEPLOYQT="${ANACONDA_PREFIX}/bin/macdeployqt"

SIGNING_IDENTITY="${MACOS_SIGNING_IDENTITY:-}"
NOTARY_PROFILE="${MACOS_NOTARY_PROFILE:-}"
NOTARY_APPLE_ID="${MACOS_NOTARY_APPLE_ID:-}"
NOTARY_TEAM_ID="${MACOS_NOTARY_TEAM_ID:-}"
NOTARY_PASSWORD="${MACOS_NOTARY_PASSWORD:-}"

DIST_DIR="${ROOT_DIR}/dist"
DMG_NAME="LitecoinCashDEX-macOS-arm64.dmg"
DMG_PATH="${DIST_DIR}/${DMG_NAME}"
VERSION="${LITECOINCASHDEX_VERSION:-1.0.0}"
DMG_VOLUME_NAME="LiteCoinCashDEX ${VERSION}"

STEP=1
TOTAL_STEPS=0
[ $DO_QT_DEPLOY -eq 1 ] && ((TOTAL_STEPS++))
[ $DO_NATIVE_DEPS -eq 1 ] && ((TOTAL_STEPS++))
[ $DO_QT_DEPLOY -eq 1 ] || [ $DO_NATIVE_DEPS -eq 1 ] && ((TOTAL_STEPS++))
[ $DO_VERIFY -eq 1 ] && ((TOTAL_STEPS++))
[ $DO_SIGN -eq 1 ] && ((TOTAL_STEPS++))
[ $DO_NOTARIZE -eq 1 ] && ((TOTAL_STEPS++))
[ $DO_DMG -eq 1 ] && ((TOTAL_STEPS++))

# ── validate app exists ──────────────────────────────────────────────────────
validate_app() {
    log "Validating application bundle..."
    [ -d "$APP" ] || die "App bundle not found: $APP"
    [ -x "$MAIN_EXE" ] || die "Main executable not found or not executable: $MAIN_EXE"
    [ -x "$KDF" ] || die "KDF executable not found or not executable: $KDF"

    local main_arch="$(file -b "$MAIN_EXE")"
    echo "$main_arch" | grep -q arm64 || die "Main executable is not arm64: $main_arch"

    local kdf_arch="$(file -b "$KDF")"
    echo "$kdf_arch" | grep -q arm64 || die "KDF binary does not contain arm64 architecture"

    log "App validation passed"
    log "  Main exe: $MAIN_EXE (arm64)"
    log "  KDF:      $KDF (arm64 present)"
}

# ── Phase 1: Deploy Qt using macdeployqt ─────────────────────────────────────
deploy_qt() {
    step "Deploying Qt frameworks and plugins via macdeployqt"
    [ -x "$MACDEPLOYQT" ] || die "macdeployqt not found at $MACDEPLOYQT. Ensure Anaconda Qt is installed."

    log "Running macdeployqt on $APP..."
    "$MACDEPLOYQT" "$APP" -verbose=2

    # macdeployqt may miss some components; deploy them manually
    local QT_PREFIX="$ANACONDA_PREFIX"

    # Deploy platform plugin (required for Qt GUI apps)
    log "Deploying platform plugin..."
    mkdir -p "$PLUGINS/platforms"
    cp "$QT_PREFIX/plugins/platforms/libqcocoa.dylib" "$PLUGINS/platforms/"
    chmod 755 "$PLUGINS/platforms/libqcocoa.dylib"

    # Deploy Qt plugins deterministically.  macdeployqt only copied
    # platforms/libqcocoa.dylib in practice, but a QtWidgets/QtQuick app also
    # needs imageformats (PNG/JPEG/SVG icons), iconengines (SVG icons),
    # styles (native macOS look), generic, and platforminputcontexts.
    log "Deploying Qt plugins (imageformats, iconengines, styles, generic, platforminputcontexts)..."
    for pdir in imageformats iconengines styles generic platforminputcontexts; do
        if [ -d "$QT_PREFIX/plugins/$pdir" ]; then
            mkdir -p "$PLUGINS/$pdir"
            cp -f "$QT_PREFIX/plugins/$pdir/"*.dylib "$PLUGINS/$pdir/" 2>/dev/null || warn "No dylibs in plugins/$pdir"
        else
            warn "Qt plugin dir not found: $QT_PREFIX/plugins/$pdir"
        fi
    done

    # Deploy QtWebEngine resources + process.
    # This conda Qt is a *dylib* (non-framework) build, so QtWebEngine looks for
    # QtWebEngineProcess in applicationDirPath() (Contents/MacOS) and finds its
    # resources via qt.conf Data / Translations paths.  A synthetic
    # QtWebEngineCore.framework in Frameworks/ is never searched.
    log "Deploying QtWebEngine resources + process..."
    if [ -f "$QT_PREFIX/libexec/QtWebEngineProcess" ]; then
        cp -f "$QT_PREFIX/libexec/QtWebEngineProcess" "$APP/Contents/MacOS/QtWebEngineProcess"
        chmod 755 "$APP/Contents/MacOS/QtWebEngineProcess"
        install_name_tool -add_rpath "@executable_path/../Frameworks" \
            "$APP/Contents/MacOS/QtWebEngineProcess" 2>/dev/null || true
    fi
    # Resources live in Contents/Resources (qt.conf Data = Resources below).
    mkdir -p "$RESOURCES"
    for f in qtwebengine_resources.pak qtwebengine_resources_100p.pak \
             qtwebengine_resources_200p.pak qtwebengine_devtools_resources.pak \
             icudtl.dat; do
        [ -f "$QT_PREFIX/resources/$f" ] && cp -f "$QT_PREFIX/resources/$f" "$RESOURCES/"
    done
    # Locales: qt.conf Translations = Resources/translations.
    if [ -d "$QT_PREFIX/translations/qtwebengine_locales" ]; then
        mkdir -p "$RESOURCES/translations"
        cp -R "$QT_PREFIX/translations/qtwebengine_locales" "$RESOURCES/translations/"
    fi
    # Drop the obsolete synthetic QtWebEngineCore.framework if a previous
    # build script created one (dylib builds never use it).
    rm -rf "$FRAMEWORKS/QtWebEngineCore.framework"
    # Extend qt.conf so QLibraryInfo resolves Data/Translations inside the bundle.
    if [ -f "$RESOURCES/qt.conf" ]; then
        grep -q '^Data = ' "$RESOURCES/qt.conf" || echo "Data = Resources" >> "$RESOURCES/qt.conf"
        grep -q '^Translations = ' "$RESOURCES/qt.conf" || echo "Translations = Resources/translations" >> "$RESOURCES/qt.conf"
    fi

    # Deploy the full Qt QML module tree.  The application's QML (qrc:/Dex/main.qml)
    # imports QtQuick.Controls, QtQuick.Controls.Universal, QtQuick.Layouts,
    # Qt.labs.settings, QtCharts, QtGraphicalEffects, QtWebEngine, … at runtime, so
    # copying only QtWebEngine/QtWebChannel is NOT enough — the QML engine aborts
    # with "module ... is not installed".  Copy the whole tree (≈23 MB).
    log "Deploying full Qt QML module tree..."
    mkdir -p "$RESOURCES/qml"
    if [ -d "$QT_PREFIX/qml" ]; then
        cp -R "$QT_PREFIX/qml/." "$RESOURCES/qml/" 2>/dev/null || die "Failed to copy Qt QML modules from $QT_PREFIX/qml"
    else
        warn "No QML tree found at $QT_PREFIX/qml; QML imports will be missing at runtime"
    fi

    # Deploy additional Qt frameworks needed by platform plugin
    log "Deploying additional Qt frameworks (DBus, PrintSupport)..."
    cp "$QT_PREFIX/lib/libQt5DBus.5.dylib" "$FRAMEWORKS/"
    cp "$QT_PREFIX/lib/libQt5PrintSupport.5.dylib" "$FRAMEWORKS/"
    chmod 755 "$FRAMEWORKS/libQt5DBus.5.dylib"
    chmod 755 "$FRAMEWORKS/libQt5PrintSupport.5.dylib"

    log "Qt deployment complete"
    log "Frameworks in bundle:"
    find "$FRAMEWORKS" -maxdepth 1 -name '*.framework' -type d | sed 's|.*/||' | sort | sed 's/^/  /'
    log "Plugins in bundle:"
    find "$PLUGINS" -type f -name '*.dylib' 2>/dev/null | sed 's|.*/||' | sort | sed 's/^/  /'
}

# ── Phase 2: Deploy native (Homebrew) dependencies ───────────────────────────
deploy_native_deps() {
    step "Collecting and bundling native (Homebrew) dependencies"

    local queue=("$MAIN_EXE")
    local bundled=()
    local processed=()
    # Ensure arrays are initialized for bash 3.2 compatibility
    processed=()

    # Add all dylibs/frameworks in Frameworks to queue after Qt deploy
    while IFS= read -r -d '' f; do
        queue+=("$f")
    done < <(find "$APP" -type f \( -name '*.dylib' -o -name '*.so' \) -print0 2>/dev/null || true)

    # Add QtWebEngineProcess (dylib build: lives in Contents/MacOS)
    local qtwebengine_process="${APP}/Contents/MacOS/QtWebEngineProcess"
    [ -f "$qtwebengine_process" ] && queue+=("$qtwebengine_process")

    # Add KDF
    queue+=("$KDF")

    # Add all plugins
    while IFS= read -r -d '' f; do
        queue+=("$f")
    done < <(find "$PLUGINS" -type f -print0 2>/dev/null || true)

    log "Initial queue size: ${#queue[@]}"

    local i=0
    while [ $i -lt ${#queue[@]} ]; do
        local current="${queue[$i]}"
        ((i++))

        # Skip if already processed
        local skip=0
        if [ ${#processed[@]} -gt 0 ]; then
            for p in "${processed[@]}"; do
                [ "$p" = "$current" ] && skip=1 && break
            done
        fi
        [ $skip -eq 1 ] && continue
        processed+=("$current")

        [ -f "$current" ] || continue
        file -b "$current" | grep -q Mach-O || continue

        log "Inspecting: $current"

        local deps
        deps=$(otool -L "$current" 2>/dev/null | grep -v '^$' | grep -v ':$' | awk '{print $1}' || true)

        for dep in $deps; do
            # Skip system libraries
            case "$dep" in
                /usr/lib/*|/System/Library/*|/Library/Frameworks/*) continue ;;
                @loader_path/*|@executable_path/*) continue ;;
            esac

            # @rpath deps: Qt libs are handled by macdeployqt; other @rpath deps
            # (e.g. imageformats -> libjpeg.8.dylib) must be resolved and bundled.
            if [[ "$dep" == @rpath/* ]]; then
                local rname="${dep#@rpath/}"
                case "$rname" in
                    Qt5*.framework/*|Qt6*.framework/*) continue ;;
                    libc++.1.dylib) continue ;;
                    # conda-relative install-name of the file itself (self-reference)
                    ../*) continue ;;
                esac
                # Already bundled (macdeployqt handles the main Qt libs; anything
                # still missing — e.g. libQt5QmlWorkerScript, referenced only by
                # QML plugins — must be resolved from the Qt prefix).
                [ -f "$FRAMEWORKS/$(basename "$rname")" ] && continue
                # Resolve against known prefixes
                local resolved=""
                for c in "$ANACONDA_PREFIX/lib" "$HOMEBREW_PREFIX/lib"; do
                    [ -f "$c/$rname" ] && resolved="$c/$rname" && break
                    [ -f "$c/$(basename "$rname")" ] && resolved="$c/$(basename "$rname")" && break
                done
                if [ -z "$resolved" ]; then
                    warn "Unresolved @rpath dependency: $dep (from $current) — skipped"
                    continue
                fi
                dep="$resolved"
            fi

            # Check if already bundled
            local dep_name="$(basename "$dep")"
            local already_bundled=0
            if [ ${#bundled[@]} -gt 0 ]; then
                for b in "${bundled[@]}"; do
                    [ "$b" = "$dep_name" ] && already_bundled=1 && break
                done
            fi
            [ $already_bundled -eq 1 ] && continue

            # Check if it's a Qt framework (already handled by macdeployqt)
            case "$dep" in
                *Qt5*.framework/*|*Qt6*.framework/*) continue ;;
            esac

            # Must be from Homebrew or Anaconda
            local src_path=""
            if [[ "$dep" == /opt/homebrew/* ]]; then
                src_path="$dep"
            elif [[ "$dep" == /opt/anaconda3/* ]]; then
                src_path="$dep"
            elif [[ "$dep" == /Users/* ]]; then
                die "Developer path dependency found: $dep (from $current)"
            else
                warn "Unknown dependency source: $dep (from $current)"
                continue
            fi

            [ -f "$src_path" ] || die "Dependency not found: $src_path"

            local dest="$FRAMEWORKS/$dep_name"
            log "Bundling: $src_path -> $dest"
            cp -f "$src_path" "$dest"
            chmod 755 "$dest"

            # Rewrite install name of the copied library
            local old_install_name
            old_install_name=$(otool -D "$dest" 2>/dev/null | tail -1)
            if [ -n "$old_install_name" ] && [ "$old_install_name" != "$dep_name" ]; then
                log "  Rewriting install name: $old_install_name -> @rpath/$dep_name"
                install_name_tool -id "@rpath/$dep_name" "$dest"
            fi

            # Rewrite references in the binary that depends on it
            log "  Rewriting reference in $current: $dep -> @rpath/$dep_name"
            install_name_tool -change "$dep" "@rpath/$dep_name" "$current"

            bundled+=("$dep_name")
            queue+=("$dest")
        done
    done

    log "Native dependency bundling complete. Bundled ${#bundled[@]} libraries:"
    if [ ${#bundled[@]} -gt 0 ]; then
        for b in "${bundled[@]}"; do
            log "  $b"
        done
    fi

    # ── Runtime-path cleanup ───────────────────────────────────────────────
    # 1) conda Qt was linked against "@rpath/libc++.1.dylib"; a copy got pulled
    #    into Frameworks.  Use the OS-supplied libc++ instead and drop the copy.
    log "Rewriting @rpath/libc++.1.dylib references to system /usr/lib/libc++.1.dylib..."
    while IFS= read -r -d '' f; do
        file -b "$f" | grep -q Mach-O || continue
        if otool -L "$f" 2>/dev/null | grep -q '@rpath/libc++.1.dylib'; then
            log "  $f"
            install_name_tool -change '@rpath/libc++.1.dylib' '/usr/lib/libc++.1.dylib' "$f" || \
                warn "Failed to rewrite libc++ reference in $f"
        fi
    done < <(find "$APP" -type f -print0 2>/dev/null || true)
    if [ -f "$FRAMEWORKS/libc++.1.dylib" ]; then
        log "Removing bundled libc++.1.dylib..."
        rm -f "$FRAMEWORKS/libc++.1.dylib"
    fi

    # 2) Drop the stale developer rpath left on the main executable by the
    #    build (libwally-core is linked statically, so the rpath is unused).
    local stale_rpath="${ROOT_DIR}/libwally-core-install/lib"
    if otool -l "$MAIN_EXE" 2>/dev/null | grep -A1 'LC_RPATH' | grep -q "$stale_rpath"; then
        log "Removing stale developer rpath: $stale_rpath"
        install_name_tool -delete_rpath "$stale_rpath" "$MAIN_EXE" 2>/dev/null || \
            warn "Failed to remove stale rpath from $MAIN_EXE"
    fi
}

# ── Phase 3.5: Fix Info.plist + final re-sign ───────────────────────────────
fix_plist_and_resign() {
    step "Fixing Info.plist and re-signing (final step after all modifications)"

    # The CMake-generated bundle has an empty CFBundleIdentifier and
    # CFBundleVersion.  Fill them so the app is launchable/signable.
    local plist="${APP}/Contents/Info.plist"
    [ -f "$plist" ] || die "Info.plist not found: $plist"

    local bundle_id="${LITECOINCASHDEX_BUNDLE_ID:-com.litecoincash.dex}"
    log "  CFBundleIdentifier -> $bundle_id"
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $bundle_id" "$plist" 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $bundle_id" "$plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$plist" 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $VERSION" "$plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$plist" 2>/dev/null || true

    # Re-sign ad-hoc as the LAST packaging action.  All install_name_tool /
    # copy operations above invalidated the build-time signature, so without
    # this step the bundle is left with a broken (unverifiable) signature.
    # When DO_SIGN is set, sign_app() runs afterwards with the real identity
    # and this ad-hoc step is skipped.
    if [ $DO_SIGN -eq 0 ]; then
        log "  Ad-hoc re-signing $APP..."
        codesign --force --deep --sign - "$APP" 2>&1 || die "Ad-hoc re-sign failed"
        codesign --verify --deep --strict --verbose=2 "$APP" 2>&1 || \
            warn "codesign --verify reports issues (see output above)"
    else
        log "  Skipping ad-hoc re-sign (real signing runs in sign_app)"
    fi
}

# ── Phase 3: Verify deployment ───────────────────────────────────────────────
verify_deployment() {
    step "Verifying deployment closure"

    local errors=0

    # Check for any remaining external references
    log "Scanning for unresolved external dependencies..."
    while IFS= read -r -d '' f; do
        file -b "$f" | grep -q Mach-O || continue
        local deps
        deps=$(otool -L "$f" 2>/dev/null | grep -v '^$' | grep -v ':$' | awk '{print $1}' || true)
        for dep in $deps; do
            case "$dep" in
                /opt/homebrew/*|/opt/anaconda3/*|/Users/*|/miniconda*)
                    echo "ERROR: Unresolved external dependency in $f: $dep" >&2
                    ((errors++))
                    ;;
            esac
        done
    done < <(find "$APP" -type f -print0 2>/dev/null || true)

    # Architecture check
    log "Verifying all binaries are arm64..."
    while IFS= read -r -d '' f; do
        file -b "$f" | grep -q Mach-O || continue
        if ! file -b "$f" | grep -q arm64; then
            echo "ERROR: Non-arm64 binary found: $f" >&2
            ((errors++))
        fi
    done < <(find "$APP" -type f -print0 2>/dev/null || true)

    # Check KDF
    log "Verifying KDF executable..."
    [ -x "$KDF" ] || { echo "ERROR: KDF not executable" >&2; ((errors++)); }
    file -b "$KDF" | grep -q arm64 || { echo "ERROR: KDF not arm64" >&2; ((errors++)); }

    # Check Qt WebEngine resources
    log "Verifying Qt WebEngine resources..."
    [ -f "${APP}/Contents/MacOS/QtWebEngineProcess" ] || { echo "ERROR: QtWebEngineProcess missing in Contents/MacOS" >&2; ((errors++)); }
    [ -f "${RESOURCES}/qtwebengine_resources.pak" ] || warn "qtwebengine_resources.pak not found (may be embedded)"
    [ -f "${RESOURCES}/icudtl.dat" ] || warn "icudtl.dat not found (may be embedded)"

    # Check required QML modules (app aborts at startup if these are missing)
    log "Verifying required QML modules..."
    for qmlmod in \
        "QtQuick/Controls.2/qmldir" \
        "QtQuick/Controls.2/Universal/qmldir" \
        "QtQuick/Layouts/qmldir" \
        "Qt/labs/settings/qmldir" \
        "QtQuick.2/qmldir" \
        "QtGraphicalEffects/qmldir" \
        "QtCharts/qmldir" \
        "QtWebEngine/qmldir"; do
        [ -f "${RESOURCES}/qml/${qmlmod}" ] || { echo "ERROR: Missing QML module ${qmlmod}" >&2; ((errors++)); }
    done

    # Check Qt plugins were deployed
    log "Verifying Qt plugins..."
    for plug in \
        "platforms/libqcocoa.dylib" \
        "imageformats/libqsvg.dylib" \
        "imageformats/libqjpeg.dylib" \
        "iconengines/libqsvgicon.dylib" \
        "styles/libqmacstyle.dylib"; do
        [ -f "${PLUGINS}/${plug}" ] || { echo "ERROR: Missing Qt plugin ${plug}" >&2; ((errors++)); }
    done

    # No bundled libc++ (should resolve to the OS copy)
    log "Verifying no bundled libc++ remains..."
    [ -f "$FRAMEWORKS/libc++.1.dylib" ] && { echo "ERROR: Bundled libc++.1.dylib still present" >&2; ((errors++)); }

    # No stale developer rpath on the main executable
    log "Verifying no stale developer rpath on main executable..."
    if otool -l "$MAIN_EXE" 2>/dev/null | grep -A1 'LC_RPATH' | grep -q "${ROOT_DIR}"; then
        echo "ERROR: Stale developer rpath still present on $MAIN_EXE" >&2
        ((errors++))
    fi

    [ $errors -eq 0 ] || die "Verification failed with $errors error(s)"
    log "All verification checks passed"
}

# ── Phase 4: Code signing ────────────────────────────────────────────────────
sign_app() {
    step "Code signing application"

    [ -n "$SIGNING_IDENTITY" ] || die "MACOS_SIGNING_IDENTITY not set. Export it or pass --sign with identity configured."

    # Entitlements for Hardened Runtime
    local entitlements="/tmp/litecoincashdex.entitlements"
    cat > "$entitlements" << 'ENTEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.cs.allow-jit</key><true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key><true/>
    <key>com.apple.security.cs.disable-library-validation</key><true/>
    <key>com.apple.security.network.client</key><true/>
    <key>com.apple.security.network.server</key><true/>
    <key>com.apple.security.files.user-selected.read-write</key><true/>
</dict>
</plist>
ENTEOF

    # Sign nested code first (deepest first)
    log "Signing nested executables and libraries..."

    # Sign all dylibs in Frameworks
    find "$FRAMEWORKS" -name '*.dylib' -type f | while read -r lib; do
        log "  Signing $lib"
        codesign --force --sign "$SIGNING_IDENTITY" --options runtime --timestamp "$lib" 2>&1 || die "Failed to sign $lib"
    done

    # Sign Qt frameworks
    find "$FRAMEWORKS" -name '*.framework' -type d | while read -r fw; do
        local fw_bin="${fw}/Versions/Current/$(basename "$fw" .framework)"
        [ -f "$fw_bin" ] && {
            log "  Signing framework: $fw"
            codesign --force --sign "$SIGNING_IDENTITY" --options runtime --timestamp "$fw_bin" 2>&1 || die "Failed to sign $fw"
        }
    done

    # Sign QtWebEngineProcess (dylib build: lives in Contents/MacOS)
    local qtwebengine_process="${APP}/Contents/MacOS/QtWebEngineProcess"
    [ -f "$qtwebengine_process" ] && {
        log "  Signing QtWebEngineProcess"
        codesign --force --sign "$SIGNING_IDENTITY" --options runtime --timestamp "$qtwebengine_process" 2>&1 || die "Failed to sign QtWebEngineProcess"
    }

    # Sign plugins
    find "$PLUGINS" -type f -name '*.dylib' | while read -r plugin; do
        log "  Signing plugin: $plugin"
        codesign --force --sign "$SIGNING_IDENTITY" --options runtime --timestamp "$plugin" 2>&1 || die "Failed to sign $plugin"
    done

    # Sign KDF
    log "  Signing KDF (mm2_cheetah)"
    codesign --force --sign "$SIGNING_IDENTITY" --options runtime --timestamp "$KDF" 2>&1 || die "Failed to sign KDF"

    # Sign main executable
    log "Signing main executable..."
    codesign --force --sign "$SIGNING_IDENTITY" --options runtime --timestamp --entitlements "$entitlements" "$MAIN_EXE" 2>&1 || die "Failed to sign main executable"

    # Sign the app bundle
    log "Signing app bundle..."
    codesign --force --sign "$SIGNING_IDENTITY" --options runtime --timestamp --entitlements "$entitlements" --deep "$APP" 2>&1 || die "Failed to sign app bundle"

    # Verify signature
    log "Verifying code signature..."
    codesign --verify --deep --strict --verbose=4 "$APP" 2>&1 || die "Code signature verification failed"

    log "Code signing complete"
    codesign -dv --verbose=4 "$APP" 2>&1 | head -20
}

# ── Phase 5: Notarization ────────────────────────────────────────────────────
notarize_app() {
    step "Notarizing application"

    [ -n "$NOTARY_PROFILE" ] || [ -n "$NOTARY_APPLE_ID" ] || die "Notarization credentials not configured. Set MACOS_NOTARY_PROFILE or MACOS_NOTARY_APPLE_ID/TEAM_ID/PASSWORD."

    mkdir -p "$DIST_DIR"
    local zip_path="${DIST_DIR}/litecoincashdex-${VERSION}-macOS-arm64.zip"

    log "Creating ZIP for notarization: $zip_path"
    ditto -c -k --keepParent "$APP" "$zip_path"

    log "Submitting for notarization..."
    local notary_args=("notarytool" "submit" "$zip_path" "--wait")

    if [ -n "$NOTARY_PROFILE" ]; then
        notary_args+=("--keychain-profile" "$NOTARY_PROFILE")
    else
        notary_args+=("--apple-id" "$NOTARY_APPLE_ID" "--team-id" "$NOTARY_TEAM_ID" "--password" "$NOTARY_PASSWORD")
    fi

    xcrun "${notary_args[@]}" 2>&1 || die "Notarization failed"

    log "Stapling notarization..."
    xcrun stapler staple "$APP" 2>&1 || die "Stapling failed"

    log "Verifying stapling..."
    xcrun stapler validate "$APP" 2>&1 || die "Stapling validation failed"

    log "Notarization complete"
}

# ── Phase 6: Create DMG ──────────────────────────────────────────────────────
create_dmg() {
    step "Creating DMG"

    mkdir -p "$DIST_DIR"
    [ -f "$DMG_PATH" ] && rm -f "$DMG_PATH"

    local dmg_temp_dir="$(mktemp -d)"
    local app_name="$(basename "$APP")"

    log "Staging app for DMG..."
    cp -R "$APP" "$dmg_temp_dir/"

    # Create Applications symlink
    ln -s /Applications "$dmg_temp_dir/Applications"

    log "Creating DMG: $DMG_PATH"
    hdiutil create \
        -volname "$DMG_VOLUME_NAME" \
        -srcfolder "$dmg_temp_dir" \
        -ov -format UDZO \
        "$DMG_PATH" 2>&1 || die "DMG creation failed"

    # Sign DMG if identity provided
    if [ -n "$SIGNING_IDENTITY" ]; then
        log "Signing DMG..."
        codesign --force --sign "$SIGNING_IDENTITY" --timestamp "$DMG_PATH" 2>&1 || warn "DMG signing failed (non-fatal)"
    fi

    rm -rf "$dmg_temp_dir"

    log "DMG created: $DMG_PATH"
    log "Size: $(du -h "$DMG_PATH" | awk '{print $1}')"
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    log "Starting macOS packaging for LiteCoinCashDEX"
    log "App: $APP"
    log "Version: $VERSION"
    log "Dist dir: $DIST_DIR"

    validate_app

    [ $DO_QT_DEPLOY -eq 1 ] && deploy_qt
    [ $DO_NATIVE_DEPS -eq 1 ] && deploy_native_deps
    [ $DO_QT_DEPLOY -eq 1 ] || [ $DO_NATIVE_DEPS -eq 1 ] && fix_plist_and_resign
    [ $DO_VERIFY -eq 1 ] && verify_deployment
    [ $DO_SIGN -eq 1 ] && sign_app
    [ $DO_NOTARIZE -eq 1 ] && notarize_app
    [ $DO_DMG -eq 1 ] && create_dmg

    log "═══════════════════════════════════════════════════════════════"
    log "PACKAGING COMPLETE"
    [ $DO_DMG -eq 1 ] && log "DMG: $DMG_PATH"
    log "═══════════════════════════════════════════════════════════════"
}

main "$@"