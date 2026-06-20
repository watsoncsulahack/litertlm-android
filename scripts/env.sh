#!/usr/bin/env bash

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

detect_android_ndk_home() {
  if [ -n "${ANDROID_NDK_HOME:-}" ]; then
    printf '%s\n' "$ANDROID_NDK_HOME"
    return 0
  fi

  local ndk_parent
  for ndk_parent in \
    "${ANDROID_HOME:-}/ndk" \
    "${ANDROID_SDK_ROOT:-}/ndk" \
    "/root/.android-build/android-sdk/ndk"; do
    [ -d "$ndk_parent" ] || continue
    find "$ndk_parent" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -1
    return 0
  done

  return 1
}

detect_adb() {
  if [ -n "${ADB:-}" ]; then
    printf '%s\n' "$ADB"
    return 0
  fi

  if command -v adb >/dev/null 2>&1; then
    command -v adb
    return 0
  fi

  local candidate
  for candidate in \
    "${ANDROID_HOME:-}/platform-tools/adb" \
    "${ANDROID_SDK_ROOT:-}/platform-tools/adb" \
    "/root/.android-build/android-sdk/platform-tools/adb"; do
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

detect_bazel() {
  if [ -n "${BAZEL:-}" ]; then
    printf '%s\n' "$BAZEL"
    return 0
  fi

  local candidate
  for candidate in \
    "$(command -v bazelisk 2>/dev/null || true)" \
    "/root/.local/bin/bazelisk" \
    "$(command -v bazel 2>/dev/null || true)"; do
    [ -n "$candidate" ] || continue
    [ -x "$candidate" ] || continue
    if "$candidate" --version >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

detect_bazel_for_version() {
  local version="$1"

  if [ -n "${BAZEL:-}" ]; then
    printf '%s\n' "$BAZEL"
    return 0
  fi

  local candidate
  for candidate in \
    "$(command -v bazelisk 2>/dev/null || true)" \
    "/root/.local/bin/bazelisk"; do
    [ -n "$candidate" ] || continue
    [ -x "$candidate" ] || continue
    if USE_BAZEL_VERSION="$version" "$candidate" --version >/dev/null 2>&1; then
      printf 'USE_BAZEL_VERSION=%s %s\n' "$version" "$candidate"
      return 0
    fi
  done

  local metadata="/root/.cache/bazelisk/downloads/metadata/bazelbuild/bazel-${version}-linux-arm64"
  if [ -f "$metadata" ]; then
    local sha
    sha="$(cat "$metadata")"
    candidate="/root/.cache/bazelisk/downloads/sha256/$sha/bin/bazel"
    if [ -x "$candidate" ] && "$candidate" --version >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return 0
    fi
  fi

  candidate="/usr/bin/bazel-$version"
  if [ -x "$candidate" ] && "$candidate" --version >/dev/null 2>&1; then
    printf '%s\n' "$candidate"
    return 0
  fi

  detect_bazel
}

require_file() {
  local path="$1"
  local message="$2"
  if [ ! -f "$path" ]; then
    echo "$message" >&2
    return 1
  fi
}

ndk_clang_path() {
  local ndk_home="$1"
  printf '%s\n' "$ndk_home/toolchains/llvm/prebuilt/linux-x86_64/bin/clang"
}

ndk_clang_is_runnable() {
  local ndk_home="$1"
  local clang
  clang="$(ndk_clang_path "$ndk_home")"
  [ -x "$clang" ] || return 1
  "$clang" --version >/dev/null 2>&1
}
