# Data Migration

Legacy sources (expected)
- Map files and metadata.
- NPC and item lists.
- Spells, quests, and text content.
- Client sprites and audio.

Target formats
- JSON for gameplay data (maps, NPCs, items, spells, quests).
- Packed textures and audio in Godot for client assets.

Migration steps
1) Inventory and document each legacy file format.
2) Build a converter in `tools/` that outputs JSON.
3) Validate counts and references (items in NPC loot, quests, etc).
4) Load JSON into the server and verify in a test map.
5) Import art assets into Godot and map them by ID.
