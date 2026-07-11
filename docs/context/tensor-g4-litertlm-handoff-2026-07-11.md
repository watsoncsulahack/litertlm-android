# Tensor G4 LiteRT-LM Handoff - 2026-07-11

This is the context file to open first in a fresh session. It condenses the multi-day work on running LiteRT-LM and Gemma-family models on Allan's Pixel 9 Pro Fold / Google Tensor G4 from Termux.

## Current Goal

Produce or obtain a working Google Tensor G4 NPU path for Gemma-family LiteRT-LM models, with special interest in getting Gemma 4 E2B onto the NPU if possible.

The practical state today:

- Gemma 4 E2B `.litertlm` works on Android through LiteRT-LM GPU and CPU.
- Tensor G4 NPU is proven working through LiteRT-LM for the Gemma3 1B JIT Tensor G4 bundle.
- Tensor G4 AOT artifacts reach dispatch initialization, but current phone dispatch/vendor runtime rejects the embedded compiled payload.
- Gemma 4 E2B does not yet have a working Tensor G4-targeted artifact in the local setup.

## Important Local Paths

Termux-side runtime and models:

```text
/data/data/com.termux/files/home/litertlm-android-runtime/
/data/data/com.termux/files/home/litertlm-android-runtime/run-litertlm
/data/data/com.termux/files/home/models/
/data/data/com.termux/files/home/models/libLiteRtDispatch_GoogleTensor.so
```

Workspace repo:

```text
/root/.openclaw/workspace/litert-lm-android-runner
```

Important workspace reports:

```text
/root/.openclaw/workspace/reports/litertlm-tensor-g4-npu-analysis-2026-07-08.md
/root/.openclaw/workspace/litert-lm-android-runner/docs/build-results/2026-06-28-github-actions-android-arm64.md
/root/.openclaw/workspace/litert-lm-android-runner/docs/build-results/2026-06-28-termux-runtime-install.md
/root/.openclaw/workspace/litert-lm-android-runner/docs/build-results/2026-06-29-google-tensor-npu-shim.md
/root/.openclaw/workspace/litert-lm-android-runner/docs/build-results/2026-06-30-gemma-npu-sweep.md
```

## Runtime Environment

The known-good Termux wrapper needs the runtime dir, dispatch shim dir, vendor Edge TPU libs, Android i18n APEX, system libs, and Termux libs on `LD_LIBRARY_PATH`.

Known-good shape:

```sh
export LITERTLM_RUNTIME_DIR="$HOME/litertlm-android-runtime"
export LITERT_GOOGLE_TENSOR_DISPATCH_DIR="$HOME/models"
export LD_LIBRARY_PATH="$LITERTLM_RUNTIME_DIR:$LITERT_GOOGLE_TENSOR_DISPATCH_DIR:/vendor/lib64:/apex/com.android.i18n/lib64:/system/lib64:$PREFIX/lib:${LD_LIBRARY_PATH:-}"
```

LiteRT-LM's current CLI only exposes:

```text
--backend
--model_path
--input_prompt
--input_prompt_file
```

There is no CLI flag for `DispatchLibraryDir`. In practice, NPU loading falls back to the model file's parent directory, so the Google Tensor dispatch shim must sit beside the `.litertlm` files in `~/models`.

## Google Tensor Dispatch Shim

The correct dispatch shim is:

```text
libLiteRtDispatch_GoogleTensor.so
```

Working source:

```text
https://github.com/google-ai-edge/LiteRT/releases/download/v2.1.5/litert_npu_runtime_libraries_jit.zip
```

Path inside zip:

```text
google_tensor_runtime/src/main/jni/arm64-v8a/libLiteRtDispatch_GoogleTensor.so
```

Installed local path:

```text
/data/data/com.termux/files/home/models/libLiteRtDispatch_GoogleTensor.so
```

SHA-256:

```text
3cb069aff8f7bff14976c0170bfc266933462952db49ddb212697f83d3b1c4f5
```

The shim resolves the Pixel vendor SouthBound runtime:

```text
/vendor/lib64/libedgetpu_litert.so
```

Other vendor pieces observed:

```text
/vendor/lib64/libedgetpu_client.google.so
/vendor/lib64/libedgetpu_tflite_compiler.so
/vendor/lib64/com.google.edgetpu_vendor_service-V2-ndk.so
```

