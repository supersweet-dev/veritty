# Dynamic Drawer Overlay System

This document specifies the behavior, styling, and event lifecycle of the **Dynamic Drawer System** in VeriTTY.

---

## 1. Problem with Static IDE Panels

Traditional IDE panels consume between 250px and 450px of horizontal or vertical screen space permanently. In a terminal-first workflow, horizontal terminal width (columns) is critical for CLI output formatting, logs, and side-by-side terminal splits.

---

## 2. Dynamic Drawer Concept

Drawers in VeriTTY are:
1. **Zero Base Width**: They consume 0 columns of terminal space when closed.
2. **Floating Overlays**: When summoned, they slide out over the terminal canvas with backdrop blur and drop shadows, rather than reflowing or resizing the terminal's column grid.
3. **Transient by Default**: Clicking back into the terminal, executing a command, or pressing `<Esc>` slides the drawer closed instantly.
4. **Context-Reactive**: They can "peek" programmatically when external events warrant attention (e.g., test failure diagnostics, git merge conflicts).

```
┌──────────────────────────────────────────────┐
│ VeriTTY Cockpit (Terminal Canvas)            │
│ $ cargo test                                 │
│ ┌──────────────────────┐                     │
│ │ File Explorer Drawer │                     │
│ │ 📁 src/              │                     │
│ │   📄 main.rs         │                     │
│ │   📄 lib.rs          │  (Auto-dismisses    │
│ │ 📁 tests/            │   on terminal key)  │
│ └──────────────────────┘                     │
│ running 4 tests ... ok                       │
└──────────────────────────────────────────────┘
```

---

## 3. Registered Drawers

| Drawer ID | Default Hotkey | Contents | Auto-Dismiss |
| :--- | :--- | :--- | :--- |
| `explorer` | `Ctrl+B` / `Cmd+B` | File Tree, Open Files, Outline | Yes (on terminal keypress or click) |
| `git` | `Ctrl+Shift+G` | Source Control, Staged Changes, Commits | Yes |
| `search` | `Ctrl+Shift+F` | Global Search & Replace | Yes |
| `diagnostics` | `Ctrl+Shift+M` | Problems, LSP errors, Warnings | Yes (supports peek timeout) |

---

## 4. Lifecycle & Event Handling

### A. Open Trigger
* User presses drawer hotkey (`Ctrl+B`).
* Or external script calls `veritty drawer open explorer`.
* CSS class `.veritty-drawer-active` applied; drawer translates smoothly into viewport (`transition: transform 150ms cubic-bezier(0.16, 1, 0.3, 1)`).

### B. Auto-Dismiss Listeners
* `xterm.onKey()`: Any keystroke destined for the active shell triggers `.veritty-drawer-dismiss`.
* Click outside drawer bounds triggers dismiss.
* `<Esc>` explicitly cancels drawer.
* Terminal columns remain 100% stable—no SIGWINCH / resize signals sent to the shell process during drawer peek.

### C. Peek Mode
* Called via `veritty drawer peek <drawer> [--duration=3000]` or via internal diagnostics watcher.
* Drawer slides open for specified duration and smoothly recedes without stealing shell focus.
