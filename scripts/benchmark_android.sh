#!/usr/bin/env bash
set -euo pipefail

BACKEND="${1:-cpu}"
CHECKOUT_DIR="${LITERT_LM_CHECKOUT:-LiteRT-LM}"
DEVICE_FOLDER="${DEVICE_FOLDER:-/data/local/tmp/litert-lm}"
MODEL_PATH="${MODEL_PATH:-}"
PREFILL_TOKENS="${PREFILL_TOKENS:-1024}"
DECODE_TOKENS="${DECODE_TOKENS:-256}"
TASKSET_MASK="${TASKSET_MASK:-f0}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="${LOG_DIR:-logs}"

mkdir -p "$LOG_DIR"

"$(dirname "$0")/push_and_run_android.sh" "$BACKEND" >/dev/null

LOG_FILE="$LOG_DIR/litert-lm-${BACKEND}-${STAMP}.log"

if [ "$BACKEND" = "gpu" ]; then
  adb shell "cd '$DEVICE_FOLDER' && LD_LIBRARY_PATH='$DEVICE_FOLDER' taskset '$TASKSET_MASK' ./litert_lm_main --backend=gpu --model_path='$DEVICE_FOLDER/model.litertlm' --benchmark --benchmark_prefill_tokens='$PREFILL_TOKENS' --benchmark_decode_tokens='$DECODE_TOKENS' --async=false" | tee "$LOG_FILE"
else
  adb shell "cd '$DEVICE_FOLDER' && taskset '$TASKSET_MASK' ./litert_lm_main --backend=cpu --model_path='$DEVICE_FOLDER/model.litertlm' --benchmark --benchmark_prefill_tokens='$PREFILL_TOKENS' --benchmark_decode_tokens='$DECODE_TOKENS' --async=false" | tee "$LOG_FILE"
fi

echo "Saved benchmark log: $LOG_FILE"
