# Roadmap

Phase 0: Scaffold (this commit)
- Create new folders for client, server, and tools.
- Define architecture and data migration outline.

Phase 1: Data audit and conversion
- Document legacy data formats (maps, NPCs, items, spells, quests).
- Build converter tools to normalized JSON or binary assets.
- Validate data integrity and load into new runtime.

Phase 2: Core server loop
- Entity and world simulation loop.
- Basic networking: login, movement, chat, map transfer.
- Persistence: player accounts and characters.

Phase 3: Client playable slice
- Map render + camera.
- Character sprite, movement, and chat UI.
- Connect to server and load a single map.

Phase 4: Content systems
- Inventory, items, and equipment.
- NPC AI and combat.
- Skills, spells, quests.

Phase 5: Production hardening
- Logging, metrics, and admin tooling.
- Patching pipeline and content build.
- Load testing and security audit.
