# Asset Inventory (GameData)

Overview
- `GameData/Grh/`: sprite sheets (`Grh*.bmp`, also lowercase variants).
- `GameData/Intro/`: splash/intro images (`.jpg`).
- `GameData/Music/`: music tracks (mostly `.mid`).
- `GameData/Sound/`: sound effects (`.wav`, some `.mp3`).
- `GameData/Maps/`: `.map` files only (visual layer); `.inf/.obj` live in `Server/Maps/`.

Notes
- The legacy client loads sprite sheets as `Grh{n}.bmp` based on `Grh.ini`.
- Godot can load `.bmp`, `.jpg`, `.png`, `.wav`, and `.mp3` directly; it does not natively play `.mid`.
- If we want music in the modern client, we should convert `.mid` to `.ogg` or `.wav`.

Tools
- `modernization-godot/tools/stage_grh_assets.py` copies and normalizes GRH names into the Godot project.
- `modernization-godot/tools/scan_game_assets.py` creates a JSON manifest for all GameData assets.
