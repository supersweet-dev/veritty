#!/usr/bin/env bash
set -euo pipefail

# VeriTTY Core Build Script
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_DIR="${ROOT_DIR}/build/upstream"

echo "==> VeriTTY: Building CLI..."
(cd "${ROOT_DIR}/cli" && npm install && npm run build)

if [ ! -d "$UPSTREAM_DIR" ]; then
  echo "error: Upstream directory not found. Please run ./build/fetch-base.sh and ./build/apply-patches.sh"
  exit 1
fi

echo "==> VeriTTY: Building Workbench..."
cd "$UPSTREAM_DIR"
npm install
npm run compile
echo "==> VeriTTY build completed successfully."
