# Gemma LiteRT-LM NPU sweep on Tensor G4

Date: 2026-06-30 UTC

Device/runtime context:

- Device class: Google Tensor G4 Pixel target, running from Termux/PRoot-accessible paths.
- Runtime wrapper: `/data/data/com.termux/files/home/litertlm-android-runtime/run-litertlm`
- Backend under test: `BACKEND=npu`
- Dispatch shim: `/data/data/com.termux/files/home/models/libLiteRtDispatch_GoogleTensor.so`
- Prompt: `Say hello in one short sentence.`
- Raw logs: `artifacts/gemma-npu-sweep-20260630/`

The wrapper keeps `/vendor/lib64` in `LD_LIBRARY_PATH`, so the Google Tensor dispatch shim can resolve Pixel vendor SouthBound symbols from `libedgetpu_litert.so`.

## Summary

| Model | Result | NPU finding |
|---|---:|---|
| `Gemma3-1B-IT_int4_aot_ekv1280_Google_Tensor_G4.litertlm` | Failed | The dispatch shim loads, but the embedded dispatch kernel is rejected by this runtime/firmware stack. |
| `Gemma3-1B-IT_mix4blk8_jit_ekv1280_Google_Tensor_G4.litertlm` | Passed | NPU path works. The log confirms Google Tensor SouthBound setup and successful generation. |
| `gemma-4-E2B-it.litertlm` | Failed | Not usable through the NPU executor as packaged; it lacks `TF_LITE_AUX`. GPU/CPU remain the viable backends for this bundle. |
| `gemma-4-E2B-it_Google_Tensor_G5.litertlm` | Failed | The dispatch shim loads, but the embedded dispatch kernel is rejected on this G4 setup. |

## Detailed results

### Gemma3 1B int4 AOT Tensor G4

Command:

```sh
BACKEND=npu \
MODEL_PATH=/data/data/com.termux/files/home/models/Gemma3-1B-IT_int4_aot_ekv1280_Google_Tensor_G4.litertlm \
PROMPT='Say hello in one short sentence.' \
/data/data/com.termux/files/home/litertlm-android-runtime/run-litertlm
```

Result: failed with exit code 134.

Relevant log evidence:

- `Loading shared library: /data/data/com.termux/files/home/models/libLiteRtDispatch_GoogleTensor.so`
- `SouthBound context created.`
- `Found GoogleTensorOptions`
- `Encountered unresolved custom op: DISPATCH_OP.`
- `Kernel binary is neither DarwiNN binary nor TF Lite binary`

Interpretation: this is not a missing-shim failure. The runner reaches the Google Tensor dispatch path, but the AOT payload is not accepted by the installed runtime/firmware combination. The README for the model already warns that AOT needs a compatible dispatch runtime and that a stock app dispatch may reject it as a firmware mismatch. This CLI setup appears to be in that incompatible bucket.

Raw log: `artifacts/gemma-npu-sweep-20260630/gemma3-1b-int4-aot-g4-npu.log`

### Gemma3 1B mix4blk8 JIT Tensor G4

Command:

```sh
BACKEND=npu \
MODEL_PATH=/data/data/com.termux/files/home/models/Gemma3-1B-IT_mix4blk8_jit_ekv1280_Google_Tensor_G4.litertlm \
PROMPT='Say hello in one short sentence.' \
/data/data/com.termux/files/home/litertlm-android-runtime/run-litertlm
```

Result: passed with exit code 0.

Output:

```text
Hello!
```

Relevant log evidence:

- `SouthBound context created.`
- `Found GoogleTensorOptions`
- `SouthBound symbols resolved by 'libedgetpu_litert.so'`

Measured CLI metrics:

| Metric | Value |
|---|---:|
| Init total | 6637.69 ms |
| Time to first token | 2.20 s |
| Prefill | 7.48 tokens/sec |
| Decode | 14.95 tokens/sec |

Interpretation: this remains the working Gemma NPU path in the current CLI environment. It confirms that the installed `libLiteRtDispatch_GoogleTensor.so` shim and `/vendor/lib64` linkage are enough for at least the JIT Tensor G4 bundle.

Raw log: `artifacts/gemma-npu-sweep-20260630/gemma3-1b-mix4blk8-jit-g4-npu.log`

### Gemma 4 E2B LiteRT-LM

Command:

```sh
BACKEND=npu \
MODEL_PATH=/data/data/com.termux/files/home/models/gemma-4-E2B-it.litertlm \
PROMPT='Say hello in one short sentence.' \
/data/data/com.termux/files/home/litertlm-android-runtime/run-litertlm
```

Result: failed with exit code 134.

Relevant log evidence:

- `SouthBound context created.`
- `TF_LITE_AUX not found in the model.`

Interpretation: this bundle works through LiteRT-LM with GPU and CPU from earlier tests, but it is not packaged as a Tensor NPU model for this executor. The NPU executor expects auxiliary metadata/subgraphs that are not present.

Raw log: `artifacts/gemma-npu-sweep-20260630/gemma4-e2b-it-npu.log`

### Gemma 4 E2B Google Tensor G5 artifact

Command:

```sh
BACKEND=npu \
MODEL_PATH=/data/data/com.termux/files/home/models/gemma-4-E2B-it_Google_Tensor_G5.litertlm \
PROMPT='Say hello in one short sentence.' \
/data/data/com.termux/files/home/litertlm-android-runtime/run-litertlm
```

Result: failed with exit code 134.

Relevant log evidence:

- `Loading shared library: /data/data/com.termux/files/home/models/libLiteRtDispatch_GoogleTensor.so`
- `SouthBound context created.`
- `Found GoogleTensorOptions`
- `Encountered unresolved custom op: DISPATCH_OP.`
- `Kernel binary is neither DarwiNN binary nor TF Lite binary`

Interpretation: this artifact is named for Google Tensor G5 and is not usable on the current Tensor G4 NPU path. The failure signature is the same class as the AOT G4 bundle: the dispatch path is reached, but the embedded dispatch kernel is rejected.

Raw log: `artifacts/gemma-npu-sweep-20260630/gemma4-e2b-google-tensor-g5-npu.log`

## Conclusion

The current Termux LiteRT-LM CLI setup can use the Tensor G4 NPU for the Gemma3 1B JIT bundle. It cannot currently run the new Gemma3 1B int4 AOT bundle, despite that bundle being intended for near-100% NPU use, because the installed Google Tensor dispatch stack rejects the embedded AOT dispatch kernel.

For practical use today:

- Use `Gemma3-1B-IT_mix4blk8_jit_ekv1280_Google_Tensor_G4.litertlm` for confirmed Gemma NPU inference.
- Use `gemma-4-E2B-it.litertlm` with GPU or CPU, not NPU.
- Treat the G5-targeted Gemma 4 artifact as incompatible with this Tensor G4 setup.

The next useful AOT-specific experiment is to test the AOT bundle in Google AI Edge Gallery or with another Google Tensor dispatch/runtime package. The CLI result shows the wiring is correct up to dispatch initialization, so the remaining issue is AOT payload/runtime compatibility, not model discovery or missing vendor libraries.
