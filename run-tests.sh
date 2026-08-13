#!/usr/bin/env bash
# Runs the litecoincashdex_tests doctest suite.
#
# The test binary must be run from a scratch working directory (tests write files,
# e.g. a fake_dir under the CWD). A "-tc" filter is always passed so the KDF daemon
# is not spawned (see main() in src/tests/atomic.dex.tests.cpp).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${ROOT_DIR}/build-macos-apple-silicon"
TEST_APP="${BUILD_DIR}/bin/litecoincashdex_tests.app/Contents/MacOS/litecoincashdex_tests"
NINJA_BIN="${NINJA_BIN:-/opt/anaconda3/bin/ninja}"
WORK_DIR="$(mktemp -d -t litecoincashdex_tests.XXXXXX)"

MODE="offline"   # offline | network | integration | list
REBUILD=0
EXTRA_ARGS=()

usage() {
  cat <<EOF
Usage: $0 [options]

Modes (default: offline):
  --offline       Run only pure unit tests + config/API unit tests. Skips
                  live-network tests and KDF-daemon integration tests.
  --network       Also run the live-network tests (coingecko, komodo prices).
                  These require a working internet connection.
  --integration   Run the full suite including tests that spawn the KDF daemon
                  (mm2_cheetah). May crash: wallet-creation crash (BUG-1) and the
                  coins.json schema issue (BUG-2) are known to affect this.
  --list          List test case names (no execution).

Build options:
  -b, --build     Rebuild the test target with ninja before running.

Other:
  -h, --help      Show this help.
  -- <args>       Pass additional arguments through to the doctest runner.
EOF
}

ARGS=()

parse_args() {
  local passthrough=0
  for arg in "$@"; do
    if [ "$passthrough" -eq 1 ]; then
      EXTRA_ARGS+=("$arg")
      continue
    fi
    case "$arg" in
      --offline) MODE="offline" ;;
      --network) MODE="network" ;;
      --integration) MODE="integration" ;;
      --list) MODE="list" ;;
      -b|--build) REBUILD=1 ;;
      -h|--help) usage; exit 0 ;;
      --) passthrough=1 ;;
      *) echo "Unknown option: $arg" >&2; usage; exit 1 ;;
    esac
  done
}

build_doctest_args() {
  # "-tc" must always be present so main() in atomic.dex.tests.cpp does not spawn KDF.
  ARGS=( -tc="*" )
  case "${MODE}" in
    offline)
      # KDF-daemon integration tests (spawn mm2_cheetah, hit BUG-1/BUG-2) plus the
      # live-network API tests are excluded from the default run.
      ARGS+=( -tce="*preimage scenario*,*addressbook*,*api test*,*komodo prices api test*" )
      ;;
    network)
      # Keep the live network tests (coingecko "api test", komodo prices) but drop
      # the KDF-daemon integration tests.
      ARGS+=( -tce="*preimage scenario*,*addressbook*" )
      ;;
    integration)
      : # run everything
      ;;
    list)
      ARGS+=( --list-test-cases )
      ;;
  esac
  ARGS+=( --no-version )
}

parse_args "$@"
build_doctest_args

if [ ! -x "${TEST_APP}" ]; then
  echo "Test binary not found: ${TEST_APP}" >&2
  echo "Run ${ROOT_DIR}/build-macos-apple-silicon.sh first." >&2
  exit 1
fi

if [ "${REBUILD}" -eq 1 ]; then
  if [ ! -x "${NINJA_BIN}" ]; then
    echo "ninja not found at ${NINJA_BIN}; pass NINJA_BIN=... to override" >&2
    exit 1
  fi
  echo "Rebuilding test target..."
  "${NINJA_BIN}" -C "${BUILD_DIR}" litecoincashdex_tests
fi

cleanup() { rm -rf "${WORK_DIR}"; }
trap cleanup EXIT

echo "Mode: ${MODE}"
echo "Work dir: ${WORK_DIR}"
echo "Test binary: ${TEST_APP}"
echo

cd "${WORK_DIR}"
if [ "${#EXTRA_ARGS[@]}" -gt 0 ]; then
  "${TEST_APP}" "${ARGS[@]}" "${EXTRA_ARGS[@]}"
else
  "${TEST_APP}" "${ARGS[@]}"
fi
