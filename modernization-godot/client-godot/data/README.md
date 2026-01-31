# Map Viewer Data

Copy converted data into this folder so Godot can load it:

1) Run the converter from the repo root:
   python modernization-godot/tools/convert_legacy_data.py --maps --client

2) Copy:
   modernization-godot/data/maps/Map1.json -> modernization-godot/client-godot/data/maps/Map1.json
   modernization-godot/data/client/grh_data.json -> modernization-godot/client-godot/data/client/grh_data.json

3) Stage GRH sprite sheets (optional, for real textures):
   python modernization-godot/tools/stage_grh_assets.py --convert

   This converts legacy BMPs (RLE8) to PNG for better compatibility.
   If you don't convert, set `asset_root` in the MapViewer to the absolute path of GameData/Grh.

4) Convert music (optional, for Godot playback):
   python modernization-godot/tools/convert_music.py

5) Open the Godot project and run.

Controls
- Arrow keys to pan.
- Press R to toggle the rain layer (layer 3).

Notes
- The current viewer renders colored tiles for each GRH index.
- Once sprite sheets are available, we can swap placeholder colors for real textures.
