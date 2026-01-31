# Protocol Outline

Transport
- TCP for reliable session traffic.
- Length-prefixed binary packets (versioned).

Core messages
- Client -> Server
  - Hello(version, build, auth)
  - Move(direction, targetTile)
  - Chat(channel, text)
  - Action(type, target)
- Server -> Client
  - Welcome(sessionId, worldInfo)
  - Snapshot(entities, time)
  - Event(type, payload)

Notes
- Keep payloads small and versioned.
- Consider adding a compression flag after alpha.
