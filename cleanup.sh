#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
#  Python cache cleanup
# -----------------------------
find . | grep -E "(/__pycache__$|\.pyc$|\.pyo$)" | xargs rm -rf || true

# -----------------------------
#  Log files
# -----------------------------
find . -type f -name "*log" -delete

# -----------------------------
#  Remove temporary build dirs
#  (but KEEP build-macos-lwc-r1.5.6)
# -----------------------------
for d in build-macos-homebrew-test \
         build-macos-analysis \
         local \
         wally-install; do
    [ -d "$d" ] && rm -rf "$d"
done

# -----------------------------
#  Remove generated build dirs
#  except the dependency
# -----------------------------
find . -maxdepth 1 -type d -name "build-*" \
    ! -name "build-macos-lwc-r1.5.6" \
    -exec rm -rf {} +

# -----------------------------
#  Remove files containing your username
#  (optional but recommended)
# -----------------------------
USER_NAME="$(whoami)"
grep -R "$USER_NAME" -l . 2>/dev/null | xargs rm -f || true

# -----------------------------
#  Remove CMake/Ninja artifacts
# -----------------------------
find . -type f -name "*.ninja" -delete
find . -type f -name ".ninja_*" -delete
find . -type f -name "CMakeCache.txt" -delete
find . -type d -name "CMakeFiles" -exec rm -rf {} +

# Remove CMake YAML logs (but not dependency YAML)
find . -type f -name "*.yaml" -path "*/CMakeFiles/*" -delete

# -----------------------------
#  Remove compiled objects
# -----------------------------
find . -type f -name "*.o" -delete
find . -type f -name "*.a" -delete
find . -type f -name "*.so" -delete
find . -type f -name "*.dylib" -delete
find . -type f -name "*.dll" -delete
find . -type f -name "*.exe" -delete