Reusable installer:

```sh
cd /root/.openclaw/workspace/litert-lm-android-runner
./scripts/install_google_tensor_npu_runtime.sh
```

## Proven Runtime Results

### LiteRT-LM Android ARM64 Binary

The standalone Android ARM64 `litert_lm_main` binary was built through GitHub Actions in:

```text
https://github.com/watsoncsulahack/litertlm-android
```

Useful commits:

```text
79e30ab Document GitHub Actions build result
e932e4b Document Termux runtime install
0f635cb Document Google Tensor NPU shim
39d6c6b Document Gemma NPU sweep
```

The binary runs on-device from Termux with the wrapper in `~/litertlm-android-runtime`.

### Gemma 4 E2B LiteRT-LM on GPU/CPU

Model:

```text
/data/data/com.termux/files/home/models/gemma-4-E2B-it.litertlm
SHA-256: 181938105e0eefd105961417e8da75903eacda102c4fce9ce90f50b97139a63c
```

GPU result:

- Output worked.
- Init total: `44399.38 ms`
- TTFT: `0.57 s`
- Prefill: `39.98 tok/s`
- Decode: `5.72 tok/s`
- Logs confirmed OpenCL delegation through `LITERT_CL` for decode/prefill/verify.

CPU result:

- Output worked.
- Init total: `6384.79 ms`
- TTFT: `1.62 s`
- Prefill: `11.38 tok/s`
- Decode: `4.72 tok/s`

Important: the accompanying `gemma-4-E2B-it-litert-lm-chat_template.jinja` exists, but this `litert_lm_main` binary does not expose a chat-template flag.

### Gemma3 1B JIT Tensor G4 on NPU

Model:

```text
Gemma3-1B-IT_mix4blk8_jit_ekv1280_Google_Tensor_G4.litertlm
size: 1,046,496,076 bytes
```

Smoke command:

```sh
BACKEND=npu \
MODEL_PATH=/data/data/com.termux/files/home/models/Gemma3-1B-IT_mix4blk8_jit_ekv1280_Google_Tensor_G4.litertlm \
PROMPT='Say hello in one short sentence.' \
/data/data/com.termux/files/home/litertlm-android-runtime/run-litertlm
```

Output:

```text
Hello!
```

Key log proof:

```text
Loading shared library: /data/data/com.termux/files/home/models/libLiteRtDispatch_GoogleTensor.so
SouthBound context created.
Found GoogleTensorOptions
SouthBound symbols resolved by 'libedgetpu_litert.so'
```

Representative metrics:

- Init total around `6.4-6.6 s`
- TTFT around `2.2-2.4 s`
- Prefill around `6.9-7.5 tok/s`
- Decode around `13.5-15 tok/s`

This is the only currently confirmed NPU inference path.

## Model Container Findings

All inspected `.litertlm` files are LiteRT-LM container version `1.5.0`, not zip archives.

### Working G4 JIT Bundle

Sections:

```text
0 LlmMetadataProto
1 HF_Tokenizer_Zlib
2 TFLiteModel tf_lite_prefill_decode
3 TFLiteModel tf_lite_embedder
4 TFLiteModel tf_lite_aux
```

Markers:

- No `DGC0`
- No `DISPATCH_OP`
- No embedded AOT payload
- Has StableHLO/ODML markers

Interpretation: this is a JIT path. The device/runtime compiles eligible subgraphs at load time and falls back to CPU for unsupported pieces.

### G4 AOT Bundle

Model:

```text
Gemma3-1B-IT_int4_aot_ekv1280_Google_Tensor_G4.litertlm
size: 867,716,136 bytes
```

Sections mirror the JIT bundle, but `tf_lite_prefill_decode` has:

```text
DGC0:2
DISPATCH_OP:1
Tensor_G4:1
stablehlo:1
```

Interpretation: this is structurally a Tensor G4 AOT bundle with embedded DarwiNN/dispatch payloads.

Runtime result: fails on the current dispatch/vendor runtime after the dispatch path is reached.

Key failure:

```text
Unsupported directive: edgetpu_performance_mode
Kernel binary is neither DarwiNN binary nor TF Lite binary
Encountered unresolved custom op: DISPATCH_OP
Node number 0 (DISPATCH_OP) failed to prepare
```

