# Architecture Overview

VeriTTY modifies Code-OSS to run the terminal multiplexer in the main application window and dispatch file editors into detached desktop windows.

---

## Workspace Structure

The system separates functionality into three layers:

1. **Main Window (Terminal Multiplexer)**
   * Hosts the terminal canvas using `xterm.js` and local pseudoterminals.
   * Manages tabs, splits, and shell connections.
   * Renders overlay drawers for the file tree, git status, and diagnostics.

2. **Detached Windows (Editor and Preview)**
   * Uses Electron `BrowserWindow` instances via `IAuxiliaryWindowService`.
   * Displays text editor groups, diff views, and previews.
   * Hands window placement and tiling to the desktop window manager (i3, Sway, Hyprland, yabai).

3. **IPC and Escape Sequences**
   * Domain sockets transfer commands between the `veritty` CLI and the main application.
   * OSC escape sequences (OSC 7, OSC 133, OSC 1337) communicate working directories and command states through the terminal stream.

---

## Comparison with Stock Code-OSS

| Feature | Stock Code-OSS | VeriTTY |
| :--- | :--- | :--- |
| **Main Window Center** | Editor tabs | Terminal multiplexer canvas |
| **Editor Launch** | Opens tab in main window grid | Opens detached native OS window |
| **Sidebars and Panels** | Docked layout columns (fixed width) | Sliding overlay drawers |
| **CLI Integration** | Command palette launcher | Bidirectional socket client (`veritty`) |
| **Telemetry** | Application Insights and crash logs | Disabled and removed |
| **Window Layout** | Single container window | Multi-window satellite model |

---

## Directory Organization

```
veritty/
├── build/                 # Upstream fetcher, patch runner, build scripts
├── cli/                   # veritty CLI client
├── docs/                  # Architecture specifications
├── patches/               # Git patches applied to Code-OSS
│   ├── 01-debloat/        # Telemetry removal and Open VSX configuration
│   ├── 02-workbench/      # Terminal root canvas layout
│   ├── 03-auxiliary/      # Auxiliary window routing for editors
│   └── 04-drawers/        # Dynamic drawer overlay system
├── README.md              # Project overview and build instructions
├── ROADMAP.md             # Development milestones
└── LICENSE                # MIT License
```
