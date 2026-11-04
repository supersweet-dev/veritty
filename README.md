<p align="center">
  <h1 align="center">VeriTTY</h1>
  <p align="center">A terminal-first Code-OSS fork for tiling window managers and multi-monitor setups.</p>
  <p align="center">
    <a href="#design">Design</a> |
    <a href="#architecture">Architecture</a> |
    <a href="#features">Features</a> |
    <a href="#shell-ipc">Shell IPC</a> |
    <a href="#roadmap">Roadmap</a> |
    <a href="#build">Build</a> |
    <a href="#license">License</a>
  </p>
</p>

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
* You can tile editor windows with i3, Sway, Hyprland, or yabai.
* You can keep the terminal on one monitor and place editor windows on another.

### Overlay Drawers
File trees, git panels, and diagnostics render as sliding overlays rather than fixed columns.
* Hotkeys (`Ctrl+B`, `Ctrl+Shift+G`) open file navigation or staged changes.
* Escape or new keystrokes in the terminal dismiss the drawer. The terminal retains its column count without resize interruptions.

### Telemetry Removal
The build removes Microsoft Application Insights, crash report uploads, and experiment services. Extension queries route to Open VSX by default.

---

## Shell IPC

A command-line client controls the running instance over a local domain socket:
```bash
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

## Codebase Structure

The project maintains modifications to upstream Code-OSS as isolated git patches:
* Patches sit in `patches/` and apply against pinned release tags.
* The CLI client lives in `cli/`.
* Shell integration hooks live in `shell/`.

---

## Roadmap

Track implementation progress in [ROADMAP.md](file:///root/projects/veritty/ROADMAP.md).

| Phase | Milestone | Status |
| :--- | :--- | :--- |
| 0 | Architecture & IPC Protocol Specification | Completed |
| 1 | Upstream Base Harness & Patch Management | Completed |
| 2 | Workbench Inversion & Auxiliary Window Routing | In Progress |
| 3 | Dynamic Drawer Overlays | Planned |
| 4 | CLI Client & Shell Hooks | Planned |
| 5 | Packaging | Planned |

---

## Build

### Prerequisites
* Node.js 20 or higher
* npm 10 or higher
* Git
* C/C++ compiler and Python 3 (for native modules)

### Instructions
```bash
git clone https://github.com/supersweet-dev/veritty.git
cd veritty

# Build the CLI
cd cli && npm install && npm run build
cd ..

# Fetch upstream base and apply patches
./build/fetch-base.sh
./build/apply-patches.sh

# Compile
./build/build.sh
```

---

## License

MIT License. See [LICENSE](file:///root/projects/veritty/LICENSE).
