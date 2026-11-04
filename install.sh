#!/usr/bin/env bash
set -euo pipefail

# VeriTTY Installer and Updater
# Installs or updates the all-in-one VeriTTY Cockpit application and CLI client

REPO="supersweet-dev/veritty"
INSTALL_DIR="${VERITTY_INSTALL_DIR:-$HOME/.local/bin}"
DATA_DIR="${VERITTY_DATA_DIR:-$HOME/.local/share/veritty}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/veritty"
DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"

print_help() {
  cat << EOF
VeriTTY Installer and Updater

USAGE:
  install.sh [OPTIONS]

OPTIONS:
  --check            Check for newer release without install
  --cli-only         Install only the CLI client
  --version <tag>    Install specific release tag (example: v1.1.0)
  --uninstall        Remove VeriTTY binaries, desktop entry, data, and configs
  --help, -h         Show this message

ENVIRONMENT:
  VERITTY_INSTALL_DIR   Target directory for binary symlinks (default: ~/.local/bin)
  VERITTY_DATA_DIR      Target directory for desktop app (default: ~/.local/share/veritty)
  XDG_CONFIG_HOME       Config directory root (default: ~/.config)
EOF
}

CHECK_ONLY=0
CLI_ONLY=0
SPECIFIC_TAG=""
UNINSTALL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --check)
      CHECK_ONLY=1
      shift
      ;;
    --cli-only)
      CLI_ONLY=1
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
  rm -f "${INSTALL_DIR}/veritty-cockpit"
  rm -f "${DESKTOP_DIR}/veritty.desktop"
  rm -rf "$DATA_DIR"
  rm -rf "$CONFIG_DIR"
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
  fi
  echo "==> VeriTTY uninstalled."
  echo "Remove any 'source .../veritty.sh' lines from your shell configuration."
  exit 0
fi

# Detect installed version
CURRENT_VERSION=""
if command -v "${INSTALL_DIR}/veritty" >/dev/null 2>&1; then
  CURRENT_VERSION=$("${INSTALL_DIR}/veritty" --version 2>/dev/null | awk '{print $2}' || true)
fi

# Query GitHub release metadata
if [ -n "$SPECIFIC_TAG" ]; then
  API_URL="https://api.github.com/repos/${REPO}/releases/tags/${SPECIFIC_TAG}"
else
  API_URL="https://api.github.com/repos/${REPO}/releases/latest"
fi

RELEASE_JSON=$(curl -fsSL "$API_URL" 2>/dev/null || true)
if [ -z "$RELEASE_JSON" ]; then
  echo "error: Failed to query release metadata from ${API_URL}"
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
    echo "==> VeriTTY is up to date (${TARGET_TAG})."
    exit 0
  fi
  echo "==> Updating VeriTTY from ${CURRENT_VERSION} to ${TARGET_TAG}..."
else
  echo "==> Installing VeriTTY (${TARGET_TAG})..."
fi

mkdir -p "$INSTALL_DIR" "$CONFIG_DIR" "$DESKTOP_DIR"

# Select release asset
ASSET_URL=""
IS_DESKTOP_BUNDLE=0

if [ "$CLI_ONLY" -eq 0 ]; then
  # Look for desktop all-in-one bundle
  DESKTOP_URL=$(echo "$RELEASE_JSON" | grep -o '"browser_download_url": *"[^"]*veritty-linux-x64[^"]*"' | head -n 1 | cut -d '"' -f 4 || true)
  if [ -n "$DESKTOP_URL" ]; then
    ASSET_URL="$DESKTOP_URL"
    IS_DESKTOP_BUNDLE=1
  fi
fi

if [ -z "$ASSET_URL" ]; then
  # Fallback to CLI bundle
  CLI_URL=$(echo "$RELEASE_JSON" | grep -o '"browser_download_url": *"[^"]*veritty-cli-[^"]*"' | head -n 1 | cut -d '"' -f 4 || true)
  if [ -z "$CLI_URL" ]; then
    echo "error: No matching release asset found for ${TARGET_TAG}."
    exit 1
  fi
  ASSET_URL="$CLI_URL"
  IS_DESKTOP_BUNDLE=0
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if [ -n "${VERITTY_ARCHIVE_FILE:-}" ] && [ -f "${VERITTY_ARCHIVE_FILE}" ]; then
  echo "--> Using local archive file: ${VERITTY_ARCHIVE_FILE}..."
  cp "${VERITTY_ARCHIVE_FILE}" "${TMP_DIR}/archive.tar.gz"
  if [[ "${VERITTY_ARCHIVE_FILE}" == *"veritty-linux-x64"* ]]; then
    IS_DESKTOP_BUNDLE=1
  fi
