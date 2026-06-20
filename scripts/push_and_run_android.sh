#!/usr/bin/env bash
set -euo pipefail

BACKEND="${1:-cpu}"
CHECKOUT_DIR="${LITERT_LM_CHECKOUT:-LiteRT-LM}"
DEVICE_FOLDER="${DEVICE_FOLDER:-/data/local/tmp/litert-lm}"
MODEL_PATH="${MODEL_PATH:-}"
PROMPT="${PROMPT:-Write one concise sentence about offline local AI.}"

if [ "$BACKEND" != "cpu" ] && [ "$BACKEND" != "gpu" ]; then
  echo "Usage: MODEL_PATH=/path/model.litertlm $0 cpu|gpu" >&2
  exit 1
fi

if [ -z "$MODEL_PATH" ] || [ ! -f "$MODEL_PATH" ]; then
  echo "Set MODEL_PATH to an existing .litertlm file." >&2
  exit 1
fi

BINARY="$CHECKOUT_DIR/bazel-bin/runtime/engine/litert_lm_main"
if [ ! -f "$BINARY" ]; then
  echo "Missing $BINARY. Run ./scripts/build_android_arm64.sh first." >&2
  exit 1
fi

adb shell "mkdir -p '$DEVICE_FOLDER'"
adb push "$MODEL_PATH" "$DEVICE_FOLDER/model.litertlm"
adb push "$BINARY" "$DEVICE_FOLDER/litert_lm_main"
adb shell "chmod 755 '$DEVICE_FOLDER/litert_lm_main'"

if [ "$BACKEND" = "gpu" ]; then
  adb push "$CHECKOUT_DIR"/prebuilt/android_arm64/*.so "$DEVICE_FOLDER/"
  adb shell "cd '$DEVICE_FOLDER' && LD_LIBRARY_PATH='$DEVICE_FOLDER' ./litert_lm_main --backend=gpu --model_path='$DEVICE_FOLDER/model.litertlm' --input_prompt='$PROMPT'"
else
  adb shell "cd '$DEVICE_FOLDER' && ./litert_lm_main --backend=cpu --model_path='$DEVICE_FOLDER/model.litertlm' --input_prompt='$PROMPT'"
fi
