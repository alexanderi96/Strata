#!/bin/bash
# Engine package rx7900 for this branch, built like the official one: Ubuntu 22.04, ROCm 7.10.0a20251120 gfx110X-dgpu
# TheRock wheels, packaging/build_hip_linux.sh. Runs inside ubuntu:22.04 with /src = the checkout and /w = a work folder.
set -eux
ROCM_VER=7.10.0a20251120
export DEBIAN_FRONTEND=noninteractive PIP_NO_CACHE_DIR=1
apt-get update -qq
apt-get install -y -qq python3 python3-venv python3-pip git build-essential patchelf file >/dev/null
python3 -m venv /w/venv
/w/venv/bin/pip install -q -U pip cmake ninja
/w/venv/bin/pip install -q --index-url https://rocm.nightlies.amd.com/v2/gfx110X-dgpu/ "rocm[libraries,devel]==$ROCM_VER"
export PATH=/w/venv/bin:$PATH
rocm-sdk init
SP=$(python -c 'import site; print(site.getsitepackages()[0])')
git config --global --add safe.directory '*'
LLAMA_COMMIT=$(grep -oP '^LLAMA_CPP_COMMIT = "\K[0-9a-f]+' /src/setup.py)
git init -q /w/llama.cpp
git -C /w/llama.cpp fetch -q --depth 1 https://github.com/ggml-org/llama.cpp "$LLAMA_COMMIT"
git -C /w/llama.cpp checkout -q FETCH_HEAD
cd /src
VARIANT=rx7900 LLAMA=/w/llama.cpp HP=$SP/_rocm_sdk_devel CORE=$SP/_rocm_sdk_core LIBW=$(ls -d $SP/_rocm_sdk_libraries_* | head -1) \
  OUT=/w/out COMMIT=$(git rev-parse HEAD) JOBS=$(nproc) bash packaging/build_hip_linux.sh
cat /w/out/build.status