Dispatch compatibility sweep:

- `v2.0.2`: `No usable Dispatch runtime found`
- `v2.1.0rc1`: `No usable Dispatch runtime found`
- `v2.1.0`: `No usable Dispatch runtime found`
- `v2.1.5`: SouthBound starts, then embedded DGC payload is rejected

Conclusion: AOT is not blocked by library path or missing shim. It is a dispatch/vendor-runtime compatibility issue with the embedded precompiled payload.

### Generic Gemma 4 E2B Bundle

Model:

```text
gemma-4-E2B-it.litertlm
size: 2,588,147,712 bytes
```

This bundle has 12 sections, including text, per-layer embedder, audio, vision, prefill/decode, and MTP drafter sections.

Important markers:

- Some `DGC0` markers exist.
- No `DISPATCH_OP`
- No `Tensor_G4`
- No `Tensor_G5`

NPU result:

```text
TF_LITE_AUX not found in the model.
```

Interpretation: despite some compiled-looking markers, it is not packaged as a Tensor G4 NPU artifact for the current executor. Use GPU/CPU for this bundle.

### Tensor G5 Gemma 4 E2B Bundle

Model:

```text
gemma-4-E2B-it_Google_Tensor_G5.litertlm
size: 3,953,110,901 bytes
```

This bundle has 14 sections. Several major sections have:

```text
DGC0
DISPATCH_OP
Tensor_G5
```

NPU result on Tensor G4:

```text
Kernel binary is neither DarwiNN binary nor TF Lite binary
Encountered unresolved custom op: DISPATCH_OP
```

Interpretation: expected incompatible. It is precompiled for Tensor G5, not Tensor G4.

## Publisher Clues From xThr45hx

Sources:

```text
https://huggingface.co/xThr45hx/Gemma3-1B-IT-Tensor-G4-NPU
https://huggingface.co/xThr45hx/Tensor-G4-NPU-Compiler-Toolchains
https://huggingface.co/xThr45hx/Gemma3-1B-IT-Tensor-G4-NPU/discussions/1
```

Key takeaways:

- JIT builds are plug-and-play and compile eligible subgraphs at load time.
- JIT reaches only partial NPU usage, roughly described by the publisher as around 32% NPU plus CPU fallback.
- Int4 AOT is intended as near-100% NPU but requires a compatible dispatch/runtime/firmware stack.
- AOT is more useful for prefill-heavy work than decode-heavy work.
- Rank-2 fully-connected surgery is the key compiler workaround: DarwiNN AOT compiler fails on rank-3 `FULLY_CONNECTED`, so rewrite as `RESHAPE -> rank-2 FC -> RESHAPE`.
- Per-channel int4 gives coherent output.
- Per-tensor int4 may compile but can produce poor output, especially around the large vocabulary head.
- JIT recipes use blockwise int4 for MLP and int8 for attention/embed/head to preserve quality.

Discussion compile advice:

- Use `ai-edge-litert-nightly`.
- Use `ai-edge-litert-sdk-google-tensor==2.1.5`.
- Import the backend explicitly:

```python
from ai_edge_litert.aot.vendors.google_tensor import google_tensor_backend
```

- For already-quantized models, start with an empty AOT config dict.
- Avoid aggressive flags initially; flags such as `google_tensor_enable_large_model_support`, `google_tensor_enable_4bit_compilation`, and dynamic-range options may crash the compiler plugin.
- Export composite-free if possible; `odml.rms_norm` and other StableHLO composites may fail to lower.

## Current Interpretation

The local system has three distinct paths:

1. LiteRT-LM GPU/CPU path: works for `gemma-4-E2B-it.litertlm`.
2. Tensor G4 NPU JIT path: works for `Gemma3-1B-IT_mix4blk8_jit_ekv1280_Google_Tensor_G4.litertlm`.
3. Tensor G4/G5 AOT dispatch path: initializes but rejects current embedded payloads.

The local NPU wiring is good enough to prove Google Tensor dispatch works. The unsolved problem is generating or finding a Tensor G4-compatible Gemma 4 E2B `.litertlm` whose artifact shape and embedded payload are accepted by the Pixel's current vendor runtime.

