#!/usr/bin/env bash
set -euo pipefail

# VeriTTY Upstream Base Fetcher
# Clones or checks out a shallow copy of upstream Code-OSS / VSCodium

CODE_TAG="${CODE_TAG:-1.96.4}"
UPSTREAM_REPO="${UPSTREAM_REPO:-https://github.com/microsoft/vscode.git}"
UPSTREAM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/build/upstream"

echo "==> VeriTTY: Fetching upstream Code-OSS (tag: ${CODE_TAG})..."

mkdir -p "$(dirname "$UPSTREAM_DIR")"

if [ -d "$UPSTREAM_DIR/.git" ]; then
  echo "==> Upstream directory already exists. Fetching updates..."
  git -C "$UPSTREAM_DIR" fetch --depth=1 origin tag "${CODE_TAG}"
  git -C "$UPSTREAM_DIR" checkout -f "${CODE_TAG}"
else
  echo "==> Shallow cloning upstream tag ${CODE_TAG} into ${UPSTREAM_DIR}..."
  git clone --depth=1 --branch "${CODE_TAG}" "$UPSTREAM_REPO" "$UPSTREAM_DIR"
fi

echo "==> Upstream ready at: ${UPSTREAM_DIR}"
