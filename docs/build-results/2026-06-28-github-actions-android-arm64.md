# 2026-06-28 GitHub Actions Android ARM64 Build

## Result

GitHub Actions built `litert_lm_main` successfully for Android ARM64.

- Repo: `watsoncsulahack/litertlm-android`
- Commit: `31c2142` (`Prepare GitHub Actions Android build`)
- Run: `28336759596`
- Artifact: `litert-lm-android-arm64`
- Local artifact copy: `artifacts/actions-28336759596/litert-lm-android-arm64.tar.gz`

## Runtime Smoke

The built Android executable runs on the phone-hosted environment when the Android
i18n APEX library path is included:

```sh
LD_LIBRARY_PATH=$PWD/artifacts/actions-28336759596/extracted/litert-lm-android-arm64:/apex/com.android.i18n/lib64 \
  artifacts/actions-28336759596/extracted/litert-lm-android-arm64/litert_lm_main --help
```

The `--help` command succeeds and prints the expected runtime flags:

- `--backend`
- `--model_path`
- `--input_prompt`
- `--input_prompt_file`

CPU runtime smoke with upstream `runtime/testdata/test_lm.litertlm` also initializes
LiteRT/TensorFlow Lite/XNNPACK and emits generated tokens.

## Current Model Blocker

The local model at:

```text
/data/data/com.termux/files/home/models/gemma-4-E2B-it_Google_Tensor_G5.litertlm
```

does not currently run through `litert_lm_main` with either `--backend=cpu` or
`--backend=gpu`; both fail with:

```text
Input tensor not found
```

This suggests the binary is now usable, but the available `Google_Tensor_G5`
model artifact is not compatible with this demo runner/backend path as invoked.
