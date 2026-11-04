# IPC Protocol Specification

This document defines the socket protocol and message formats used between the `veritty` CLI and the running VeriTTY instance.

---

## Transport

* **Linux and macOS**: Unix domain socket at `$XDG_RUNTIME_DIR/veritty/veritty-$UID.sock` (fallback: `/tmp/veritty-$UID/veritty.sock`).
* **Windows**: Named pipe at `\\.\pipe\veritty-$USERNAME`.
* **Framing**: Newline-delimited JSON-RPC 2.0.

---

## Message Format

Requests:
```json
{
  "jsonrpc": "2.0",
  "id": "req-1",
  "method": "<method_name>",
  "params": { ... }
}
```

Responses:
```json
{
  "jsonrpc": "2.0",
  "id": "req-1",
  "result": { ... },
  "error": null
}
```

---

## Methods

### `editor.open`
Opens a file in a detached native OS auxiliary window.

**Parameters:**
* `path` (string, required): Filesystem path.
* `line` (number, optional): Target line number (1-indexed).
* `column` (number, optional): Target column number (1-indexed).
* `preview` (boolean, optional): Open in preview mode (default: `false`).
* `reUseWindow` (boolean, optional): Reuse an existing detached window (default: `false`).

**Request Example:**
```json
{
  "jsonrpc": "2.0",
  "id": "1",
  "method": "editor.open",
  "params": {
    "path": "/home/dev/projects/app/src/index.ts",
    "line": 42,
    "column": 10,
    "reUseWindow": false
  }
}
```

**Response Example:**
```json
{
  "jsonrpc": "2.0",
  "id": "1",
  "result": {
    "windowId": 2,
    "status": "opened"
  }
}
```

---

### `editor.diff`
Opens a detached diff window comparing two files.

**Parameters:**
* `originalPath` (string, required): Baseline file path.
* `modifiedPath` (string, required): Target file path.
* `title` (string, optional): Title for the window titlebar.

**Request Example:**
```json
{
  "jsonrpc": "2.0",
  "id": "2",
  "method": "editor.diff",
  "params": {
    "originalPath": "/tmp/base-config.json",
    "modifiedPath": "/home/dev/projects/app/config.json",
    "title": "config.json (Base vs Current)"
  }
}
```

---

### `drawer.toggle` / `drawer.open` / `drawer.close` / `drawer.peek`
Controls overlay drawers in the main window.

**Parameters:**
* `drawer` (string, required): One of `"explorer"`, `"git"`, `"search"`, `"diagnostics"`, `"extensions"`.
* `durationMs` (number, optional): Duration in milliseconds before dismissal when using `drawer.peek` (default: `3000`).

**Request Example:**
```json
{
  "jsonrpc": "2.0",
  "id": "3",
  "method": "drawer.peek",
  "params": {
    "drawer": "diagnostics",
    "durationMs": 4000
  }
}
```

---

### `editor.scratch`
Opens a detached buffer containing text passed via standard input.

**Parameters:**
* `content` (string, required): Buffer contents.
* `language` (string, optional): Syntax highlighting mode (e.g. `"json"`, `"markdown"`, `"diff"`).

---

## Terminal Escape Sequences

The terminal parser inspects these escape sequences in the PTY output stream:

| Sequence | Purpose | Syntax |
| :--- | :--- | :--- |
| **OSC 133** | Semantic shell markers | `\x1b]133;A\x07` (prompt start), `\x1b]133;C\x07` (command run), `\x1b]133;D;<code\x07` (exit status) |
| **OSC 7** | Working directory reporting | `\x1b]7;file://<host>/<path>\x07` |
| **OSC 1337** | Drawer and window triggers | `\x1b]1337;VeriTTY=open:<path>\x07` |
