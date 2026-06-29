#!/usr/bin/env bash
set -euo pipefail

TAG="${LITERT_TAG:-v2.1.5}"
ZIP_NAME="${LITERT_NPU_ZIP:-litert_npu_runtime_libraries_jit.zip}"
TERMUX_HOME="${TERMUX_HOME:-/data/data/com.termux/files/home}"
MODEL_DIR="${MODEL_DIR:-$TERMUX_HOME/models}"
RUNTIME_DIR="${RUNTIME_DIR:-$TERMUX_HOME/litertlm-android-runtime}"
WORK_DIR="${WORK_DIR:-$TERMUX_HOME/tmp-litert-google-tensor-runtime}"

URL="https://github.com/google-ai-edge/LiteRT/releases/download/$TAG/$ZIP_NAME"
ZIP_PATH="$WORK_DIR/$TAG-$ZIP_NAME"
SHIM_IN_ZIP="google_tensor_runtime/src/main/jni/arm64-v8a/libLiteRtDispatch_GoogleTensor.so"
SHIM_OUT="$MODEL_DIR/libLiteRtDispatch_GoogleTensor.so"

mkdir -p "$WORK_DIR" "$MODEL_DIR"

if [ ! -f "$ZIP_PATH" ]; then
  curl -L --fail --show-error -o "$ZIP_PATH" "$URL"
fi

unzip -p "$ZIP_PATH" "$SHIM_IN_ZIP" > "$SHIM_OUT"
chmod 755 "$SHIM_OUT"

if [ -f "$RUNTIME_DIR/run-litertlm" ] && ! grep -q '/vendor/lib64' "$RUNTIME_DIR/run-litertlm"; then
  tmp_wrapper="$RUNTIME_DIR/run-litertlm.tmp"
  sed 's#"$RUNTIME_DIR:#"$RUNTIME_DIR:/vendor/lib64:#' "$RUNTIME_DIR/run-litertlm" > "$tmp_wrapper"
  chmod --reference="$RUNTIME_DIR/run-litertlm" "$tmp_wrapper"
  mv "$tmp_wrapper" "$RUNTIME_DIR/run-litertlm"
fi

echo "Installed Google Tensor LiteRT dispatch shim:"
ls -lah "$SHIM_OUT"
sha256sum "$SHIM_OUT"

cat <<'EOF'

Smoke test:

BACKEND=npu \
MODEL_PATH=/data/data/com.termux/files/home/models/Gemma3-1B-IT_mix4blk8_jit_ekv1280_Google_Tensor_G4.litertlm \
PROMPT='Say hello in one short sentence.' \
/data/data/com.termux/files/home/litertlm-android-runtime/run-litertlm
EOF