else
  echo "--> Downloading ${ASSET_URL}..."
  curl -fsSL "$ASSET_URL" -o "${TMP_DIR}/archive.tar.gz"
fi

if [ "$IS_DESKTOP_BUNDLE" -eq 1 ]; then
  echo "--> Installing VeriTTY Cockpit to ${DATA_DIR}..."
  rm -rf "$DATA_DIR"
  mkdir -p "$DATA_DIR"
  tar -xzf "${TMP_DIR}/archive.tar.gz" -C "$DATA_DIR" --strip-components=1

  # Link binaries
  if [ -f "${DATA_DIR}/bin/veritty" ]; then
    ln -sf "${DATA_DIR}/bin/veritty" "${INSTALL_DIR}/veritty"
  elif [ -f "${DATA_DIR}/veritty" ]; then
    ln -sf "${DATA_DIR}/veritty" "${INSTALL_DIR}/veritty"
  fi

  if [ -f "${DATA_DIR}/bin/veritty-cockpit" ]; then
    ln -sf "${DATA_DIR}/bin/veritty-cockpit" "${INSTALL_DIR}/veritty-cockpit"
  elif [ -f "${DATA_DIR}/veritty" ]; then
    ln -sf "${DATA_DIR}/veritty" "${INSTALL_DIR}/veritty-cockpit"
  fi

  # Install desktop entry
  if [ -f "${DATA_DIR}/share/applications/veritty.desktop" ]; then
    cp "${DATA_DIR}/share/applications/veritty.desktop" "${DESKTOP_DIR}/veritty.desktop"
    # Ensure Exec points to binary
    sed -i "s|Exec=.*|Exec=${INSTALL_DIR}/veritty-cockpit %F|" "${DESKTOP_DIR}/veritty.desktop" || true
    if command -v update-desktop-database >/dev/null 2>&1; then
      update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
    fi
  fi

  # Shell integration directory
  SHELL_DIR="${DATA_DIR}/shell"
else
  echo "--> Installing VeriTTY CLI to ${CONFIG_DIR}/cli..."
  rm -rf "${CONFIG_DIR}/cli"
  mkdir -p "${CONFIG_DIR}/cli"
  tar -xzf "${TMP_DIR}/archive.tar.gz" -C "${CONFIG_DIR}/cli" --strip-components=1

  ln -sf "${CONFIG_DIR}/cli/bin/veritty" "${INSTALL_DIR}/veritty"
  SHELL_DIR="${CONFIG_DIR}/cli/shell"
fi

# Persist installer script for self-updating commands
INSTALLER_SRC="${BASH_SOURCE[0]:-}"
if [ -n "$INSTALLER_SRC" ] && [ -f "$INSTALLER_SRC" ]; then
  cp "$INSTALLER_SRC" "${CONFIG_DIR}/install.sh"
else
  curl -fsSL "https://raw.githubusercontent.com/${REPO}/main/install.sh" -o "${CONFIG_DIR}/install.sh" 2>/dev/null || true
fi
chmod +x "${CONFIG_DIR}/install.sh" 2>/dev/null || true

echo "==> VeriTTY ${TARGET_TAG} installed."
echo "Binaries available in ${INSTALL_DIR}:"
echo "  veritty         (unified launcher and CLI)"
if [ "$IS_DESKTOP_BUNDLE" -eq 1 ]; then
  echo "  veritty-cockpit (graphical desktop cockpit)"
fi

if [ -z "$CURRENT_VERSION" ]; then
  echo ""
  echo "Add shell integration to your shell configuration:"
  echo ""
  echo "  # Bash (~/.bashrc) or Zsh (~/.zshrc):"
  echo "  source ${SHELL_DIR}/veritty.sh"
  echo ""
  echo "  # Fish (~/.config/fish/config.fish):"
  echo "  source ${SHELL_DIR}/veritty.fish"
  echo ""
fi

if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo "Note: Add ${INSTALL_DIR} to your PATH."
fi

echo "==> Done. Launch with 'veritty' or 'veritty-cockpit'."
