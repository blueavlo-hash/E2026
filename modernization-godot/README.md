# Modernization Scaffold (Godot 4 + .NET 8)

This folder contains a clean rewrite scaffold for a 2D MMO using a modern engine and a separate server.

Goals
- Full rewrite with modern tooling and clear separation of client and server.
- Windows-only for now, but architecture should stay portable.
- Preserve legacy content by migrating data files into new formats.

Layout
- docs: roadmap, architecture, migration notes, and protocol outline.
- client-godot: Godot 4 2D client scaffold.
- server-dotnet: .NET 8 headless server scaffold.
- tools: placeholder for data conversion and validation utilities.

Getting started
1) Open `modernization-godot/client-godot` in Godot 4.x.
2) Build and run the server from `modernization-godot/server-dotnet`.

Notes
- This is intentionally minimal and safe. It is a foundation you can extend.
- Legacy assets and data are not yet imported; see docs for the migration plan.
