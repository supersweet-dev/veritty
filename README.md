<p align="center">
  <h1 align="center">VeriTTY</h1>
  <p align="center"><strong>The Terminal-First, Bloat-Free Code-OSS Fork.</strong></p>
  <p align="center">
    <em>Open Source • AI-Architected • Tiling-WM & Multi-Monitor Friendly</em>
  </p>
  <p align="center">
    <a href="#philosophy">Philosophy</a> •
    <a href="#architecture">Architecture</a> •
    <a href="#key-features">Key Features</a> •
    <a href="#cli--ipc">CLI & IPC</a> •
    <a href="#roadmap">Roadmap</a> •
    <a href="#building-from-source">Building</a> •
    <a href="#contributing">Contributing</a>
  </p>
</p>

---

## 💡 Philosophy

Modern IDEs treat the terminal as a second-class citizen—a cramped 300px panel squeezed into the bottom of an editor grid. Meanwhile, terminal multiplexers (tmux, zellij) lack the rich Language Server Protocol (LSP), debugging (DAP), and extension ecosystems of modern code editors.

**VeriTTY inverts the paradigm:**
> **Your terminal is the cockpit. Everything else is a satellite.**

* The **main window** is a high-performance terminal multiplexer canvas.
* **Code editors, diff viewers, and previews** launch as detached, native OS auxiliary windows.
* **Sidebars and tool panels** become dynamic, auto-collapsing drawers that peek in only when needed and vanish when focus returns to your shell.
* Built entirely on an **open-source, debloated Code-OSS core**, stripping telemetry, heavy background daemons, and tracking bloat.
* **AI-Architected & Built**: Designed from scratch through collaborative AI agentic pairing, maintaining clean modularity and verifiable patches against upstream.

---

## 🏛️ Architecture

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

## ✨ Key Features

### 1. 🖥️ Terminal-First Cockpit
The primary canvas is your terminal grid. Powered by hardware-accelerated PTY rendering, splits, tabs, and full shell integrations. Focus defaults to the command line, where power users live.

### 2. 🪟 Detached Native Sub-Windows
Opening a file or preview does not hijack your terminal view. VeriTTY dispatches editors to native OS auxiliary windows:
* Native integration with tiling window managers (**i3, Sway, yabai, AeroSpace, Hyprland, bspwm**).
* Effortless multi-monitor setups (e.g., Terminal cockpit on primary monitor, code editors snapped across secondary monitors).
* Instant dismissal: close or save an editor to return seamless control to your shell session.

### 3. 🗄️ Dynamized Drawers
Static 300px side panels are gone. Drawers for **File Explorer**, **Source Control (Git)**, **Search**, and **Diagnostics**:
* Float or slide into view via hotkeys or CLI signals.
* Context-reactive: peek open automatically on build errors or git status changes.
* Automatically dismiss when you click or type back into the terminal.

### 4. 🧼 Zero Telemetry & Stripped Bloat
Derived from a debloated Code-OSS base:
* Stripped of Microsoft telemetry, background analytics, crash uploaders, and marketing payloads.
* Minimalist memory footprint and blazing startup performance compared to stock VS Code.
* Compatible with Open VSX and the standard VS Code extension ecosystem.

### 5. ⚡ Bi-directional CLI & Shell IPC
Control your IDE straight from your prompt:
```bash
# Open a file in a detached native editor window at a specific line
veritty open src/index.ts:42:10

# Open a 3-way or 2-way diff in a floating window
veritty diff old.py new.py

# Programmatically toggle or peek dynamic drawers
veritty drawer toggle git
veritty drawer peek diagnostics

# Pipe stdout directly into a detached scratchpad editor
cat build.log | veritty scratch
```

---

## 🤖 AI-Built & Open Source

VeriTTY is developed transparently as an open-source project architected and built in collaboration with autonomous AI agents. 

* **Clean Patch Separation**: All modifications to upstream Code-OSS are maintained as isolated, auditable git patches in [`patches/`](file:///root/projects/veritty/patches).
* **Modular CLI Tooling**: The CLI and IPC daemon layer live independently in [`cli/`](file:///root/projects/veritty/cli).
* **Automated Sync Harness**: Automated tooling tracks upstream Code-OSS releases, validates patches, and verifies builds.

---

## 🗺️ Roadmap

See [ROADMAP.md](file:///root/projects/veritty/ROADMAP.md) for detailed milestone tracking, technical specifications, and development phases.

| Phase | Milestone | Status |
| :--- | :--- | :--- |
| **0** | Architecture Specification & IPC Protocol Design | 🟢 In Progress |
| **1** | Debloated Code-OSS Upstream Harness & Patch Engine | 🟡 Up Next |
| **2** | Workbench Inversion (Terminal as Root, Native Aux Windows) | ⚪ Planned |
| **3** | Dynamic Drawer Overlay & Context Engine | ⚪ Planned |
| **4** | `veritty` CLI Tool & Shell Hook Integrations | ⚪ Planned |
| **5** | Cross-Platform Bundling (Linux, macOS, Windows) | ⚪ Planned |

---

## 🛠️ Building from Source

### Prerequisites
* **Node.js** >= 20.x
* **npm** >= 10.x
* **Git**
* Standard build essentials for native Node modules (Python 3, C/C++ compiler)

### Setup
```bash
# Clone the repository
git clone https://github.com/veritty-org/veritty.git
cd veritty

# Install CLI dependencies
cd cli && npm install && npm run build
cd ..

# Fetch upstream base and apply VeriTTY patches
./build/fetch-base.sh
./build/apply-patches.sh

# Build VeriTTY
./build/build.sh
```

---

## 📄 License

VeriTTY is licensed under the [MIT License](file:///root/projects/veritty/LICENSE).
