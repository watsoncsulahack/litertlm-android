# 2026-06-29 Google Tensor NPU Shim

## Result

Found and validated the Google Tensor LiteRT NPU dispatch shim for the Pixel 9
Pro Fold / Tensor G4 setup:

```text
libLiteRtDispatch_GoogleTensor.so
```

The working source is the LiteRT release asset:

```text
https://github.com/google-ai-edge/LiteRT/releases/download/v2.1.5/litert_npu_runtime_libraries_jit.zip
```

Inside the zip:

```text
google_tensor_runtime/src/main/jni/arm64-v8a/libLiteRtDispatch_GoogleTensor.so
```

Installed locally to:

```text
/data/data/com.termux/files/home/models/libLiteRtDispatch_GoogleTensor.so
```

SHA-256:

```text
3cb069aff8f7bff14976c0170bfc266933462952db49ddb212697f83d3b1c4f5
```

## Why This Location Works

The current `litert_lm_main` binary exposes only:

- `--backend`
- `--model_path`
- `--input_prompt`
- `--input_prompt_file`

It does not expose a `--dispatch_library_dir` flag. During NPU execution the
runtime uses the model directory as the dispatch-library search directory, so
placing `libLiteRtDispatch_GoogleTensor.so` beside the `.litertlm` model lets
the loader find it.

The Google Tensor shim also needs the Pixel vendor Southbound runtime:

```text
/vendor/lib64/libedgetpu_litert.so
```

So the local wrapper now includes `/vendor/lib64` in `LD_LIBRARY_PATH`:

```text
LD_LIBRARY_PATH=/data/data/com.termux/files/home/litertlm-android-runtime:/vendor/lib64:/apex/com.android.i18n/lib64
```

## Smoke Test

Command:

```sh
BACKEND=npu \
MODEL_PATH=/data/data/com.termux/files/home/models/Gemma3-1B-IT_mix4blk8_jit_ekv1280_Google_Tensor_G4.litertlm \
PROMPT='Say hello in one short sentence.' \
/data/data/com.termux/files/home/litertlm-android-runtime/run-litertlm
```

Result: success.

Output:

```text
Hello!
```

Evidence from the log:

```text
Loading shared library: /data/data/com.termux/files/home/models/libLiteRtDispatch_GoogleTensor.so
SouthBound context created.
Found GoogleTensorOptions
SouthBound symbols resolved by 'libedgetpu_litert.so'
```

Metrics:

- Init Total: `6388.78 ms`
- Time to first token: `2.39 s`
- Prefill: `16 tokens` in `2.317065879 s`, `6.91 tok/s`
- Decode: `3 tokens` in `221.883341 ms`, `13.52 tok/s`

Log:

```text
/data/data/com.termux/files/home/litertlm-android-runtime/gemma3-g4-npu-smoke-20260629-fixed.log
```

## Reproduce

Use:

```sh
./scripts/install_google_tensor_npu_runtime.sh
```

The script downloads the LiteRT release zip, installs the Google Tensor dispatch
shim beside the local models, and ensures the Termux wrapper can resolve the
Pixel vendor Southbound library.
