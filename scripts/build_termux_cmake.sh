#!/usr/bin/env bash
set -euo pipefail

CHECKOUT_DIR="${LITERT_LM_CHECKOUT:-LiteRT-LM}"
BUILD_DIR="${TERMUX_CMAKE_BUILD_DIR:-cmake/build-termux-prebuild}"
JOBS="${JOBS:-2}"
TERMUX_PREFIX="${TERMUX_PREFIX:-/data/data/com.termux/files/usr}"
TERMUX_HOME="${TERMUX_HOME:-/data/data/com.termux/files/home}"

if [ ! -d "$CHECKOUT_DIR" ]; then
  echo "Missing $CHECKOUT_DIR. Run ./scripts/fetch_litert_lm.sh first." >&2
  exit 1
fi

"$(dirname "$0")/apply_termux_patches.sh"

cd "$CHECKOUT_DIR"

env -i \
  HOME="$TERMUX_HOME" \
  PREFIX="$TERMUX_PREFIX" \
  TMPDIR="$TERMUX_PREFIX/tmp" \
  PATH="$TERMUX_PREFIX/bin:/system/bin:/system/xbin" \
  SHELL="$TERMUX_PREFIX/bin/bash" \
  TERM="${TERM:-xterm-256color}" \
  "$TERMUX_PREFIX/bin/bash" -lc \
  "cmake -S . -B '$BUILD_DIR' -G Ninja -DCMAKE_BUILD_TYPE=Release -DLITERTLM_TOOLCHAIN_ARGS=-DCMAKE_CXX_STANDARD=20 && \
   cmake --build '$BUILD_DIR/prebuild/build' -t protobuf_external flatbuffers_external -j'$JOBS' && \
   cmake --build '$BUILD_DIR' -t litert_lm -j'$JOBS'"
