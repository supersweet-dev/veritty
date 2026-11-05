#!/usr/bin/env bash
set -euo pipefail

# VeriTTY Desktop Application Packager
# Packages the standalone Linux application bundle (tar.gz) and native Debian package (.deb)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
UPSTREAM_DIR="${ROOT_DIR}/build/upstream"
DIST_DIR="${ROOT_DIR}/dist"
STAGE_DIR="${DIST_DIR}/veritty-linux-x64"
ASSETS_DIR="${ROOT_DIR}/dist-assets"

VERSION="${1:-v1.2.0}"
CLEAN_VERSION="${VERSION#v}"

echo "==> Packaging VeriTTY (${VERSION})..."

# 1. Build CLI client
echo "--> Compiling CLI client..."
(cd "${ROOT_DIR}/cli" && npm install && npm run build && npm test)

# 2. Build Companion Extension
echo "--> Compiling Companion Extension..."
(cd "${ROOT_DIR}/extensions/veritty" && npm install && npm run build)

# 3. Ensure Upstream and Patches
if [ ! -d "$UPSTREAM_DIR" ]; then
  echo "--> Fetching upstream Code-OSS..."
  "${ROOT_DIR}/build/fetch-base.sh"
fi

echo "--> Applying Patches..."
"${ROOT_DIR}/build/apply-patches.sh"