## Practical Next Steps

Recommended next session task:

1. Build or obtain a text-only Gemma 4 E2B Tensor G4 export.
2. Avoid vision/audio sections until text works.
3. Try JIT first if possible, because the proven working path is JIT and it is less firmware-sensitive than AOT.
4. If attempting AOT, use the Google Tensor AOT flow targeting `Tensor_G4`, not `Tensor_G5`.
5. Use nightly LiteRT tooling plus `ai-edge-litert-sdk-google-tensor==2.1.5`.
6. Import `google_tensor_backend` explicitly.
7. Start with an empty AOT config for already-quantized models.
8. Make the graph composite-free where possible, especially around `odml.rms_norm`.
9. Apply rank-2 `FULLY_CONNECTED` surgery if rank-3 FC ops exist.
10. Quantize conservatively:
    - per-channel int4 for AOT where supported,
    - int8 for sensitive attention/embed/head paths if quality degrades.
11. Start at small context such as `ekv1280`.
12. Inspect every produced `.litertlm` before running it.

Expected markers for a Tensor G4 AOT artifact:

```text
LITERTLM 1.5.0
DGC0
DISPATCH_OP
Tensor_G4
```

Bad marker for this phone:

```text
Tensor_G5
```

For a JIT artifact, absence of `DGC0` and `DISPATCH_OP` is not automatically bad; the working Gemma3 G4 JIT model has neither.

## Useful Run Commands

Working NPU JIT smoke:

```sh
BACKEND=npu \
MODEL_PATH=/data/data/com.termux/files/home/models/Gemma3-1B-IT_mix4blk8_jit_ekv1280_Google_Tensor_G4.litertlm \
PROMPT='Say hello in one short sentence.' \
/data/data/com.termux/files/home/litertlm-android-runtime/run-litertlm
```

Gemma 4 E2B GPU smoke:

```sh
BACKEND=gpu \
MODEL_PATH=/data/data/com.termux/files/home/models/gemma-4-E2B-it.litertlm \
PROMPT='Say hello in one short sentence.' \
/data/data/com.termux/files/home/litertlm-android-runtime/run-litertlm
```

Gemma 4 E2B CPU smoke:

```sh
BACKEND=cpu \
MODEL_PATH=/data/data/com.termux/files/home/models/gemma-4-E2B-it.litertlm \
PROMPT='Say hello in one short sentence.' \
/data/data/com.termux/files/home/litertlm-android-runtime/run-litertlm
```

Known failing but diagnostically useful AOT smoke:

```sh
BACKEND=npu \
MODEL_PATH=/data/data/com.termux/files/home/models/Gemma3-1B-IT_int4_aot_ekv1280_Google_Tensor_G4.litertlm \
PROMPT='Say hello in one short sentence.' \
/data/data/com.termux/files/home/litertlm-android-runtime/run-litertlm
```

## Links

Project repo:

```text
https://github.com/watsoncsulahack/litertlm-android
```

LiteRT release with dispatch shim:

```text
https://github.com/google-ai-edge/LiteRT/releases/tag/v2.1.5
```

Direct dispatch zip:

```text
https://github.com/google-ai-edge/LiteRT/releases/download/v2.1.5/litert_npu_runtime_libraries_jit.zip
```

LiteRT-LM:

```text
https://github.com/google-ai-edge/LiteRT-LM
```

LiteRT NPU docs:

```text
https://developers.google.com/edge/litert/next/npu
```

LiteRT Dispatch API:

```text
https://developers.google.com/edge/litert/next/dispatch
```

Google Tensor compile flags:

```text
https://developers.google.com/edge/tensor-sdk/compilation-flags
```

Official Gemma 4 E2B LiteRT-LM:

```text
https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm
```

xThr45hx working G4 model:

```text
https://huggingface.co/xThr45hx/Gemma3-1B-IT-Tensor-G4-NPU
```

xThr45hx Tensor G4 compiler/toolchain notes:

```text
https://huggingface.co/xThr45hx/Tensor-G4-NPU-Compiler-Toolchains
```

xThr45hx discussion with compile gotchas:

```text
https://huggingface.co/xThr45hx/Gemma3-1B-IT-Tensor-G4-NPU/discussions/1
```
