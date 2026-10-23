#!/usr/bin/env bash
# Sourced by the setup and launch scripts; keep caches inside this project.
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$PROJECT_DIR/.venv/bin:$PATH"
export UV_CACHE_DIR="$PROJECT_DIR/.cache/uv"
export PIP_CACHE_DIR="$PROJECT_DIR/.cache/pip"
export XDG_CACHE_HOME="$PROJECT_DIR/.cache"
export HF_HOME="$PROJECT_DIR/.cache/huggingface"
export NUMBA_CACHE_DIR="$PROJECT_DIR/.cache/numba"
export JUPYTER_CONFIG_DIR="$PROJECT_DIR/.local/jupyter/config"
export JUPYTER_DATA_DIR="$PROJECT_DIR/.local/jupyter/data"
export JUPYTER_RUNTIME_DIR="$PROJECT_DIR/.local/jupyter/runtime"
export IPYTHONDIR="$PROJECT_DIR/.local/ipython"
mkdir -p "$IPYTHONDIR" "$JUPYTER_RUNTIME_DIR"
