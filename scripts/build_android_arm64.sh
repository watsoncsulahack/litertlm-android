#!/usr/bin/env bash
set -euo pipefail

CHECKOUT_DIR="${LITERT_LM_CHECKOUT:-LiteRT-LM}"

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

cd "$CHECKOUT_DIR"
bazel build --config=android_arm64 //runtime/engine:litert_lm_main

echo "Built: $CHECKOUT_DIR/bazel-bin/runtime/engine/litert_lm_main"
