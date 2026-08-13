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
set -euo pipefail

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
  echo "== DRY RUN: nothing will be deleted =="
fi

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
#      build-macos-anaconda3       — current active build
#      build-macos-homebrew        — previous verified build
#      build-macos-lwc-r1.5.6      — dependency source build
#      libwally-core-build         — wally autotools build tree
#      libwally-core-install       — wally installed headers + libs
#      vendor/coins                — git submodule (GLEECBTC/coins); not a build
#                                    artifact, never touched by this script
# -----------------------------------------------------------------------
for d in build-macos-anaconda3-test \
          build-macos-homebrew-test \
          build-macos-analysis \
          wally-install; do
  [ -d "$d" ] && do_rm "$d"
done

# -----------------------------------------------------------------------
# 4. CMake/Ninja metadata — scoped to INSIDE the disposable build dirs
#    (not a repo-wide sweep, which would hit libwally-core-build etc.).
#    Active build dirs (build-macos-anaconda3 / build-macos-homebrew) are
#    preserved as-is so an existing build stays usable.
# -----------------------------------------------------------------------
for build_dir in build-macos-anaconda3-test build-macos-homebrew-test build-macos-analysis; do
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
for build_dir in build-macos-anaconda3-test build-macos-homebrew-test build-macos-analysis; do
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

echo "Cleanup complete."
