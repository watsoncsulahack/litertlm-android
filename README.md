# litertlm-android

Reproducible build/run wrapper for testing `.litertlm` models directly on Android.
The main build path is GitHub Actions on an x86_64 Linux runner, then runtime
testing on the phone.

This repo intentionally does not store model files. Keep downloaded models in a local
`models/` directory outside Git, then pass the model path to the scripts.

## Target

First target model:

- `gemma-4-E2B-it.litertlm`
- text-only
- no `mmproj`
- CPU first, GPU second

Secondary Tensor G4 NPU target:

- `Gemma3-1B-IT_mix4blk8_jit_ekv1280_Google_Tensor_G4.litertlm`
- requires Google's `libLiteRtDispatch_GoogleTensor.so` dispatch shim
- installs/runs from top-level Termux with `BACKEND=npu`

## What This Builds

Google's source build produces the demo executable:

```sh
bazel build --config=android_arm64 //runtime/engine:litert_lm_main
```

The resulting Android binary is:

```text
bazel-bin/runtime/engine/litert_lm_main
```

For CPU, push only the binary and model. For GPU, also push
`prebuilt/android_arm64/*.so` and run with `LD_LIBRARY_PATH`.

GPU prebuilts come from:

```text
https://github.com/google-ai-edge/LiteRT-LM/tree/main/prebuilt/android_arm64
```

Expected files include:

- `libGemmaModelConstraintProvider.so`
- `libLiteRtGpuAccelerator.so`
- `libLiteRtOpenClAccelerator.so`
- `libLiteRtTopKOpenClSampler.so`
- `libLiteRtTopKWebGpuSampler.so`
- `libLiteRtWebGpuAccelerator.so`
- `libwebgpu_dawn.so`

## Host Prerequisites

- Linux or macOS build host
- Git
- Git LFS
- Bazelisk or Bazel 7.6.1
- Android NDK r28b or newer
- `adb`
- USB debugging enabled on the phone

Set:

```sh
export ANDROID_NDK_HOME=/absolute/path/to/android-ndk-r28b
```

The scripts also auto-detect NDKs under `/root/.android-build/android-sdk/ndk`.

## Quick Start

Build on GitHub:

1. Push this repo to `watsoncsulahack/litertlm-android`.
2. Open **Actions -> Build Android ARM64 LiteRT-LM Runner**.
3. Run the workflow with `litert_lm_ref=main` or a pinned upstream SHA.
4. Download the `litert-lm-android-arm64` artifact.

Local build, for machines with a working Android NDK:

```sh
./scripts/fetch_litert_lm.sh
./scripts/preflight.sh
./scripts/build_android_arm64.sh

MODEL_PATH=/absolute/path/to/models/gemma-4-E2B-it.litertlm \
  ./scripts/push_and_run_android.sh cpu
```

GPU trial:

```sh
MODEL_PATH=/absolute/path/to/models/gemma-4-E2B-it.litertlm \
  ./scripts/push_and_run_android.sh gpu
```

Benchmark:

```sh
MODEL_PATH=/absolute/path/to/models/gemma-4-E2B-it.litertlm \
  ./scripts/benchmark_android.sh cpu
```

Top-level Termux NPU shim install:

```sh
./scripts/install_google_tensor_npu_runtime.sh
```

Then run:

```sh
BACKEND=npu \
MODEL_PATH=/data/data/com.termux/files/home/models/Gemma3-1B-IT_mix4blk8_jit_ekv1280_Google_Tensor_G4.litertlm \
PROMPT='Say hello in one short sentence.' \
/data/data/com.termux/files/home/litertlm-android-runtime/run-litertlm
```

## Build Host Note

The official Android NDK installed by Android SDK Manager uses Linux x86_64 host
tools. Building inside ARM64 Ubuntu/PRoot on the phone can fail before compile
with an NDK clang host-tool error. In that case, use the GitHub Actions workflow
in this repo or another x86_64 Linux host to build the binary, then push the
artifact to the phone for offline runtime testing.

## Offline Mode

After source, tools, model files, and Android assets are downloaded once, the actual
phone run is offline. The model and binary live under `/data/local/tmp/litert-lm`.

Use airplane mode for the validation pass:

```sh
adb shell svc wifi disable
adb shell svc data disable
```

Then run the benchmark script again.

## Output

Copy benchmark logs into the companion benchmark repo:

```text
../litert-lm-benchmarks/results/
```
