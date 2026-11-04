<p align="center">
  <h1 align="center">VeriTTY</h1>
  <p align="center">A terminal-first Code-OSS fork for tiling window managers and multi-monitor setups.</p>
  <p align="center">
    <a href="#what-is-veritty">What is VeriTTY</a> |
    <a href="#design">Design</a> |
    <a href="#architecture">Architecture</a> |
    <a href="#installation">Installation</a> |
    <a href="#shell-ipc">Shell IPC</a> |
    <a href="#build-from-source">Build</a> |
    <a href="#license">License</a>
  </p>
</p>

---

## What is VeriTTY?

VeriTTY is an all-in-one graphical developer cockpit:

* **VeriTTY Cockpit**: The desktop application. The root canvas is a terminal multiplexer powered by local pseudoterminals. File editors, diffs, and previews open as detached native OS windows that your window manager arranges.
* **The Unified CLI (`veritty`)**: A command-line client for your shell. Run `veritty` to launch the Cockpit, or use `veritty open <file>` to route files from existing terminal sessions into detached editor windows.
* **The IPC Companion**: A built-in extension packaged inside the Cockpit that manages the local domain socket server.
* **The Patches**: Clean source modifications to Code-OSS that remove telemetry, invert the workbench, redirect editors to auxiliary windows, and convert toolbars into dynamic overlay drawers.

---

## Design

Standard code editors place the terminal in a panel docked beneath editor tabs. Developers who work from the command line face friction with this layout: logs lose column width, tabs crowd the display, and context shifts away from the shell.

VeriTTY assigns the main window to the terminal multiplexer. File editors, diff viewers, and previews open as detached native OS windows. Your desktop window manager controls their placement, sizing, and workspaces. Tool drawers for the file tree, git status, and diagnostics slide over the terminal on demand and dismiss when you resume typing in the shell.

---

## Architecture

```
                                 ┌──────────────────────────────────────────┐
                                 │       VeriTTY Cockpit (Main Window)      │
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

## Features

### Terminal Grid as Primary Canvas
The main window renders a terminal grid powered by `xterm.js` and local pseudoterminals. It supports splits, tabs, and OSC escape sequences. Input goes to the shell prompt without passing through editor focus layers.

### Detached Auxiliary Windows for Files
Opening a file or jumping to a definition launches a native OS auxiliary window.
* Tile editor windows with i3, Sway, Hyprland, bspwm, or macOS managers.
* Keep the terminal on one monitor and place editor windows on another.

### Dynamic Overlay Drawers
File trees, git panels, and diagnostics render as sliding overlays rather than fixed columns.
* Hotkeys (`Ctrl+B`, `Ctrl+Shift+G`) open file navigation or staged changes.
* Escape or new keystrokes in the terminal dismiss the drawer. The terminal retains its column count without resize interruptions.

### Telemetry Removal
The build removes Microsoft Application Insights, crash report uploads, and experiment services. Extension queries route to Open VSX by default.

---

## Installation

Install the complete VeriTTY Cockpit application, CLI client, desktop launcher, and shell integrations:

```bash
curl -fsSL https://raw.githubusercontent.com/supersweet-dev/veritty/main/install.sh | bash
```

The installer places the Cockpit in `~/.local/share/veritty/`, creates `~/.local/bin/veritty` and `~/.local/bin/veritty-cockpit`, and registers `veritty.desktop` with your desktop application menu.

### Shell Integration

Add directory synchronization and aliases to your shell startup file:

```bash
# Bash (~/.bashrc) or Zsh (~/.zshrc)
source ~/.local/share/veritty/shell/veritty.sh

# Fish (~/.config/fish/config.fish)
source ~/.local/share/veritty/shell/veritty.fish
```

### Updates

Check for newer releases or upgrade your installation:

```bash
veritty update --check
veritty update
```

---

## Shell IPC

Control the running Cockpit instance over the domain socket:

```bash
# Launch the desktop Cockpit
veritty cockpit .

# Open a file at a specific line in a detached window
veritty open src/index.ts:42:10

# Open a diff between two files
veritty diff old.py new.py

# Toggle or inspect dynamic drawers
veritty drawer toggle git
veritty drawer peek diagnostics

# Pipe standard input into a temporary buffer
cat build.log | veritty scratch
```

---

## Build from Source

### Prerequisites
* Node.js 20 or higher
* npm 10 or higher
* Git, C/C++ compiler, Python 3
* Native libraries: `libkrb5-dev`, `libsecret-1-dev`, `libx11-dev`, `libxkbfile-dev`

### Package Standalone Cockpit Bundle
```bash
git clone https://github.com/supersweet-dev/veritty.git
cd veritty

# Run the desktop packager
./build/package-desktop.sh v1.1.0
```

The output tarball appears in `dist-assets/veritty-linux-x64-v1.1.0.tar.gz`.

---

## License

MIT License. See [LICENSE](file:///root/projects/veritty/LICENSE).
