# Android Build Notes

The upstream LiteRT-LM Android route is a native executable, not a packaged APK:

1. Clone `google-ai-edge/LiteRT-LM`.
2. Install Android NDK r28b or newer.
3. Set `ANDROID_NDK_HOME`.
4. Build `//runtime/engine:litert_lm_main` with `--config=android_arm64`.
5. Push the binary and `.litertlm` file to `/data/local/tmp/litert-lm`.
6. Run with `--backend=cpu`.
7. For GPU, also push `prebuilt/android_arm64/*.so` and set `LD_LIBRARY_PATH`.

The GPU library directory is:

```text
https://github.com/google-ai-edge/LiteRT-LM/tree/main/prebuilt/android_arm64
```

The first proof should be CPU because it has fewer moving parts. GPU is the next
benchmark lane once CPU produces text offline.
