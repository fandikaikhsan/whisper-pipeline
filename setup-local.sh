#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/local-env.sh"
cd "$PROJECT_DIR"

if command -v uv >/dev/null 2>&1; then
    if [ ! -x .venv/bin/python ]; then
        uv venv --python 3.12 .venv
    fi
    uv pip install --python .venv/bin/python -r requirements.txt
else
    if [ ! -x .venv/bin/python ]; then
        python3 -m venv .venv
    fi
    .venv/bin/python -m ensurepip --upgrade
    .venv/bin/python -m pip install -r requirements.txt
fi

# Whisper invokes the ffmpeg command. Use the binary shipped in this environment.
.venv/bin/python - <<'PY'
from pathlib import Path
import imageio_ffmpeg
target = Path('.venv/bin/ffmpeg')
if target.is_symlink() or target.exists():
    target.unlink()
target.symlink_to(imageio_ffmpeg.get_ffmpeg_exe())
PY

.venv/bin/python -m ipykernel install --user --name whisper-pipeline --display-name "Python (whisper-pipeline)"
echo "Setup selesai. Jalankan: bash start-local.sh"
