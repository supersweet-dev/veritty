# VeriTTY Patches

All modifications against upstream Code-OSS are organized here as isolated, auditable Git patches. This allows VeriTTY to cleanly rebase across newer upstream Code-OSS releases while maintaining a minimal and inspectable diff.

---

## Directory Organization

```
patches/
├── 01-debloat/
│   └── 001-remove-telemetry.patch
│       # Strips ApplicationInsights, crash reporters, experiment services
│
├── 02-workbench/
│   └── 001-terminal-root-canvas.patch
│       # Makes TerminalPart the primary unclosable workbench canvas
│
├── 03-auxiliary/
│   └── 001-route-editors-to-aux-windows.patch
│       # Directs IEditorService.openEditor() to IAuxiliaryWindowService
│
└── 04-drawers/
    └── 001-dynamic-overlay-drawers.patch
        # Converts sidebars/panels into floating, context-reactive drawers
```

---

## Managing Patches

* **Apply all patches to upstream tree**:
  ```bash
  ./build/apply-patches.sh
  ```

* **Generate new patches from changes in upstream tree**:
  ```bash
  ./build/generate-patches.sh <patch-category> <patch-name>
  ```
