# Architecture

High level
- Client: Godot 4 2D, rendering and input only.
- Server: .NET 8 headless simulation and networking.
- Data: content authored in legacy files, converted into new formats.

Networking
- Authoritative server with a fixed tick rate.
- Client sends intent (movement, interaction).
- Server broadcasts state snapshots and events.

Simulation
- Deterministic update loop for movement and combat.
- Map boundaries and collision server-side.

Persistence
- Start with JSON or SQLite for rapid iteration.
- Migrate to a production database later if needed.

Safety
- Validate all client inputs.
- Rate limit chat and actions.
