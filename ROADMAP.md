# VeriTTY Roadmap & Milestones

This document outlines the milestones and implementation phases for VeriTTY.

---

## Target State

VeriTTY configures a terminal-first workspace:
1. **Primary Window**: A terminal multiplexer (`xterm.js` and PTY) occupies the main window.
2. **Auxiliary Windows**: File edits, diffs, and previews open in detached native OS windows (`BrowserWindow` through `IAuxiliaryWindowService`).
3. **Dynamic Drawers**: File trees, git views, and diagnostics slide in as overlays and dismiss when input returns to the shell.
4. **Shell IPC**: A CLI client (`veritty`) controls windows and drawers through a local domain socket.
5. **Debloated Core**: Zero telemetry, no proprietary services, and minimal background memory overhead.
6. **All-in-One Distribution**: A complete standalone desktop Cockpit application bundled with the CLI, companion extension, and shell integrations.

---

## Milestones

| Phase | Milestone | Status |
| :--- | :--- | :--- |
| 0 | Architecture & IPC Protocol Specification | Completed |
| 1 | Upstream Base Harness & Patch Management | Completed |
| 2 | Workbench Inversion & Auxiliary Window Routing | Completed |
| 3 | Dynamic Drawer Overlays | Completed |
| 4 | CLI Client & Shell Hooks | Completed |
| 5 | All-in-One Desktop Cockpit & Packaging | Completed |

---

### Phase 0: Architecture & IPC Protocol Specification (Completed)
- [x] Repository initialization with MIT license.
- [x] Project manifesto and design specification in [`README.md`](file:///root/projects/veritty/README.md).
- [x] Socket protocol and message specification in [`docs/architecture/ipc-protocol.md`](file:///root/projects/veritty/docs/architecture/ipc-protocol.md).
- [x] Layout inversion specification in [`docs/architecture/workbench-inversion.md`](file:///root/projects/veritty/docs/architecture/workbench-inversion.md).
- [x] Dynamic drawer specification in [`docs/architecture/dynamic-drawers.md`](file:///root/projects/veritty/docs/architecture/dynamic-drawers.md).

---

### Phase 1: Upstream Base & Patch Engine (Completed)
- [x] Upstream fetch script pinning Code-OSS 1.96.4 in [`build/fetch-base.sh`](file:///root/projects/veritty/build/fetch-base.sh).
- [x] Telemetry removal and Open VSX marketplace configuration in [`patches/01-debloat/001-product-and-telemetry.patch`](file:///root/projects/veritty/patches/01-debloat/001-product-and-telemetry.patch).
- [x] Patch applicator script in [`build/apply-patches.sh`](file:///root/projects/veritty/build/apply-patches.sh).
- [x] Patch export script in [`build/generate-patches.sh`](file:///root/projects/veritty/build/generate-patches.sh).
- [x] CI verification on GitHub Actions.

---

### Phase 2: Workbench Layout Inversion (Completed)
- [x] Invert main layout keys: `PANEL_HIDDEN: false` and `EDITOR_HIDDEN: true` in [`patches/02-workbench/001-terminal-root-canvas.patch`](file:///root/projects/veritty/patches/02-workbench/001-terminal-root-canvas.patch).
- [x] Register terminal container as default view (order 0).
- [x] Route main window editor open requests to `createAuxiliaryEditorPart()` in [`patches/03-auxiliary/001-route-editors-to-aux-windows.patch`](file:///root/projects/veritty/patches/03-auxiliary/001-route-editors-to-aux-windows.patch).
- [x] Configure window manager hints (`title: "VeriTTY Editor"`) for desktop window tiling rules.
- [x] Persist open auxiliary window geometry and editor groups across restarts.

---

### Phase 3: Dynamic Drawer Overlay System (Completed)
- [x] Render `SidebarPart` with floating overlay shadows and border isolation in [`patches/04-drawers/001-dynamic-overlay-drawers.patch`](file:///root/projects/veritty/patches/04-drawers/001-dynamic-overlay-drawers.patch).
- [x] Auto-dismiss sidebar and auxiliary drawers on terminal keystroke input in [`patches/04-drawers/001-dynamic-overlay-drawers.patch`](file:///root/projects/veritty/patches/04-drawers/001-dynamic-overlay-drawers.patch).
- [x] Add peek timeouts for diagnostics drawers on build errors in [`extensions/veritty/`](file:///root/projects/veritty/extensions/veritty).

---

### Phase 4: CLI Client & Shell Integration (Completed)
- [x] Domain socket IPC client and parser in [`cli/`](file:///root/projects/veritty/cli).
- [x] Companion IPC server bridge in [`extensions/veritty/`](file:///root/projects/veritty/extensions/veritty).
- [x] Shell hooks for bash and zsh ([`shell/veritty.sh`](file:///root/projects/veritty/shell/veritty.sh)) and fish ([`shell/veritty.fish`](file:///root/projects/veritty/shell/veritty.fish)).
- [x] OSC 7 working directory sync functions and CLI aliases (`v`, `vdiff`, `vdrawer`, `vscratch`).
- [x] End-to-end socket integration test suite passing.

---

### Phase 5: All-in-One Desktop Cockpit & Packaging (Completed)
- [x] Standalone Cockpit desktop packager in [`build/package-desktop.sh`](file:///root/projects/veritty/build/package-desktop.sh).
- [x] Electron runtime integration and production dependency filtering.
- [x] Unified launcher binary (`bin/veritty`) supporting direct Cockpit launch and IPC commands.
- [x] Graphical Cockpit launcher (`bin/veritty-cockpit`) and desktop file (`share/applications/veritty.desktop`).
- [x] Self-updating installer in [`install.sh`](file:///root/projects/veritty/install.sh) deploying all-in-one desktop Cockpit.
- [x] GitHub Actions automated release pipeline publishing standalone Linux Cockpit packages.
