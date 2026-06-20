#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

CHECKOUT_DIR="${LITERT_LM_CHECKOUT:-LiteRT-LM}"
ANDROID_NDK_HOME="$(detect_android_ndk_home || true)"
ADB_BIN="$(detect_adb || true)"
BAZEL_VERSION=""
if [ -f "$CHECKOUT_DIR/.bazelversion" ]; then
  BAZEL_VERSION="$(tr -d '[:space:]' < "$CHECKOUT_DIR/.bazelversion")"
fi
if [ -n "$BAZEL_VERSION" ]; then
  BAZEL_BIN="$(detect_bazel_for_version "$BAZEL_VERSION" || true)"
else
  BAZEL_BIN="$(detect_bazel || true)"
fi

echo "repo: $(repo_root)"
echo "checkout: $CHECKOUT_DIR"
echo "bazel_version: ${BAZEL_VERSION:-default}"
echo "android_ndk_home: ${ANDROID_NDK_HOME:-missing}"
if [ -n "$ANDROID_NDK_HOME" ]; then
  echo "ndk_clang: $(ndk_clang_path "$ANDROID_NDK_HOME")"
  if ndk_clang_is_runnable "$ANDROID_NDK_HOME"; then
    echo "ndk_clang_status: runnable"
  else
    echo "ndk_clang_status: not-runnable-on-$(uname -m)"
  fi
fi
echo "adb: ${ADB_BIN:-missing}"
echo "bazel: ${BAZEL_BIN:-missing}"
echo "git-lfs: $(command -v git-lfs || echo missing)"

if [ -n "$ADB_BIN" ]; then
  "$ADB_BIN" devices || true
fi

if [ -d "$CHECKOUT_DIR/prebuilt/android_arm64" ]; then
  echo "gpu_prebuilts:"
  find "$CHECKOUT_DIR/prebuilt/android_arm64" -maxdepth 1 -type f -name '*.so' -printf '  %f\n' | sort
else
  echo "gpu_prebuilts: missing LiteRT-LM checkout"
fi

if [ -n "${MODEL_PATH:-}" ]; then
  if [ -f "$MODEL_PATH" ]; then
    echo "model: $MODEL_PATH"
    sha256sum "$MODEL_PATH"
  else
    echo "model: missing at MODEL_PATH=$MODEL_PATH"
  fi
else
  echo "model: set MODEL_PATH=/path/to/gemma-4-E2B-it.litertlm"
fi
