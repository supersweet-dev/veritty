<p align="center">
  <h1 align="center">VeriTTY</h1>
  <p align="center">A terminal-first VS Code distribution for tiling window managers and multi-monitor setups.</p>
  <p align="center">
    <a href="#overview">Overview</a> |
    <a href="#design">Design</a> |
    <a href="#architecture">Architecture</a> |
    <a href="#installation">Installation</a> |
    <a href="#usage">Usage</a> |
    <a href="#apparmor">AppArmor</a> |
    <a href="#build-from-source">Build</a> |
    <a href="#license">License</a>
  </p>
</p>

---

## Overview

VeriTTY is a terminal-first distribution of Code-OSS (VS Code):

* **Terminal as Canvas**: The main window is a full-screen terminal multiplexer powered by local pseudoterminals.
* **Detached Native Windows**: File editors, diff views, and previews open as native OS windows for your window manager (i3, Sway, Hyprland, bspwm) to place and tile.
* **Dynamic Overlay Drawers**: File trees, git panels, and diagnostics slide over the terminal as overlays and dismiss when you resume typing in the shell.
* **Zero Telemetry**: All telemetry, crash reporters, and experiment services are stripped. Extension queries point to Open VSX.
* **Sandbox Support**: Includes an AppArmor profile configured for modern Ubuntu 24.04 and Debian unprivileged user namespaces.

---

## Design

Standard code editors place the terminal in a panel docked beneath editor tabs. Developers who work from the command line face friction with this layout: logs lose column width, tabs crowd the display, and context shifts away from the shell.

VeriTTY assigns the main window to the terminal multiplexer. File editors, diff viewers, and previews open as detached native OS windows. Your desktop window manager controls their placement, sizing, and workspaces. Tool drawers for the file tree, git status, and diagnostics slide over the terminal on demand and dismiss when you resume typing in the shell.

---

## Architecture

```
                                 ┌──────────────────────────────────────────┐
                                 │         VeriTTY (Main Window)            │
                                 │                                          │
                                 │  ┌────────────────────────────────────┐  │
 ┌──────────────────────┐        │  │                                    │  │
 │   Dynamic Drawers    │◄──────►│  │     Terminal Multiplexer Canvas    │  │
 │ (File Tree, Git, LSP)│        │  │     (xterm.js + PTY Engine)        │  │
 └──────────────────────┘        │  │                                    │  │
                                 │  └────────────────────────────────────┘  │
                                 └─────────────────────▲────────────────────┘
                                                       │
                                        IPC / Unix Sockets & OSC Hooks
                                                       │
                   ┌───────────────────────────────────┼───────────────────────────────────┐
                   ▼                                   ▼                                   ▼
      ┌─────────────────────────┐         ┌─────────────────────────┐         ┌─────────────────────────┐
      │  Detached Editor Window │         │  Detached Diff Window   │         │ Detached Preview Window │
      │      (Native OS)        │         │       (Native OS)       │         │       (Native OS)       │
      │       src/main.rs       │         │     HEAD vs Working     │         │   Markdown / Webview    │
      └─────────────────────────┘         └─────────────────────────┘         └─────────────────────────┘
```

---

## Installation

### Option 1: Debian / Ubuntu Package (.deb)

Download and install the native package:

```bash
# Download from latest release
curl -fsSLO https://github.com/supersweet-dev/veritty/releases/latest/download/veritty_amd64.deb

# Install package and AppArmor profile
sudo apt install ./veritty_amd64.deb
```

### Option 2: Automated User Installer

Install VeriTTY into `~/.local/share/veritty/` and create `~/.local/bin/veritty`:

```bash
curl -fsSL https://raw.githubusercontent.com/supersweet-dev/veritty/main/install.sh | bash
```

### Option 3: Portable Linux Tarball

Download `veritty-linux-x64.tar.gz` from [Releases](https://github.com/supersweet-dev/veritty/releases), extract the archive, and run `bin/veritty`.

---

## Usage

```bash
# Launch VeriTTY
veritty

# Open a workspace folder
veritty /path/to/project

# Open a file in a detached window
veritty open src/index.ts:42:10

# Open a diff view between two files
veritty diff old.py new.py

# Toggle dynamic drawers
veritty drawer toggle explorer
veritty drawer peek diagnostics

# Pipe stdin into a detached scratch buffer
cat build.log | veritty scratch
```

### Shell Integration

Add directory synchronization and aliases to your shell configuration:

```bash
# Bash (~/.bashrc) or Zsh (~/.zshrc)
source ~/.local/share/veritty/shell/veritty.sh

# Fish (~/.config/fish/config.fish)
source ~/.local/share/veritty/shell/veritty.fish
```

---

## AppArmor

Modern Linux distributions (Ubuntu 24.04 and Debian 12+) restrict unprivileged user namespaces by default. Without an AppArmor profile, Electron applications fail to create sandbox helper processes.

VeriTTY includes an AppArmor profile in `resources/apparmor/veritty`.
* Installing the `.deb` package registers the profile in `/etc/apparmor.d/veritty` during install.
* The application launcher detects whether AppArmor restricts user namespaces and falls back to unprivileged execution if the profile is not yet loaded.

---

## Build from Source

### Prerequisites
* Node.js 20 or higher
* npm 10 or higher
* Git, C/C++ compiler, Python 3
* Native libraries: `libkrb5-dev`, `libsecret-1-dev`, `libx11-dev`, `libxkbfile-dev`

### Package Standalone Distribution
```bash
git clone https://github.com/supersweet-dev/veritty.git
cd veritty

# Build .deb package and .tar.gz archive
./build/package-desktop.sh v1.2.0
```

Built artifacts appear in `dist-assets/`:
* `veritty_1.2.0_amd64.deb`
* `veritty-linux-x64-v1.2.0.tar.gz`

---

## License

MIT License. See [LICENSE](file:///root/projects/veritty/LICENSE).
