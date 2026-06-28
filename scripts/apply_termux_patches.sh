#!/usr/bin/env bash
set -euo pipefail

CHECKOUT_DIR="${LITERT_LM_CHECKOUT:-LiteRT-LM}"
PATCH_DIR="$(cd "$(dirname "$0")/../patches/termux" && pwd)"

if [ ! -d "$CHECKOUT_DIR/.git" ]; then
  echo "Missing $CHECKOUT_DIR checkout. Run ./scripts/fetch_litert_lm.sh first." >&2
  exit 1
fi

for patch in "$PATCH_DIR"/*.patch; do
  [ -f "$patch" ] || continue
  if git -C "$CHECKOUT_DIR" apply --check "$patch" >/dev/null 2>&1; then
    git -C "$CHECKOUT_DIR" apply "$patch"
    echo "Applied $(basename "$patch")"
  else
    echo "Skipping $(basename "$patch") (already applied or incompatible)"
  fi
done
