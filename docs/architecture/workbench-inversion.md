# Workbench Inversion: Terminal as Root Canvas

This document details the modifications that place the terminal multiplexer in the main window and route file editors to detached desktop windows.

---

## Upstream Layout Hierarchy

In standard Code-OSS (`src/vs/workbench/browser/layout.ts`):
* The layout grid anchors around `EditorPart`.
* `SidebarPart`, `AuxiliaryBarPart`, and `PanelPart` dock around the central editor area.
* `IEditorService.openEditor()` resolves an `IEditorGroup` in the central editor grid and renders the buffer in the main window.

---

## Inverted Layout

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

## Implementation Details

### Routing `IEditorService.openEditor` to Auxiliary Windows
In `src/vs/workbench/services/editor/common/editorGroupFinder.ts`:
1. Check candidate group locations.
2. If the resolved group belongs to the main window (`mainPart`), redirect to an active auxiliary editor part or invoke `editorGroupService.createAuxiliaryEditorPart()`.
3. Wrap the editor group inside the native OS `BrowserWindow`.
4. When you save and close the editor window (`Ctrl+W`), focus returns to the shell.

### Main Window Layout Keys
In `src/vs/workbench/browser/layout.ts`:
1. Set `PANEL_HIDDEN` to `false` by default.
2. Set `EDITOR_HIDDEN` to `true` by default in the main window.
3. Register `TERMINAL_VIEW_ID` with `order: 0` in `terminal.contribution.ts` so the terminal initializes as the primary panel view on boot.

### Window Manager Integration
For auxiliary windows, configure Electron window properties:
* `hasShadow: true`
* `frame: true` (or frameless mode for tiling window managers)
* `titleBarStyle: 'hiddenInset'` on macOS or native borders on Linux and Windows
* Set `wmClass` and `appId` to `veritty-editor` for window rules:
  ```
  # Example i3 / sway rule:
  for_window [app_id="veritty-editor"] floating enable, resize set 900 700
  ```
