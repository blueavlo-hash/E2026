# Tools

This folder contains utilities for:
- Parsing legacy VB6 data files.
- Converting to JSON.
- Validating references and IDs.

Usage
```
python modernization-godot/tools/convert_legacy_data.py
```

Output
- `modernization-godot/data/legacy-json/` for INI-style files.
- `modernization-godot/data/maps/` for per-map JSON with parsed tile layers.
- `modernization-godot/data/client/` for client graphics data and indices.
- `modernization-godot/data/text/` for readmes, notes, and version files.

Notes
- `.map` is parsed into `blocked` + 3 `graphics` layers.
- `.inf` and `.obj` are parsed using VB6 field sizes; `reserved` captures unused fields.
- Run with `--validate` to emit warnings about map layer sizes or strides.
