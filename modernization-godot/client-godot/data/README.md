# Map Viewer Data

Copy converted data into this folder so Godot can load it:

1) Run the converter from the repo root:
   python modernization-godot/tools/convert_legacy_data.py --maps --client

2) Copy:
   modernization-godot/data/maps/Map1.json -> modernization-godot/client-godot/data/maps/Map1.json
   modernization-godot/data/client/grh_data.json -> modernization-godot/client-godot/data/client/grh_data.json

3) Open the Godot project and run.

Notes
- The current viewer renders colored tiles for each GRH index.
- Once sprite sheets are available, we can swap placeholder colors for real textures.
