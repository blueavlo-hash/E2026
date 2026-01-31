extends Node2D

@export var map_json_path: String = "res://data/maps/Map1.json"
@export var grh_json_path: String = "res://data/client/grh_data.json"
@export var tile_size: int = 32
@export var show_blocked_overlay: bool = true

var _map_data: Dictionary = {}
var _grh_data: Dictionary = {}
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
