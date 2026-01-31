extends Node2D

@export var map_json_path: String = "res://data/maps/Map1.json"
@export var grh_json_path: String = "res://data/client/grh_data.json"
@export var asset_root: String = "res://assets/grh"
@export var tile_size: int = 32
@export var show_blocked_overlay: bool = true

var _map_data: Dictionary = {}
var _grh_data: Dictionary = {}
var _grh_entries: Dictionary = {}
var _texture_cache: Dictionary = {}
var _map_width: int = 0
var _map_height: int = 0
var _camera_tile: Vector2i = Vector2i(1, 1)
var _camera_speed: float = 10.0


func _ready() -> void:
	_load_data()
	queue_redraw()


func _process(delta: float) -> void:
	var move = Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT):
		move.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		move.x += 1.0
	if Input.is_key_pressed(KEY_UP):
		move.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN):
		move.y += 1.0

	if move != Vector2.ZERO:
		_camera_tile.x = clamp(
			int(_camera_tile.x + move.x * _camera_speed * delta),
			0,
			max(0, _map_width - 1)
		)
		_camera_tile.y = clamp(
			int(_camera_tile.y + move.y * _camera_speed * delta),
			0,
			max(0, _map_height - 1)
		)
		queue_redraw()


func _draw() -> void:
	if _map_data.is_empty():
		draw_string(get_theme_default_font(), Vector2(12, 24), "No map data loaded.")
		return

	var view_size = get_viewport_rect().size
	var tiles_x = int(view_size.x / float(tile_size)) + 2
	var tiles_y = int(view_size.y / float(tile_size)) + 2

	var start_x = clamp(_camera_tile.x - tiles_x / 2, 0, max(0, _map_width - tiles_x))
	var start_y = clamp(_camera_tile.y - tiles_y / 2, 0, max(0, _map_height - tiles_y))
	var end_x = min(_map_width, start_x + tiles_x)
	var end_y = min(_map_height, start_y + tiles_y)

	var layers = _map_data.get("layers", {})
	var map_layer = layers.get("map", {})
	var blocked = map_layer.get("blocked", [])
	var graphics_layers = map_layer.get("graphics", [])

	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			var screen_pos = Vector2((x - start_x) * tile_size, (y - start_y) * tile_size)

			for layer_index in range(3):
				var grh_index = _get_layer_value(graphics_layers, layer_index, x, y)
				if grh_index > 0:
					if not _draw_grh(grh_index, screen_pos):
						var color = _color_from_id(grh_index)
						draw_rect(Rect2(screen_pos, Vector2(tile_size, tile_size)), color)

			if show_blocked_overlay and _get_grid_value(blocked, x, y) == 1:
				draw_rect(
					Rect2(screen_pos, Vector2(tile_size, tile_size)),
					Color(1.0, 0.1, 0.1, 0.35),
					true
				)

	draw_string(
		get_theme_default_font(),
		Vector2(12, view_size.y - 12),
		"Map %s | Camera %d,%d" % [_map_data.get("id", "?"), _camera_tile.x, _camera_tile.y]
	)


func _load_data() -> void:
	_map_data = _load_json(map_json_path)
	_grh_data = _load_json(grh_json_path)

	if _map_data.is_empty():
		push_warning("Map data not found: %s" % map_json_path)
		return

	var map_layer = _map_data.get("layers", {}).get("map", {})
	_map_width = int(map_layer.get("width", 0))
	_map_height = int(map_layer.get("height", 0))
	if _map_width <= 0 or _map_height <= 0:
		push_warning("Map dimensions missing in %s" % map_json_path)

	_build_grh_index()


func _build_grh_index() -> void:
	_grh_entries.clear()
	_texture_cache.clear()

	var entries = _grh_data.get("entries", [])
	for entry in entries:
		if entry.has("id"):
			_grh_entries[int(entry["id"])] = entry


func _draw_grh(grh_index: int, position: Vector2) -> bool:
	var entry = _resolve_grh_entry(grh_index)
	if entry.is_empty():
		return false
	if not entry.has("file_num"):
		return false

	var file_num = int(entry["file_num"])
	var texture = _get_texture(file_num)
	if texture == null:
		return false

	var sx = int(entry.get("sx", 0))
	var sy = int(entry.get("sy", 0))
	var w = int(entry.get("pixel_width", tile_size))
	var h = int(entry.get("pixel_height", tile_size))

	var src_rect = Rect2(sx, sy, w, h)
	var dest_rect = Rect2(position, Vector2(w, h))
	draw_texture_rect_region(texture, dest_rect, src_rect)
	return true


func _resolve_grh_entry(grh_index: int) -> Dictionary:
	if not _grh_entries.has(grh_index):
		return {}
	var entry = _grh_entries[grh_index]
	if entry.get("num_frames", 1) > 1:
		var frames = entry.get("frames", [])
		if frames.size() > 0:
			var base_id = int(frames[0])
			if _grh_entries.has(base_id):
				return _grh_entries[base_id]
	return entry


func _get_texture(file_num: int) -> Texture2D:
	if _texture_cache.has(file_num):
		return _texture_cache[file_num]

	var texture: Texture2D = null
	var candidates = _build_candidate_paths(file_num)
	for path in candidates:
		if path.begins_with("res://"):
			if ResourceLoader.exists(path):
				texture = load(path)
		else:
			if FileAccess.file_exists(path):
				var img = Image.new()
				var err = img.load(path)
				if err == OK:
					texture = ImageTexture.create_from_image(img)
		if texture != null:
			break

	_texture_cache[file_num] = texture
	return texture


func _build_candidate_paths(file_num: int) -> Array:
	var base = asset_root
	if base.ends_with("/"):
		base = base.substr(0, base.length() - 1)
	var paths = []
	paths.append("%s/Grh%d.bmp" % [base, file_num])
	paths.append("%s/grh%d.bmp" % [base, file_num])
	paths.append("%s/GRH%d.BMP" % [base, file_num])
	return paths


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text = file.get_as_text()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _get_layer_value(graphics_layers: Array, layer_index: int, x: int, y: int) -> int:
	if layer_index >= graphics_layers.size():
		return 0
	var layer = graphics_layers[layer_index]
	return _get_grid_value(layer, x, y)


func _get_grid_value(grid: Array, x: int, y: int) -> int:
	if y < 0 or y >= grid.size():
		return 0
	var row = grid[y]
	if x < 0 or x >= row.size():
		return 0
	return int(row[x])


func _color_from_id(value: int) -> Color:
	var r = float((value * 73) % 255) / 255.0
	var g = float((value * 151) % 255) / 255.0
	var b = float((value * 199) % 255) / 255.0
	return Color(r, g, b, 1.0)
