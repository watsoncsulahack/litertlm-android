#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${LITERT_LM_REPO_URL:-https://github.com/google-ai-edge/LiteRT-LM.git}"
REF="${LITERT_LM_REF:-main}"
CHECKOUT_DIR="${LITERT_LM_CHECKOUT:-LiteRT-LM}"

if [ -d "$CHECKOUT_DIR/.git" ]; then
  git -C "$CHECKOUT_DIR" fetch --tags origin
else
  git clone "$REPO_URL" "$CHECKOUT_DIR"
fi

git -C "$CHECKOUT_DIR" checkout "$REF"

if command -v git-lfs >/dev/null 2>&1; then
  git -C "$CHECKOUT_DIR" lfs install --local
  git -C "$CHECKOUT_DIR" lfs pull
else
  echo "git-lfs not found; install it before GPU runs that need prebuilt shared libraries." >&2
fi

if [ -d "$CHECKOUT_DIR/prebuilt/android_arm64" ]; then
  find "$CHECKOUT_DIR/prebuilt/android_arm64" -maxdepth 1 -type f -name '*.so' -printf '%f\n' | sort
fi

echo "LiteRT-LM source ready at $CHECKOUT_DIR"
