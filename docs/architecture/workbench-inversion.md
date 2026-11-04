# Workbench Inversion: Terminal as Root Canvas

This document outlines the technical changes required to invert the Code-OSS workbench layout hierarchy, promoting the terminal to the primary canvas and routing editor instances to detached native auxiliary windows.

---

## 1. Upstream Code-OSS Layout Hierarchy

In upstream VS Code (`src/vs/workbench/browser/layout.ts`):
* The layout grid is rooted around the `EditorPart`.
* The `SidebarPart`, `AuxiliaryBarPart`, and `PanelPart` (which contains the terminal) are subordinate parts docked around the central editor area.
* Editors are opened via `IEditorService.openEditor()`, which resolves an `IEditorGroup` in the central `EditorPart` and renders the editor DOM within the main window.

---

## 2. The VeriTTY Inverted Hierarchy

In VeriTTY:
```
                      ┌─────────────────────────────────┐
                      │        Workbench Window         │
                      └────────────────┬────────────────┘
                                       │
                        ┌──────────────┴──────────────┐
                        ▼                             ▼
            ┌──────────────────────┐      ┌──────────────────────┐
            │     TerminalPart     │      │ Dynamic Drawer Layer │
            │   (Primary Canvas)   │      │ (Overlays & Peeks)   │
            └──────────────────────┘      └──────────────────────┘
                        │
                        ▼ (on file open request)
            ┌──────────────────────┐
            │ AuxiliaryWindowSvc   │
            └───────────┬──────────┘
                        │
       ┌────────────────┴────────────────┐
       ▼                                 ▼
┌──────────────┐                  ┌──────────────┐
│ Native Aux 1 │                  │ Native Aux 2 │
│  (Editor A)  │                  │  (Editor B)  │
└──────────────┘                  └──────────────┘
```

---

## 3. Implementation Blueprint

### A. Routing `IEditorService.openEditor` to Auxiliary Windows
In `src/vs/workbench/services/editor/browser/editorService.ts`:
1. Intercept `openEditor` invocations.
2. If `options.target` is not explicitly set to in-cockpit, delegate the creation to `IAuxiliaryWindowService.createAuxiliaryWindow()`.
3. Wrap the editor group inside the newly created native OS `BrowserWindow`.
4. Provide seamless focus transitions: the user can edit code, save (`Ctrl+S`), and when closing the window (`Ctrl+W`), focus cleanly returns to the terminal prompt that initiated the edit.

### B. Promoting `TerminalPart` to Master Grid Container
In `src/vs/workbench/browser/parts/workbench.ts`:
1. Register `TerminalPart` as the central non-collapsible component instead of `EditorPart`.
2. Configure `TerminalGroupService` and `TerminalService` to initialize immediately on startup without waiting for panel visibility toggles.
3. Automatically attach the active terminal to the default shell (or restored multiplexer session).

### C. Native Window Manager Hints
For auxiliary windows, configure Electron window options:
* `hasShadow: true`
* `frame: true` (or customizable frameless mode for tiling window managers)
* `titleBarStyle: 'hiddenInset'` (macOS) or native client decorations (Linux/Windows)
* Proper `wmClass` / `appId` (`veritty-editor`) allowing window managers to write rules:
  ```
  # Example i3 / sway rule:
  for_window [app_id="veritty-editor"] floating enable, resize set 900 700
  ```
