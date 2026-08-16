#!/usr/bin/env bash
# cleanup-v2.sh — safe project cleanup
#
# Changes from cleanup.sh:
#   - Deleted dirs are listed explicitly; active build dirs are preserved by default.
#   - Compiled-object (.o/.a/.so/.dylib) removal is scoped to inside build dirs only,
#     preventing collateral deletion of libwally-core-install/lib/*.dylib and similar.
#   - Username-content grep+delete is gone (was deleting any file that mentioned the
#     current user as a substring — CMakeLists, git internals, logs, manifests, etc.).
#   - *.log glob is corrected (old script used "*log", matching e.g. "changelog").
#   - --dry-run flag supported throughout.
#   - --clean-build / -c runs `ninja -t clean` in the active build dir
#     (build-macos-apple-silicon) to force a from-scratch rebuild; off by
#     default since it wipes all compiled artifacts of the current build.
set -euo pipefail

DRY_RUN=0
CLEAN_BUILD=0
for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=1
      echo "== DRY RUN: nothing will be deleted =="
      ;;
    --clean-build|-c)
      CLEAN_BUILD=1
      ;;
  esac
done

do_rm() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'would remove: %s\n' "$@"
  else
    printf 'removing:     %s\n' "$@"
    rm -rf -- "$@"
  fi
}

# -----------------------------------------------------------------------
# 1. Python caches — safe everywhere, scoped away from .git
# -----------------------------------------------------------------------
while IFS= read -r -d '' f; do
  do_rm "$f"
done < <(find . -path ./.git -prune -o \
              \( -type d -name "__pycache__" \
              -o -type f -name "*.pyc" \
              -o -type f -name "*.pyo" \) \
              -print0)

# -----------------------------------------------------------------------
# 2. Log files — corrected glob (*.log not *log)
# -----------------------------------------------------------------------
while IFS= read -r -d '' f; do
  do_rm "$f"
done < <(find . -path ./.git -prune -o -type f -name "*.log" -print0)

# -----------------------------------------------------------------------
# 3. Disposable scratch / test build dirs only
#    Preserved (never touched by this script):
#      build-macos-apple-silicon   — current active build
#      libwally-core-build         — wally autotools build tree
#      libwally-core-install       — wally installed headers + libs
#      vendor/coins                — git submodule (GLEECBTC/coins); not a build
#                                    artifact, never touched by this script
# -----------------------------------------------------------------------
for d in build-macos-apple-silicon-test \
          build-macos-analysis \
          wally-install; do
  [ -d "$d" ] && do_rm "$d"
done

# -----------------------------------------------------------------------
# 4. CMake/Ninja metadata — scoped to INSIDE the disposable build dirs
#    (not a repo-wide sweep, which would hit libwally-core-build etc.).
#    Active build dirs (build-macos-apple-silicon) are
#    preserved as-is so an existing build stays usable.
# -----------------------------------------------------------------------
for build_dir in build-macos-apple-silicon-test build-macos-analysis; do
  [ -d "$build_dir" ] || continue
  while IFS= read -r -d '' f; do
    do_rm "$f"
  done < <(find "$build_dir" \
                \( -type f -name "*.ninja" \
                -o -type f -name ".ninja_*" \
                -o -type f -name "CMakeCache.txt" \) \
                -print0)
  while IFS= read -r -d '' d; do
    do_rm "$d"
  done < <(find "$build_dir" -type d -name "CMakeFiles" -print0)
  while IFS= read -r -d '' f; do
    do_rm "$f"
  done < <(find "$build_dir" -type f -name "*.yaml" -path "*/CMakeFiles/*" -print0)
done

# -----------------------------------------------------------------------
# 5. Compiled objects — scoped to INSIDE the disposable build dirs only
#    Active build dirs are preserved. Skipping the repo root and
#    vendor/libwally trees prevents deleting libwally-core-install/lib/*.dylib
#    and vendored static libs.
# -----------------------------------------------------------------------
for build_dir in build-macos-apple-silicon-test build-macos-analysis; do
  [ -d "$build_dir" ] || continue
  while IFS= read -r -d '' f; do
    do_rm "$f"
  done < <(find "$build_dir" \
                \( -type f -name "*.o" \
                -o -type f -name "*.a" \
                -o -type f -name "*.so" \
                -o -type f -name "*.dylib" \
                -o -type f -name "*.dll" \
                -o -type f -name "*.exe" \) \
                -print0)
done

# -----------------------------------------------------------------------
# 6. Optional: full clean of the active build dir (--clean-build)
#    Runs `ninja -t clean` in build-macos-apple-silicon to force a
#    from-scratch rebuild. Off by default: unlike the sections above,
#    this wipes all compiled artifacts of the current build.
# -----------------------------------------------------------------------
if [ "$CLEAN_BUILD" -eq 1 ]; then
  BUILD_DIR="build-macos-apple-silicon"
  NINJA_BIN="${NINJA_BIN:-/opt/anaconda3/bin/ninja}"
  if [ -d "$BUILD_DIR" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "would clean build dir: $BUILD_DIR"
    else
      echo "Cleaning build dir: $BUILD_DIR"
      if [ -x "$NINJA_BIN" ]; then
        (cd "$BUILD_DIR" && "$NINJA_BIN" -t clean) || echo "ninja clean failed; build dir left as-is" >&2
      else
        echo "ninja not found at $NINJA_BIN; pass NINJA_BIN=... to override" >&2
      fi
    fi
  else
    echo "active build dir $BUILD_DIR not found; skipping ninja clean" >&2
  fi
fi

echo "Cleanup complete."