# Bundle companion extension into upstream extensions directory
echo "--> Bundling Companion Extension into upstream..."
mkdir -p "${UPSTREAM_DIR}/extensions/veritty"
cp -r "${ROOT_DIR}/extensions/veritty"/* "${UPSTREAM_DIR}/extensions/veritty/"

# 4. Compile Workbench
echo "--> Preparing Upstream Dependencies..."
cd "$UPSTREAM_DIR"
if [ ! -d "node_modules" ]; then
  npm ci --prefer-offline --no-audit
fi

# Fetch electron runtime binary if missing
if [ ! -f ".build/electron/veritty" ]; then
  echo "--> Fetching Electron binary..."
  node build/lib/electron.js
fi

# Compile typescript sources if missing
if [ ! -f "out/main.js" ]; then
  echo "--> Compiling Workbench TypeScript..."
  NODE_OPTIONS="--max-old-space-size=5120" npm run compile
fi

# Ensure NLS message placeholder
if [ ! -f "out/nls.messages.json" ]; then
  echo '{}' > out/nls.messages.json
fi

# 5. Assemble Standalone Application Bundle
echo "--> Assembling Application Bundle in ${STAGE_DIR}..."
rm -rf "$STAGE_DIR"
mkdir -p "${STAGE_DIR}/bin" \
         "${STAGE_DIR}/resources/app" \
         "${STAGE_DIR}/share/applications" \
         "${STAGE_DIR}/share/pixmaps" \
         "${STAGE_DIR}/share/apparmor" \
         "${STAGE_DIR}/shell"

# Copy Electron runtime files
cp -r .build/electron/* "$STAGE_DIR/"
rm -f "${STAGE_DIR}/resources/default_app.asar"

# Copy Workbench Manifests and Compiled Core
cp package.json product.json "$STAGE_DIR/resources/app/"
cp -r out "$STAGE_DIR/resources/app/"
cp -r resources "$STAGE_DIR/resources/app/"

# Copy Production Dependencies
echo "--> Copying Production Node Modules..."
mkdir -p "$STAGE_DIR/resources/app/node_modules"
node -e '
  const fs = require("fs");
  const path = require("path");
  const { getProductionDependencies } = require("./build/lib/dependencies");
  const deps = getProductionDependencies(".");
  const root = path.resolve(".");
  const dest = path.resolve(process.argv[1]);

  for (const dep of deps) {
    const rel = path.relative(root, dep);
    const target = path.join(dest, rel.replace(/^node_modules\//, ""));
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.cpSync(dep, target, { recursive: true, dereference: true });
  }
' "$STAGE_DIR/resources/app/node_modules"

# Copy Built-in Extensions
echo "--> Copying Built-in Extensions..."
cp -r extensions "$STAGE_DIR/resources/app/"

# Copy CLI Dist and manifest
mkdir -p "${STAGE_DIR}/resources/app/cli"
cp "${ROOT_DIR}/cli/package.json" "${STAGE_DIR}/resources/app/cli/"
cp -r "${ROOT_DIR}/cli/dist" "${STAGE_DIR}/resources/app/cli/"

# Install Unified Executable Launcher in bin/veritty
cat << 'EOF' > "${STAGE_DIR}/bin/veritty"
#!/usr/bin/env bash
TARGET="${BASH_SOURCE[0]:-$0}"
while [ -h "$TARGET" ]; do
  DIR="$(cd -P "$(dirname "$TARGET")" && pwd)"
  TARGET="$(readlink "$TARGET")"
  [[ $TARGET != /* ]] && TARGET="$DIR/$TARGET"
done
BUNDLE_DIR="$(cd -P "$(dirname "$TARGET")/.." && pwd)"

# Resolve sandbox arguments for modern Linux (Ubuntu 24.04 AppArmor restrictions)
SANDBOX_ARGS=()
if [ "$(id -u)" = "0" ]; then
  SANDBOX_ARGS+=("--no-sandbox")
elif [ -f /proc/sys/kernel/apparmor_restrict_unprivileged_userns ] && [ "$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns 2>/dev/null)" = "1" ]; then
  # Check if an active AppArmor profile allows userns for veritty
  if ! command -v aa-status >/dev/null 2>&1 || ! aa-status 2>/dev/null | grep -q "veritty"; then
    SANDBOX_ARGS+=("--no-sandbox")
  fi
fi

# Ensure Code-OSS unbundled dev loader and CSS module discovery are active
export VSCODE_DEV=1

# Launch VeriTTY when invoked with no arguments or with a directory target
if [ $# -eq 0 ]; then
  exec "${BUNDLE_DIR}/veritty" "${SANDBOX_ARGS[@]}" "${BUNDLE_DIR}/resources/app" "."
elif [ $# -eq 1 ] && [ -d "$1" ]; then
  exec "${BUNDLE_DIR}/veritty" "${SANDBOX_ARGS[@]}" "${BUNDLE_DIR}/resources/app" "$1"
fi

# Route IPC commands through the CLI client
CLI_SCRIPT="${BUNDLE_DIR}/resources/app/cli/dist/index.js"
if [ -f "$CLI_SCRIPT" ] && command -v node >/dev/null 2>&1; then
  VERITTY_APP_BIN="${BUNDLE_DIR}/veritty" exec node "$CLI_SCRIPT" "$@"
else
  ELECTRON_RUN_AS_NODE=1 VERITTY_APP_BIN="${BUNDLE_DIR}/veritty" exec "${BUNDLE_DIR}/veritty" "${CLI_SCRIPT}" "$@"
fi
EOF
chmod +x "${STAGE_DIR}/bin/veritty"

# Copy Shell Integrations
cp -r "${ROOT_DIR}/shell"/* "${STAGE_DIR}/shell/"

# Copy Desktop Entry and Icons
cp "${UPSTREAM_DIR}/resources/linux/code.png" "${STAGE_DIR}/share/pixmaps/veritty.png"
cat << 'EOF' > "${STAGE_DIR}/share/applications/veritty.desktop"
[Desktop Entry]
Name=VeriTTY
Comment=Terminal-first VS Code distribution
GenericName=Code Editor
Exec=veritty %F
Icon=veritty
Type=Application
StartupNotify=false
StartupWMClass=VeriTTY
Categories=Development;IDE;System;TerminalEmulator;
MimeType=application/x-veritty-workspace;
Actions=new-window;

[Desktop Action new-window]
Name=New Window
Exec=veritty --new-window %F
Icon=veritty
EOF

# Copy AppArmor profile template
cp "${ROOT_DIR}/resources/apparmor/veritty" "${STAGE_DIR}/share/apparmor/veritty"

mkdir -p "$ASSETS_DIR"

# 6. Create Tarball Archive
TARBALL_NAME="veritty-linux-x64-${VERSION}.tar.gz"
echo "--> Creating ${ASSETS_DIR}/${TARBALL_NAME}..."
(cd "$DIST_DIR" && tar -czf "${ASSETS_DIR}/${TARBALL_NAME}" "veritty-linux-x64")
(cd "$ASSETS_DIR" && cp "${TARBALL_NAME}" "veritty-linux-x64.tar.gz")

# 7. Create Native Debian Package (.deb)
if command -v dpkg-deb >/dev/null 2>&1; then
  echo "--> Building Debian package (.deb)..."
  DEB_STAGE="${DIST_DIR}/deb-stage"
  rm -rf "$DEB_STAGE"
  mkdir -p "${DEB_STAGE}/DEBIAN" \
           "${DEB_STAGE}/usr/bin" \
           "${DEB_STAGE}/usr/share/veritty" \
           "${DEB_STAGE}/usr/share/applications" \
           "${DEB_STAGE}/usr/share/pixmaps" \
           "${DEB_STAGE}/etc/apparmor.d"

  # Copy application files to /usr/share/veritty
  cp -r "${STAGE_DIR}"/* "${DEB_STAGE}/usr/share/veritty/"

  # Symlink main binary to /usr/bin/veritty
  ln -sf /usr/share/veritty/bin/veritty "${DEB_STAGE}/usr/bin/veritty"

  # Desktop entry and icon
  cp "${STAGE_DIR}/share/applications/veritty.desktop" "${DEB_STAGE}/usr/share/applications/veritty.desktop"
  cp "${STAGE_DIR}/share/pixmaps/veritty.png" "${DEB_STAGE}/usr/share/pixmaps/veritty.png"

  # AppArmor profile in /etc/apparmor.d/veritty
  cp "${ROOT_DIR}/resources/apparmor/veritty" "${DEB_STAGE}/etc/apparmor.d/veritty"

  # Control file
  cat << EOF > "${DEB_STAGE}/DEBIAN/control"
Package: veritty
Version: ${CLEAN_VERSION}
Section: devel
Priority: optional
Architecture: amd64
Maintainer: VeriTTY Contributors <support@supersweet.dev>
Description: Terminal-first VS Code distribution
 A terminal-first Code-OSS distribution for tiling window managers.
 The terminal multiplexer occupies the root canvas, file editors open in
 detached native OS windows, and toolbars function as dynamic overlay drawers.
EOF

  # Maintainer scripts
  cat << 'EOF' > "${DEB_STAGE}/DEBIAN/postinst"
#!/usr/bin/env sh
set -e

# Reload desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications 2>/dev/null || true
fi

# Reload AppArmor profile if AppArmor is active
if [ -f /etc/apparmor.d/veritty ] && command -v apparmor_parser >/dev/null 2>&1; then
  apparmor_parser -r /etc/apparmor.d/veritty 2>/dev/null || true
fi
EOF
  chmod 755 "${DEB_STAGE}/DEBIAN/postinst"

  cat << 'EOF' > "${DEB_STAGE}/DEBIAN/postrm"
#!/usr/bin/env sh
set -e

if [ "$1" = "remove" ] || [ "$1" = "purge" ]; then
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications 2>/dev/null || true
  fi
  if [ -f /etc/apparmor.d/veritty ] && command -v apparmor_parser >/dev/null 2>&1; then
    apparmor_parser -R /etc/apparmor.d/veritty 2>/dev/null || true
  fi
fi
EOF
  chmod 755 "${DEB_STAGE}/DEBIAN/postrm"

  DEB_NAME="veritty_${CLEAN_VERSION}_amd64.deb"
  dpkg-deb --build --root-owner-group "$DEB_STAGE" "${ASSETS_DIR}/${DEB_NAME}"
  cp "${ASSETS_DIR}/${DEB_NAME}" "${ASSETS_DIR}/veritty_amd64.deb"
  rm -rf "$DEB_STAGE"
fi

echo "==> VeriTTY packaging finished."
ls -lh "${ASSETS_DIR}"/veritty*
