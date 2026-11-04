#!/usr/bin/env bash
set -euo pipefail

# VeriTTY Patch Generator
# Generates a git patch from changes in build/upstream against the pinned tag

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_DIR="${ROOT_DIR}/build/upstream"
PATCHES_DIR="${ROOT_DIR}/patches"

if [ $# -lt 2 ]; then
  echo "Usage: ./build/generate-patches.sh <category> <patch-name>"
  echo "Example: ./build/generate-patches.sh 01-debloat 001-product-and-telemetry"
  echo "Available categories in patches/:"
  ls -1 "$PATCHES_DIR" | grep -v README.md || true
  exit 1
fi

CATEGORY="$1"
PATCH_NAME="$2"
TARGET_DIR="${PATCHES_DIR}/${CATEGORY}"
TARGET_PATCH="${TARGET_DIR}/${PATCH_NAME}.patch"

if [ ! -d "$TARGET_DIR" ]; then
  mkdir -p "$TARGET_DIR"
fi

if [ ! -d "$UPSTREAM_DIR" ]; then
  echo "error: Upstream directory not found at ${UPSTREAM_DIR}"
  exit 1
fi

echo "==> Generating patch from ${UPSTREAM_DIR} -> ${TARGET_PATCH}..."

# Check if there are changes
if git -C "$UPSTREAM_DIR" diff --quiet && git -C "$UPSTREAM_DIR" diff --cached --quiet; then
  echo "warning: No uncommitted changes found in ${UPSTREAM_DIR}."
  exit 1
fi

# Generate the unified diff
git -C "$UPSTREAM_DIR" diff > "$TARGET_PATCH"

echo "==> Successfully wrote patch: ${TARGET_PATCH}"
git -C "$UPSTREAM_DIR" status -s
