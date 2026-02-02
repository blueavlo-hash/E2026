# Legacy Map Viewer (PySide6)

Standalone viewer for legacy Era Online map files. Reads original `.map/.inf/.obj` and `Grh.dat`/`Grh` BMPs directly.

## Run

```
python legacy_editor.py
```

## Controls

- Mouse wheel: zoom
- Middle/right mouse drag: pan
- Toolbar toggles: layer 1/2/3, blocked, exits

## Notes

- Uses tile size 50 (matches the original VB6 editor constants).
- If a `grh###M.bmp` mask exists, it is used for alpha.
- Otherwise a simple color key is applied (top-left pixel).

## Paths

The viewer auto-detects repo root based on script location. You can override paths at the top of `legacy_editor.py`.
