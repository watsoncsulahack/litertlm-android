# 2026-06-28 Termux Runtime Install

## Install Location

Installed the GitHub Actions artifact into the top-level Termux home:

```text
/data/data/com.termux/files/home/litertlm-android-runtime
```

The directory contains `litert_lm_main`, the LiteRT GPU/OpenCL/WebGPU shared
libraries, and a local wrapper:

```sh
/data/data/com.termux/files/home/litertlm-android-runtime/run-litertlm
```

The wrapper sets:

```sh
LD_LIBRARY_PATH=/data/data/com.termux/files/home/litertlm-android-runtime:/apex/com.android.i18n/lib64
```

The Android i18n APEX path is required for `libicu.so`.

## Model

Allan downloaded the real model to:

```text
/data/data/com.termux/files/home/models/gemma-4-E2B-it.litertlm
```

SHA-256:

```text
181938105e0eefd105961417e8da75903eacda102c4fce9ce90f50b97139a63c
```

The chat template file is also present:

```text
/data/data/com.termux/files/home/models/gemma-4-E2B-it-litert-lm-chat_template.jinja
```

Current `litert_lm_main` exposes only `--backend`, `--model_path`,
`--input_prompt`, and `--input_prompt_file`; no template flag is available in
this demo binary.

## GPU Smoke

Command:

```sh
BACKEND=gpu \
MODEL_PATH=/data/data/com.termux/files/home/models/gemma-4-E2B-it.litertlm \
PROMPT='Write one short sentence about Android.' \
/data/data/com.termux/files/home/litertlm-android-runtime/run-litertlm
```

Result: success.

Output:

```text
Android is a popular, open-source operating system for mobile devices.
```

Metrics:

- Init Total: `44399.38 ms`
- Time to first token: `0.57 s`
- Prefill: `16 tokens` in `400.207113 ms`, `39.98 tok/s`
- Decode: `15 tokens` in `2.620482342 s`, `5.72 tok/s`

The log confirms full OpenCL delegation for the main model signatures:

- `decode`: `2068 / 2068` nodes delegated to `LITERT_CL`
- `prefill_1024`: `1107 / 1107` nodes delegated to `LITERT_CL`
- `prefill_128`: `1107 / 1107` nodes delegated to `LITERT_CL`
- `verify`: `2243 / 2243` nodes delegated to `LITERT_CL`

Log:

```text
/data/data/com.termux/files/home/litertlm-android-runtime/gemma-e2b-gpu-smoke-20260628.log
```

## CPU Smoke

Command:

```sh
BACKEND=cpu \
MODEL_PATH=/data/data/com.termux/files/home/models/gemma-4-E2B-it.litertlm \
PROMPT='Write one short sentence about Android.' \
/data/data/com.termux/files/home/litertlm-android-runtime/run-litertlm
```

Result: success.

Output:

```text
Android is a popular, open-source operating system for mobile devices.
```

Metrics:

- Init Total: `6384.79 ms`
- Time to first token: `1.62 s`
- Prefill: `16 tokens` in `1.406544475 s`, `11.38 tok/s`
- Decode: `15 tokens` in `3.178457033 s`, `4.72 tok/s`

Log:

```text
/data/data/com.termux/files/home/litertlm-android-runtime/gemma-e2b-cpu-smoke-20260628.log
```
