# VeriTTY IPC Protocol Specification

The VeriTTY IPC protocol enables bidirectional communication between the shell environment, external CLI invocations (`veritty`), and the running VeriTTY Cockpit instance.

---

## 1. Transport Layer

* **Unix / Linux / macOS**: Unix domain socket at:
  ```
  $XDG_RUNTIME_DIR/veritty/veritty-$UID.sock
  # Fallback: /tmp/veritty-$UID/veritty.sock
  ```
* **Windows**: Named Pipe at:
  ```
  \\.\pipe\veritty-$USERNAME
  ```
* **Framing**: Newline-delimited JSON (NDJSON) or JSON-RPC 2.0.

---

## 2. Message Format

Every message sent across the socket conforms to standard JSON-RPC 2.0:

```json
{
  "jsonrpc": "2.0",
  "id": "req-1",
  "method": "<method_name>",
  "params": { ... }
}
```

Responses conform to:
```json
{
  "jsonrpc": "2.0",
  "id": "req-1",
  "result": { ... },
  "error": null
}
```

---

## 3. Supported Methods

### 3.1 `editor.open`
Spawns or focuses a detached native OS auxiliary window for a specified file.

**Parameters:**
* `path` (string, required): Absolute or relative filesystem path.
* `line` (number, optional): 1-indexed target line number.
* `column` (number, optional): 1-indexed target column number.
* `preview` (boolean, optional): Whether to open in preview mode (default: `false`).
* `reUseWindow` (boolean, optional): Whether to reuse an existing detached editor window if one is open.

**Example Request:**
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

**Example Response:**
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

### 3.2 `editor.diff`
Opens a detached native auxiliary window displaying a side-by-side or inline diff.

**Parameters:**
* `originalPath` (string, required): Original file path or git blob identifier.
* `modifiedPath` (string, required): Modified file path.
* `title` (string, optional): Display title in the auxiliary window titlebar.

**Example Request:**
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

### 3.3 `drawer.toggle` / `drawer.open` / `drawer.close` / `drawer.peek`
Controls the dynamic drawer overlay in the VeriTTY Cockpit.

**Parameters:**
* `drawer` (string, required): One of `"explorer"`, `"git"`, `"search"`, `"diagnostics"`, `"extensions"`.
* `durationMs` (number, optional): For `drawer.peek`, duration in milliseconds before auto-dismissing (default: `3000`).

**Example Request:**
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

### 3.4 `editor.scratch`
Creates a temporary scratchpad buffer populated with content from standard input (stdin).

**Parameters:**
* `content` (string, required): Buffer content.
* `language` (string, optional): Language identifier for syntax highlighting (e.g., `"json"`, `"markdown"`, `"log"`).

---

## 4. In-Band OSC Escape Sequences

In addition to socket-based IPC, the active terminal multiplexer listens for custom and standard OSC (Operating System Command) sequences embedded in the PTY output stream:

| Sequence | Purpose | Syntax |
| :--- | :--- | :--- |
| **OSC 133** | Semantic Shell Integration | `\x1b]133;A\x07` (Prompt start), `\x1b]133;C\x07` (Command executed), `\x1b]133;D;<exit_code>\x07` (Exit code) |
| **OSC 7** | Working Directory Synchronization | `\x1b]7;file://<hostname>/<path>\x07` |
| **OSC 1337 (VeriTTY Extension)** | Dynamic Drawer & Sub-window triggers | `\x1b]1337;VeriTTY=open:<path>\x07` |
