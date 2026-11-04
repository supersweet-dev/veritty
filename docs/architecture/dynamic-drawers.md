# Dynamic Drawer Overlay System

This document specifies the behavior, styling, and event lifecycle of the drawer overlay system in VeriTTY.

---

## Panel Layout Constraints

Docked IDE panels consume between 250px and 450px of horizontal space. When running split terminals or reading command output, reduced column width truncates lines and triggers horizontal scrollbars.

---

## Drawer Design

Drawers in VeriTTY operate with these constraints:
1. **Zero Base Width**: Closed drawers occupy 0 columns of terminal space.
2. **Floating Overlays**: When summoned, drawers slide over the terminal canvas with drop shadows. They do not trigger window resize events or change terminal column dimensions.
3. **Transient State**: Clicking the terminal or pressing Escape closes the active drawer.
4. **Context Peeking**: External commands or diagnostics watchers can open a drawer for a set duration.

```
┌──────────────────────────────────────────────┐
│ VeriTTY Terminal Canvas                      │
│ $ cargo test                                 │
│ ┌──────────────────────┐                     │
│ │ File Explorer Drawer │                     │
│ │ 📁 src/              │                     │
│ │   📄 main.rs         │                     │
│ │   📄 lib.rs          │  (Closes on         │
│ │ 📁 tests/            │   terminal key)     │
│ └──────────────────────┘                     │
│ running 4 tests ... ok                       │
└──────────────────────────────────────────────┘
```

---

## Drawer Registry

| Drawer ID | Default Hotkey | Contents | Auto-Dismiss |
| :--- | :--- | :--- | :--- |
| `explorer` | `Ctrl+B` / `Cmd+B` | File tree and open buffers | Yes (on terminal keypress or click) |
| `git` | `Ctrl+Shift+G` | Source control and staged changes | Yes |
| `search` | `Ctrl+Shift+F` | Workspace search | Yes |
| `diagnostics` | `Ctrl+Shift+M` | Compiler errors and warnings | Yes (supports peek timeout) |

---

## Event Lifecycle

### Open Trigger
* You press the drawer shortcut (`Ctrl+B`).
* Or a script executes `veritty drawer open explorer`.
* CSS class `.veritty-drawer-active` translates the element into the viewport (`transition: transform 150ms cubic-bezier(0.16, 1, 0.3, 1)`).

### Dismiss Listeners
* `xterm.onKey()`: A keystroke sent to the active shell triggers `.veritty-drawer-dismiss`.
* Clicking outside drawer bounds triggers dismissal.
* Pressing Escape closes the drawer.
* The terminal grid does not emit SIGWINCH resize signals during drawer visibility.

### Peek Mode
* Triggered by `veritty drawer peek <drawer> [--duration=3000]` or build failure hooks.
* The drawer displays for the specified duration and closes without stealing shell focus.
