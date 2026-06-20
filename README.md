# LiteRT-LM Android Runner

Reproducible build/run wrapper for testing `.litertlm` models directly on Android.

This repo intentionally does not store model files. Keep downloaded models in a local
`models/` directory outside Git, then pass the model path to the scripts.

## Target

First target model:

- `gemma-4-E2B-it.litertlm`
- text-only
- no `mmproj`
- CPU first, GPU second

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

## Quick Start

```sh
./scripts/fetch_litert_lm.sh
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
