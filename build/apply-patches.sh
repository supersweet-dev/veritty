#!/usr/bin/env bash
set -euo pipefail

# VeriTTY Patch Applicator
# Sequentially applies all modular patches in patches/ to build/upstream

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_DIR="${ROOT_DIR}/build/upstream"
PATCHES_DIR="${ROOT_DIR}/patches"

if [ ! -d "$UPSTREAM_DIR" ]; then
  echo "error: Upstream directory not found at ${UPSTREAM_DIR}."
  echo "Run ./build/fetch-base.sh first."
  exit 1
fi

echo "==> VeriTTY: Applying patches to ${UPSTREAM_DIR}..."

PATCH_COUNT=0
for patch_file in $(find "$PATCHES_DIR" -type f -name "*.patch" | sort); do
  echo "--> Applying patch: $(basename "$patch_file")"
  git -C "$UPSTREAM_DIR" apply --ignore-whitespace "$patch_file"
  PATCH_COUNT=$((PATCH_COUNT + 1))
done

if [ "$PATCH_COUNT" -eq 0 ]; then
  echo "--> No patch files found in ${PATCHES_DIR} yet."
else
  echo "==> Successfully applied ${PATCH_COUNT} patch(es)."
fi

if [ -d "${ROOT_DIR}/extensions/veritty" ]; then
  echo "--> Bundling VeriTTY companion extension into ${UPSTREAM_DIR}/extensions/veritty..."
  mkdir -p "${UPSTREAM_DIR}/extensions/veritty"
  cp -r "${ROOT_DIR}/extensions/veritty/"* "${UPSTREAM_DIR}/extensions/veritty/"
  echo "==> Companion extension bundled."
fi

