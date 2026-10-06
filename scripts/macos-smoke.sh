#!/usr/bin/env bash
# One command from any directory; never installs dependencies or uploads logs.
set -euo pipefail
if ! command -v python3 >/dev/null 2>&1; then
  echo 'FAIL: Python 3 is required for bounded process supervision and ICD checks.' >&2
  echo 'Manual optional installation: brew install python' >&2
  exit 1
fi
exec python3 "$(cd "$(dirname "$0")" && pwd)/macos-smoke.py" "$@"
