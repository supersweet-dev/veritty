# VeriTTY Architecture Overview

VeriTTY is an open-source, AI-built fork of Code-OSS engineered specifically for developers who live in their terminal, use tiling window managers (or multi-monitor setups), and want full access to the VS Code language intelligence (LSP) and extension ecosystem without the traditional IDE GUI bloat.

---

## 1. High-Level System Architecture

VeriTTY divides the developer workspace into three distinct layers:

1. **The Cockpit (Primary Window)**
   * Houses the terminal multiplexer grid.
   * Renders the interactive terminal canvas using `xterm.js` with hardware acceleration (WebGL / WebGPU).
   * Manages local PTY lifecycles (`node-pty` / native OS pseudoterminals).
   * Hosts the dynamic drawer overlay system.

2. **The Satellites (Native Auxiliary Windows)**
   * Created via Electron's `BrowserWindow` API through Code-OSS's `IAuxiliaryWindowService`.
   * Houses editor groups, diff viewers, markdown/SVG/image previews, and custom webviews.
   * Completely decoupled from the primary terminal window layout, allowing window managers (i3, Sway, Hyprland, yabai, Windows FancyZones) to manage their position, floating/tiled state, and workspaces.

3. **The Communication Fabric (IPC & Escape Sequences)**
   * **Domain Sockets / Named Pipes**: High-speed bidirectional communication between external shell processes and the VeriTTY main/workbench process.
   * **OSC (Operating System Command) Escape Sequences**: Embedded in the PTY stream (e.g., OSC 133 / OSC 633 / OSC 1337) to synchronize current working directory, command boundaries, and tool triggers with zero latency.

---

## 2. Core Differences from Stock VS Code

| Feature | Stock VS Code / Code-OSS | VeriTTY |
| :--- | :--- | :--- |
| **Primary Canvas** | Editor Part (Tabbed code editors) | Terminal Part (PTY Multiplexer Canvas) |
| **Editor Opening Behavior** | Opens as a tab in central grid | Spawns a detached native OS auxiliary window |
| **Sidebars & Panels** | Static docked layout columns (300px+) | Dynamic slide-out / floating overlay drawers |
| **Shell Integration** | Embedded terminal with manual controls | Bi-directional CLI tool (`veritty`) + IPC control |
| **Telemetry & Trackers** | Microsoft Application Insights, crash logs | Completely excised / stripped |
| **Window Management** | Monolithic single-window container | Multi-window satellite model |

---

## 3. Directory Layout in Repository

```
veritty/
├── build/                 # Build harness, upstream fetcher, patch runner
│   ├── apply-patches.sh
│   ├── fetch-base.sh
│   └── build.sh
├── cli/                   # 'veritty' CLI binary (IPC client & shell hooks)
│   ├── src/
│   │   ├── client.ts      # Unix socket client
│   │   ├── commands/      # open, diff, drawer, scratch
│   │   └── index.ts
│   ├── package.json
│   └── tsconfig.json
├── docs/                  # Architecture & engineering documentation
│   └── architecture/
│       ├── overview.md
│       ├── ipc-protocol.md
│       ├── workbench-inversion.md
│       └── dynamic-drawers.md
├── patches/               # Modular Git patches applied to Code-OSS
│   ├── 01-debloat/        # Telemetry & tracker removal
│   ├── 02-workbench/      # Terminal root canvas & layout inversion
│   ├── 03-auxiliary/      # Default auxiliary window editor routing
│   └── 04-drawers/        # Dynamic drawer overlay system
├── README.md              # Project Manifesto & Overview
├── ROADMAP.md             # Development Roadmap & Milestones
└── LICENSE                # MIT License
```
