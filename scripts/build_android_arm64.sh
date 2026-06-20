#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

CHECKOUT_DIR="${LITERT_LM_CHECKOUT:-LiteRT-LM}"
ANDROID_NDK_HOME="$(detect_android_ndk_home || true)"
BAZEL_VERSION=""
if [ -f "$CHECKOUT_DIR/.bazelversion" ]; then
  BAZEL_VERSION="$(tr -d '[:space:]' < "$CHECKOUT_DIR/.bazelversion")"
fi
if [ -n "$BAZEL_VERSION" ]; then
  BAZEL_BIN="$(detect_bazel_for_version "$BAZEL_VERSION" || true)"
else
  BAZEL_BIN="$(detect_bazel || true)"
fi

if [ ! -d "$CHECKOUT_DIR" ]; then
  echo "Missing $CHECKOUT_DIR. Run ./scripts/fetch_litert_lm.sh first." >&2
  exit 1
fi

if [ -z "${ANDROID_NDK_HOME:-}" ]; then
  echo "Set ANDROID_NDK_HOME to an Android NDK r28b+ directory." >&2
  exit 1
fi

if [ ! -f "$ANDROID_NDK_HOME/README.md" ]; then
  echo "ANDROID_NDK_HOME does not look like an NDK root: $ANDROID_NDK_HOME" >&2
  exit 1
fi

if ! ndk_clang_is_runnable "$ANDROID_NDK_HOME"; then
  echo "Android NDK clang is not runnable from this host: $(ndk_clang_path "$ANDROID_NDK_HOME")" >&2
  echo "This usually means the installed NDK has linux-x86_64 host tools but the build host is $(uname -m)." >&2
  echo "Use an x86_64 Linux host/CI runner, or install a working native host NDK toolchain for this device." >&2
  exit 1
fi

if [ -z "$BAZEL_BIN" ]; then
  echo "Install Bazelisk or Bazel 7.6.1+." >&2
  exit 1
fi

cd "$CHECKOUT_DIR"
if [[ "$BAZEL_BIN" == USE_BAZEL_VERSION=* ]]; then
  env ANDROID_NDK_HOME="$ANDROID_NDK_HOME" $BAZEL_BIN build --config=android_arm64 //runtime/engine:litert_lm_main
else
  ANDROID_NDK_HOME="$ANDROID_NDK_HOME" "$BAZEL_BIN" build --config=android_arm64 //runtime/engine:litert_lm_main
fi

echo "Built: $CHECKOUT_DIR/bazel-bin/runtime/engine/litert_lm_main"
