#!/usr/bin/env bash
set -euo pipefail

# VeriTTY Quick Installer
# Installs the veritty CLI client and shell integrations

REPO="supersweet-dev/veritty"
INSTALL_DIR="${VERITTY_INSTALL_DIR:-$HOME/.local/bin}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/veritty"

echo "==> Installing VeriTTY..."

# Ensure target directories exist
mkdir -p "$INSTALL_DIR" "$CONFIG_DIR"

# Fetch latest release info from GitHub API
LATEST_JSON=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null || true)

if [ -z "$LATEST_JSON" ]; then
  echo "error: Failed to query latest release from GitHub."
  exit 1
fi

TAG_NAME=$(echo "$LATEST_JSON" | grep '"tag_name":' | head -n 1 | cut -d '"' -f 4)
echo "--> Found release: ${TAG_NAME}"

# Find CLI asset URL
ASSET_URL=$(echo "$LATEST_JSON" | grep 'browser_download_url' | grep 'veritty-cli-' | head -n 1 | cut -d '"' -f 4)

if [ -z "$ASSET_URL" ]; then
  echo "error: No CLI bundle found for release ${TAG_NAME}."
  exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "--> Downloading ${ASSET_URL}..."
curl -fsSL "$ASSET_URL" -o "${TMP_DIR}/veritty-cli.tar.gz"

echo "--> Extracting..."
tar -xzf "${TMP_DIR}/veritty-cli.tar.gz" -C "$TMP_DIR"

EXTRACTED_DIR=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)

# Install files to CONFIG_DIR and symlink binary to INSTALL_DIR
rm -rf "${CONFIG_DIR}/cli"
cp -r "$EXTRACTED_DIR" "${CONFIG_DIR}/cli"

ln -sf "${CONFIG_DIR}/cli/bin/veritty" "${INSTALL_DIR}/veritty"

echo "==> VeriTTY CLI installed to ${INSTALL_DIR}/veritty"

# Offer shell integration hints
echo ""
echo "To enable shell integration, add the following to your shell config:"
echo ""
echo "  # Bash (~/.bashrc):"
echo "  source ${CONFIG_DIR}/cli/shell/veritty.sh"
echo ""
echo "  # Zsh (~/.zshrc):"
echo "  source ${CONFIG_DIR}/cli/shell/veritty.sh"
echo ""
echo "  # Fish (~/.config/fish/config.fish):"
echo "  source ${CONFIG_DIR}/cli/shell/veritty.fish"
echo ""

if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo "Note: Make sure ${INSTALL_DIR} is in your PATH."
fi

echo "==> Installation complete! Run 'veritty --version' to test."
