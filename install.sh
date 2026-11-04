#!/usr/bin/env bash
set -euo pipefail

# VeriTTY Self-Updating Installer
# Installs, updates, or checks the veritty CLI client and shell integrations

REPO="supersweet-dev/veritty"
INSTALL_DIR="${VERITTY_INSTALL_DIR:-$HOME/.local/bin}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/veritty"

print_help() {
  cat << EOF
VeriTTY Installer & Updater

USAGE:
  install.sh [OPTIONS]

OPTIONS:
  --check            Check if a newer version is available without installing
  --version <tag>    Install a specific version (e.g. v1.0.1)
  --uninstall        Remove VeriTTY binary, configurations, and scripts
  --help, -h         Show this help message

ENVIRONMENT:
  VERITTY_INSTALL_DIR   Target directory for binary symlink (default: ~/.local/bin)
  XDG_CONFIG_HOME       Config root directory (default: ~/.config)
EOF
}

CHECK_ONLY=0
SPECIFIC_TAG=""
UNINSTALL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --check)
      CHECK_ONLY=1
      shift
      ;;
    --version)
      SPECIFIC_TAG="$2"
      shift 2
      ;;
    --uninstall)
      UNINSTALL=1
      shift
      ;;
    --help|-h)
      print_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      print_help
      exit 1
      ;;
  esac
done

# Handle uninstall
if [ "$UNINSTALL" -eq 1 ]; then
  echo "==> Uninstalling VeriTTY..."
  rm -f "${INSTALL_DIR}/veritty"
  rm -rf "$CONFIG_DIR"
  echo "==> Removed ${INSTALL_DIR}/veritty and ${CONFIG_DIR}."
  echo "Remember to remove any 'source .../veritty.sh' lines from your shell config."
  exit 0
fi

# Detect currently installed version if available
CURRENT_VERSION=""
if command -v "${INSTALL_DIR}/veritty" >/dev/null 2>&1; then
  CURRENT_VERSION=$("${INSTALL_DIR}/veritty" --version 2>/dev/null | awk '{print $2}' || true)
fi

# Query GitHub for release metadata
if [ -n "$SPECIFIC_TAG" ]; then
  API_URL="https://api.github.com/repos/${REPO}/releases/tags/${SPECIFIC_TAG}"
else
  API_URL="https://api.github.com/repos/${REPO}/releases/latest"
fi

RELEASE_JSON=$(curl -fsSL "$API_URL" 2>/dev/null || true)
if [ -z "$RELEASE_JSON" ]; then
  echo "error: Failed to query release information from ${API_URL}"
  exit 1
fi

TARGET_TAG=$(echo "$RELEASE_JSON" | grep -o '"tag_name": *"[^"]*"' | head -n 1 | cut -d '"' -f 4)
CLEAN_TARGET_TAG="${TARGET_TAG#v}"

# Handle --check
if [ "$CHECK_ONLY" -eq 1 ]; then
  if [ -n "$CURRENT_VERSION" ]; then
    CLEAN_CURRENT_VERSION="${CURRENT_VERSION#v}"
    if [ "$CLEAN_CURRENT_VERSION" = "$CLEAN_TARGET_TAG" ]; then
      echo "VeriTTY is up to date (${TARGET_TAG})."
      exit 0
    else
      echo "Update available: ${CURRENT_VERSION} -> ${TARGET_TAG}"
      exit 10
    fi
  else
    echo "VeriTTY is not installed. Latest release: ${TARGET_TAG}"
    exit 0
  fi
fi

if [ -n "$CURRENT_VERSION" ]; then
  CLEAN_CURRENT_VERSION="${CURRENT_VERSION#v}"
  if [ "$CLEAN_CURRENT_VERSION" = "$CLEAN_TARGET_TAG" ] && [ -z "$SPECIFIC_TAG" ]; then
    echo "==> VeriTTY is already up to date (${TARGET_TAG})."
    exit 0
  fi
  echo "==> Updating VeriTTY from ${CURRENT_VERSION} to ${TARGET_TAG}..."
else
  echo "==> Installing VeriTTY (${TARGET_TAG})..."
fi

# Ensure target directories exist
mkdir -p "$INSTALL_DIR" "$CONFIG_DIR"

# Locate CLI tarball asset
ASSET_URL=$(echo "$RELEASE_JSON" | grep -o '"browser_download_url": *"[^"]*veritty-cli-[^"]*"' | head -n 1 | cut -d '"' -f 4)
if [ -z "$ASSET_URL" ]; then
  echo "error: No CLI bundle found for release ${TARGET_TAG}."
  exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "--> Downloading ${ASSET_URL}..."
curl -fsSL "$ASSET_URL" -o "${TMP_DIR}/veritty-cli.tar.gz"

echo "--> Extracting..."
tar -xzf "${TMP_DIR}/veritty-cli.tar.gz" -C "$TMP_DIR"
EXTRACTED_DIR=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)

# Install files to CONFIG_DIR/cli and symlink to INSTALL_DIR/veritty
rm -rf "${CONFIG_DIR}/cli"
cp -r "$EXTRACTED_DIR" "${CONFIG_DIR}/cli"
ln -sf "${CONFIG_DIR}/cli/bin/veritty" "${INSTALL_DIR}/veritty"

# Persist installer script locally for self-updating commands
cp "${BASH_SOURCE[0]}" "${CONFIG_DIR}/install.sh"
chmod +x "${CONFIG_DIR}/install.sh"

echo "==> VeriTTY ${TARGET_TAG} installed at ${INSTALL_DIR}/veritty"

if [ -z "$CURRENT_VERSION" ]; then
  echo ""
  echo "To enable shell integration, add the following to your shell config:"
  echo ""
  echo "  # Bash (~/.bashrc) or Zsh (~/.zshrc):"
  echo "  source ${CONFIG_DIR}/cli/shell/veritty.sh"
  echo ""
  echo "  # Fish (~/.config/fish/config.fish):"
  echo "  source ${CONFIG_DIR}/cli/shell/veritty.fish"
  echo ""
fi

if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo "Note: Make sure ${INSTALL_DIR} is in your PATH."
fi

echo "==> Done! Run 'veritty --version' or 'veritty update' to test."
