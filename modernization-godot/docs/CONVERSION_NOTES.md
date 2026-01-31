# Conversion Notes

Map formats (legacy VB6)
- `.map`: per-tile data. Layout is `Blocked (Byte)` + 3 graphics indices (`Integer`), repeated for each tile.
- `.inf`: per-tile exits and NPC references. Layout is `TileExit.map`, `TileExit.X`, `TileExit.Y`, `NpcIndex`, plus 2 reserved Integers.
- `.obj`: per-tile object data. Layout is `ObjIndex (Integer)`, `Amount (Integer)`, `Locked (Long)`, `Sign (Integer)`, `SignOwner (Long)`.

Converter behavior
- Uses map dimensions from legacy constants (100x100) but will infer square maps if size doesn't match.
- Stores parsed tile arrays and retains inferred stride and size in the JSON `raw` block.
- Uses `--validate` to warn about unexpected sizes or strides.

Client graphics formats
- `Grh.dat`: binary table of graphics entries. Each entry is either a single-frame sprite sheet region or an animation sequence.
- `Grh.ini`: path and count metadata for graphics.
- `Body.dat`, `Head.dat`, `wpanim.dat`, `shanim.dat`: INI-style lists that map body/head/weapon/shield IDs to GRH indices.
