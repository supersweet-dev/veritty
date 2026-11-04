#!/usr/bin/env bash
set -euo pipefail

# VeriTTY Installer and Updater
# Installs or updates the VeriTTY terminal-first VS Code distribution

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
  --deb              Install native Debian package (.deb) using sudo
  --version <tag>    Install specific release tag (example: v1.2.0)
  --uninstall        Remove VeriTTY binaries, desktop entry, data, and configs
  --help, -h         Show this message

ENVIRONMENT:
  VERITTY_INSTALL_DIR   Target directory for binary symlink (default: ~/.local/bin)
  VERITTY_DATA_DIR      Target directory for application (default: ~/.local/share/veritty)
  XDG_CONFIG_HOME       Config directory root (default: ~/.config)
EOF
}

CHECK_ONLY=0
INSTALL_DEB=0
SPECIFIC_TAG=""
UNINSTALL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --check)
      CHECK_ONLY=1
      shift
      ;;
    --deb)
      INSTALL_DEB=1
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
  rm -f "${INSTALL_DIR}/veritty-cockpit" 2>/dev/null || true
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

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Debian package installation option
if [ "$INSTALL_DEB" -eq 1 ] && command -v dpkg >/dev/null 2>&1; then
  DEB_URL=$(echo "$RELEASE_JSON" | grep -o '"browser_download_url": *"[^"]*veritty_[^"]*\.deb"' | head -n 1 | cut -d '"' -f 4 || true)
  if [ -n "$DEB_URL" ]; then
    echo "--> Downloading Debian package ${DEB_URL}..."
    curl -fsSL "$DEB_URL" -o "${TMP_DIR}/veritty.deb"
    echo "--> Installing package with apt/dpkg..."
    if [ "$(id -u)" = "0" ]; then
      apt-get install -y "${TMP_DIR}/veritty.deb" || dpkg -i "${TMP_DIR}/veritty.deb"
    elif command -v sudo >/dev/null 2>&1; then
      sudo apt-get install -y "${TMP_DIR}/veritty.deb" || sudo dpkg -i "${TMP_DIR}/veritty.deb"
    else
      echo "error: Root or sudo access required to install .deb package."
      exit 1
    fi
    echo "==> VeriTTY ${TARGET_TAG} installed."
    exit 0
  fi
fi

# Standalone tarball installation
mkdir -p "$INSTALL_DIR" "$CONFIG_DIR" "$DESKTOP_DIR"

ASSET_URL=""
if [ -n "${VERITTY_ARCHIVE_FILE:-}" ] && [ -f "${VERITTY_ARCHIVE_FILE}" ]; then
  echo "--> Using local archive file: ${VERITTY_ARCHIVE_FILE}..."
  cp "${VERITTY_ARCHIVE_FILE}" "${TMP_DIR}/archive.tar.gz"
else
  TAR_URL=$(echo "$RELEASE_JSON" | grep -o '"browser_download_url": *"[^"]*veritty-linux-x64[^"]*"' | head -n 1 | cut -d '"' -f 4 || true)
  if [ -z "$TAR_URL" ]; then
    echo "error: No application archive found for ${TARGET_TAG}."
    exit 1
  fi
  ASSET_URL="$TAR_URL"
  echo "--> Downloading ${ASSET_URL}..."
  curl -fsSL "$ASSET_URL" -o "${TMP_DIR}/archive.tar.gz"
fi

echo "--> Installing VeriTTY to ${DATA_DIR}..."
rm -rf "$DATA_DIR"
mkdir -p "$DATA_DIR"
tar -xzf "${TMP_DIR}/archive.tar.gz" -C "$DATA_DIR" --strip-components=1

# Link unified binary
ln -sf "${DATA_DIR}/bin/veritty" "${INSTALL_DIR}/veritty"
rm -f "${INSTALL_DIR}/veritty-cockpit" 2>/dev/null || true

# Install desktop entry
if [ -f "${DATA_DIR}/share/applications/veritty.desktop" ]; then
  cp "${DATA_DIR}/share/applications/veritty.desktop" "${DESKTOP_DIR}/veritty.desktop"
  sed -i "s|Exec=.*|Exec=${INSTALL_DIR}/veritty %F|" "${DESKTOP_DIR}/veritty.desktop" || true
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
  fi
fi

# Install AppArmor profile if system supports it and permissions allow
APPARMOR_SRC="${DATA_DIR}/share/apparmor/veritty"
if [ -d /etc/apparmor.d ] && [ -f "$APPARMOR_SRC" ]; then
  if [ "$(id -u)" = "0" ]; then
    cp "$APPARMOR_SRC" /etc/apparmor.d/veritty
    if command -v apparmor_parser >/dev/null 2>&1; then
      apparmor_parser -r /etc/apparmor.d/veritty 2>/dev/null || true
    fi
  elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    sudo cp "$APPARMOR_SRC" /etc/apparmor.d/veritty 2>/dev/null || true
    if command -v apparmor_parser >/dev/null 2>&1; then
      sudo apparmor_parser -r /etc/apparmor.d/veritty 2>/dev/null || true
    fi
  fi
fi

# Persist installer script for self-updating commands
INSTALLER_SRC="${BASH_SOURCE[0]:-}"
if [ -n "$INSTALLER_SRC" ] && [ -f "$INSTALLER_SRC" ]; then
  cp "$INSTALLER_SRC" "${CONFIG_DIR}/install.sh"
else
  curl -fsSL "https://raw.githubusercontent.com/${REPO}/main/install.sh" -o "${CONFIG_DIR}/install.sh" 2>/dev/null || true
fi
chmod +x "${CONFIG_DIR}/install.sh" 2>/dev/null || true

SHELL_DIR="${DATA_DIR}/shell"

echo "==> VeriTTY ${TARGET_TAG} installed."
echo "Binary available at: ${INSTALL_DIR}/veritty"

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

echo "==> Done. Launch with 'veritty'."
