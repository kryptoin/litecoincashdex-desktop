#!/usr/bin/env bash
# cleanup-m2.sh — clean build artifacts for the m2 (Apple Silicon) workflow
#
# The build script (build-macos-apple-silicon.sh) already wipes its own
# BUILD_DIR and the package script overwrites the DMG, so a normal
# build/package run is effectively clean for the C++ app.  This script
# removes the ADDITIONAL artifacts the build script leaves behind so you
# can force a true from-scratch m2 rebuild in one command:
#
#   ./cleanup-m2.sh                                  # remove m2 build artifacts
#   ./cleanup-m2.sh --reset-coins                    # also drop vendor/coins
#   ./cleanup-m2.sh --dry-run                        # show what would be removed
#
# Safe by design:
#   - Only an explicit, project-specific target list is removed.
#   - No repo-wide sweep (libwally-core-install, vendor/coins, .git, and
#     source trees are never touched unless explicitly listed above).
#   - --dry-run prints targets without deleting anything.
set -euo pipefail

DRY_RUN=0
RESET_COINS=0
for arg in "$@"; do
  case "$arg" in
    --dry-run)      DRY_RUN=1; echo "== DRY RUN: nothing will be deleted ==" ;;
    --reset-coins)  RESET_COINS=1 ;;
    -h|--help)
      echo "Usage: $0 [--reset-coins] [--dry-run]"
      echo "  --reset-coins   Also remove vendor/coins (re-fetched on next build)."
      echo "  --dry-run       Print targets without deleting."
      exit 0 ;;
    *) echo "Unknown argument: $arg (use --help for usage)" >&2; exit 1 ;;
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

# ── m2-specific build artifacts (the build script does NOT auto-clean these) ──
#   build-macos-apple-silicon   — C++/Qt build dir (script also wipes this, harmless here)
#   libwally-core-install       — wally headers+libs; script only rebuilds if .a missing
#   build-macos-lwc-r1.5.6/build — wally cmake build tree
#   build-macos-lwc-r1.5.6/src/secp256k1 — build-time cloned secp256k1-zkp
#   dist/LitecoinCashDEX-macOS-arm64.dmg — packaged DMG output
TARGETS=(
  build-macos-apple-silicon
  libwally-core-install
  build-macos-lwc-r1.5.6/build
  build-macos-lwc-r1.5.6/src/secp256k1
  dist/LitecoinCashDEX-macOS-arm64.dmg
)

for d in "${TARGETS[@]}"; do
  [ -e "$d" ] && do_rm "$d"
done

if [ "$RESET_COINS" -eq 1 ]; then
  [ -e vendor/coins ] && do_rm vendor/coins
fi

echo "m2 cleanup complete."
