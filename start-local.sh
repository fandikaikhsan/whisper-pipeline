#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/local-env.sh"
cd "$PROJECT_DIR"
if [ ! -x .venv/bin/jupyter-lab ] || [ ! -x .venv/bin/ffmpeg ]; then
    echo "Jalankan dulu: bash setup-local.sh" >&2
    exit 1
fi
exec .venv/bin/jupyter-lab --no-browser --ip=127.0.0.1 --port=8888 "$@"
