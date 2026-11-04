#!/usr/bin/env bash
set -euo pipefail

# VeriTTY Cockpit Desktop Packaging Script
# Packages the standalone Linux application bundle (Electron, Cockpit runtime, extensions, CLI)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_DIR="${ROOT_DIR}/build/upstream"
DIST_DIR="${ROOT_DIR}/dist"
STAGE_DIR="${DIST_DIR}/veritty-linux-x64"
ASSETS_DIR="${ROOT_DIR}/dist-assets"

VERSION="${1:-v1.1.0}"
CLEAN_VERSION="${VERSION#v}"

echo "==> Packaging VeriTTY Desktop Application (${VERSION})..."

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
         "${STAGE_DIR}/shell"

# Copy Electron runtime files
cp -r .build/electron/* "$STAGE_DIR/"
rm -f "${STAGE_DIR}/resources/default_app.asar"

# Copy Workbench Manifests and Compiled Core
cp package.json product.json "$STAGE_DIR/resources/app/"
cp -r out "$STAGE_DIR/resources/app/"

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

# Install Executable Launchers in bin/
cat << 'EOF' > "${STAGE_DIR}/bin/veritty"
#!/usr/bin/env bash
TARGET="${BASH_SOURCE[0]}"
while [ -h "$TARGET" ]; do
  DIR="$(cd -P "$(dirname "$TARGET")" && pwd)"
  TARGET="$(readlink "$TARGET")"
  [[ $TARGET != /* ]] && TARGET="$DIR/$TARGET"
done
BUNDLE_DIR="$(cd -P "$(dirname "$TARGET")/.." && pwd)"

# Launch Cockpit GUI when invoked with no arguments or cockpit command
if [ $# -eq 0 ]; then
  exec "${BUNDLE_DIR}/bin/veritty-cockpit" "."
elif [ "$1" = "cockpit" ]; then
  shift
  exec "${BUNDLE_DIR}/bin/veritty-cockpit" "$@"
fi

# Route IPC commands through the CLI client
CLI_SCRIPT="${BUNDLE_DIR}/resources/app/cli/dist/index.js"
if [ -f "$CLI_SCRIPT" ] && command -v node >/dev/null 2>&1; then
  VERITTY_COCKPIT_BIN="${BUNDLE_DIR}/bin/veritty-cockpit" exec node "$CLI_SCRIPT" "$@"
else
  ELECTRON_RUN_AS_NODE=1 VERITTY_COCKPIT_BIN="${BUNDLE_DIR}/bin/veritty-cockpit" exec "${BUNDLE_DIR}/veritty" "${BUNDLE_DIR}/resources/app/cli/dist/index.js" "$@"
fi
EOF
chmod +x "${STAGE_DIR}/bin/veritty"

cat << 'EOF' > "${STAGE_DIR}/bin/veritty-cockpit"
#!/usr/bin/env bash
TARGET="${BASH_SOURCE[0]}"
while [ -h "$TARGET" ]; do
  DIR="$(cd -P "$(dirname "$TARGET")" && pwd)"
  TARGET="$(readlink "$TARGET")"
  [[ $TARGET != /* ]] && TARGET="$DIR/$TARGET"
done
BUNDLE_DIR="$(cd -P "$(dirname "$TARGET")/.." && pwd)"

ARGS=()
if [ "$(id -u)" = "0" ]; then
  ARGS+=("--no-sandbox")
fi

exec "${BUNDLE_DIR}/veritty" "${ARGS[@]}" "${BUNDLE_DIR}/resources/app" "$@"
EOF
chmod +x "${STAGE_DIR}/bin/veritty-cockpit"

# Copy Shell Integrations
cp -r "${ROOT_DIR}/shell"/* "${STAGE_DIR}/shell/"

# Copy Desktop Entry and Icons
cp "${UPSTREAM_DIR}/resources/linux/code.png" "${STAGE_DIR}/share/pixmaps/veritty.png"
cat << 'EOF' > "${STAGE_DIR}/share/applications/veritty.desktop"
[Desktop Entry]
Name=VeriTTY
Comment=Terminal-first Inverted Cockpit
GenericName=Cockpit IDE
Exec=veritty-cockpit %F
Icon=veritty
Type=Application
StartupNotify=false
StartupWMClass=VeriTTY
Categories=Development;IDE;System;TerminalEmulator;
MimeType=application/x-veritty-workspace;
Actions=new-window;

[Desktop Action new-window]
Name=New Window
Exec=veritty-cockpit --new-window %F
Icon=veritty
EOF

# 6. Create Tarball Archive
mkdir -p "$ASSETS_DIR"
TARBALL_NAME="veritty-linux-x64-${VERSION}.tar.gz"
echo "--> Creating ${ASSETS_DIR}/${TARBALL_NAME}..."
(cd "$DIST_DIR" && tar -czf "${ASSETS_DIR}/${TARBALL_NAME}" "veritty-linux-x64")
(cd "$ASSETS_DIR" && cp "${TARBALL_NAME}" "veritty-linux-x64.tar.gz")

echo "==> Standalone VeriTTY Cockpit Desktop packaging finished."
ls -lh "${ASSETS_DIR}/${TARBALL_NAME}"
