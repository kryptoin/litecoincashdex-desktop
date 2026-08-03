#!/usr/bin/env bash
set -euo pipefail

# Usage: ./cleanup.sh [--dry-run]
DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
  echo "== DRY RUN: nothing will actually be deleted =="
fi

# Wrapper: either print or actually remove, and always print what matched.
do_rm() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'would remove: %s\n' "$@"
  else
    printf 'removing: %s\n' "$@"
    rm -rf -- "$@"
  fi
}

# -----------------------------
#  Python cache cleanup
#  (prune .git; null-safe; only real pycache dirs / pyc / pyo)
# -----------------------------
while IFS= read -r -d '' f; do
  do_rm "$f"
done < <(find . -path ./.git -prune -o \
              \( -type d -name "__pycache__" -o -type f -name "*.pyc" -o -type f -name "*.pyo" \) \
              -print0)

# -----------------------------
#  Log files (fixed glob: was "*log", now "*.log")
# -----------------------------
while IFS= read -r -d '' f; do
  do_rm "$f"
done < <(find . -path ./.git -prune -o -type f -name "*.log" -print0)

# -----------------------------
#  Remove specific temporary build dirs
#  (but KEEP build-macos-lwc-r1.5.6)
# -----------------------------
for d in build-macos-anaconda3-test \
         build-macos-analysis \
         local \
         wally-install; do
  [ -d "$d" ] && do_rm "$d"
done

# -----------------------------
#  Remove generated build-* dirs except the dependency build
# -----------------------------
while IFS= read -r -d '' d; do
  do_rm "$d"
done < <(find . -maxdepth 1 -type d -name "build-*" \
              ! -name "build-macos-lwc-r1.5.6" -print0)

# -----------------------------
#  Remove CMake/Ninja artifacts (prune .git)
# -----------------------------
while IFS= read -r -d '' f; do
  do_rm "$f"
done < <(find . -path ./.git -prune -o \
              \( -type f -name "*.ninja" \
              -o -type f -name ".ninja_*" \
              -o -type f -name "CMakeCache.txt" \) \
              -print0)

while IFS= read -r -d '' d; do
  do_rm "$d"
done < <(find . -path ./.git -prune -o -type d -name "CMakeFiles" -print0)

# CMake-generated YAML logs only (scoped to CMakeFiles/ paths, not project YAML)
while IFS= read -r -d '' f; do
  do_rm "$f"
done < <(find . -path ./.git -prune -o -type f -name "*.yaml" -path "*/CMakeFiles/*" -print0)

# -----------------------------
#  Remove compiled objects (prune .git)
# -----------------------------
while IFS= read -r -d '' f; do
  do_rm "$f"
done < <(find . -path ./.git -prune -o \
              \( -type f -name "*.o" \
              -o -type f -name "*.a" \
              -o -type f -name "*.so" \
              -o -type f -name "*.dylib" \
              -o -type f -name "*.dll" \
              -o -type f -name "*.exe" \) \
              -print0)

# -----------------------------
#  Username scrub: REMOVED.
#
#  The old version did `grep -R "$USER_NAME" -l . | xargs rm -f`, which
#  deletes ANY file anywhere in the tree (including inside .git) that
#  merely contains your username as a substring -- source files, README,
#  LICENSE, CMakeLists.txt, git internals, anything. That is almost
#  certainly what ate files it shouldn't have last time.
#
#  If you need this, scope it tightly and review before deleting, e.g.
#  only inside build directories, and print matches first:
#
#    USER_NAME="$(whoami)"
#    find ./build-* -path ./.git -prune -o -type f -print0 2>/dev/null \
#      | xargs -0 grep -l "$USER_NAME" 2>/dev/null
#
#  ...then delete only after you've looked at that list.
# -----------------------------

echo "Cleanup complete."