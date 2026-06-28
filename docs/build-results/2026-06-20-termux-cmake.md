# 2026-06-20 Termux CMake Build Attempt

## Goal

Build `litert_lm_main` in the top-level Termux environment using Termux's native
Android/aarch64 clang instead of the PRoot Ubuntu + official Android NDK
cross-build path.

## Environment

- Device: Pixel 9 Pro Fold
- SoC: Tensor G4
- Compiler: Termux clang 21.1.8
- CMake: 4.3.3
- Rust: 1.95.0
- Java: OpenJDK 17

## First Result

The outer CMake configure succeeded, and the `litert_lm` ExternalProject started
with Termux-native tools.

The first inner configure failed because upstream CMake refers to:

```cmake
add_subdirectory(constrained_decoding)
```

but the actual source directory is:

```text
runtime/components/logits_processor/constrained_decoding
```

The runner now carries a repeatable Termux patch:

```text
patches/termux/0001-fix-constrained-decoding-cmake-path.patch
```

Re-run with:

```sh
./scripts/build_termux_cmake.sh
```

## Current Termux Route

The first successful configure still left the inner build without generated host
tools. The repeatable script now forces LiteRT-LM's prebuild phase and builds
the generator dependencies before the main target:

```sh
cmake -S . -B cmake/build-termux-prebuild -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DLITERTLM_TOOLCHAIN_ARGS=-DCMAKE_CXX_STANDARD=20
cmake --build cmake/build-termux-prebuild/prebuild/build \
  -t protobuf_external flatbuffers_external -j2
cmake --build cmake/build-termux-prebuild -t litert_lm -j2
```

As of this note, Protobuf is compiling natively under Termux. The final
`litert_lm_main` binary has not been produced yet.
