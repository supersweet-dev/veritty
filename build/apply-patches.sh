#!/usr/bin/env bash
set -euo pipefail

# VeriTTY Patch Applicator
# Applies modular patches from patches/ to build/upstream

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
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
  PATCH_NAME="$(basename "$patch_file")"
  if git -C "$UPSTREAM_DIR" apply --reverse --check "$patch_file" >/dev/null 2>&1; then
    echo "--> Patch already present: ${PATCH_NAME}"
  else
    echo "--> Applying patch: ${PATCH_NAME}"
    git -C "$UPSTREAM_DIR" apply --ignore-whitespace "$patch_file"
  fi
  PATCH_COUNT=$((PATCH_COUNT + 1))
done

if [ "$PATCH_COUNT" -eq 0 ]; then
  echo "--> No patch files found in ${PATCHES_DIR}."
else
  echo "==> Processed ${PATCH_COUNT} patch(es)."
fi

if [ -d "${ROOT_DIR}/extensions/veritty" ]; then
  echo "--> Bundling VeriTTY companion extension into ${UPSTREAM_DIR}/extensions/veritty..."
  mkdir -p "${UPSTREAM_DIR}/extensions/veritty"
  cp -r "${ROOT_DIR}/extensions/veritty/"* "${UPSTREAM_DIR}/extensions/veritty/"
  echo "==> Companion extension bundled."
fi
