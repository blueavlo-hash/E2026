extends Node2D

@export var map_json_path: String = "res://data/maps/Map1.json"
@export var grh_json_path: String = "res://data/client/grh_data.json"
@export var asset_root: String = "res://assets/grh"
@export var music_root: String = "res://assets/music"
@export var tile_size: int = 32
@export var show_blocked_overlay: bool = true
@export var draw_rain_layer: bool = false
@export var play_music: bool = true
@export var grh_speed_scale: float = 0.04
@export var apply_color_key: bool = true
@export var debug_hover: bool = true

var _map_data: Dictionary = {}
var _grh_data: Dictionary = {}
var _grh_entries: Dictionary = {}
var _texture_cache: Dictionary = {}
var _map_width: int = 0
var _map_height: int = 0
var _camera_tile: Vector2i = Vector2i(1, 1)
var _camera_speed: float = 10.0
var _animation_time: float = 0.0
var _has_animations: bool = false
var _audio_player: AudioStreamPlayer = null
var _music_index: int = 0
var _last_hover_info: String = ""


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

	if _has_animations:
		_animation_time += delta
		queue_redraw()

	if debug_hover:
		_update_hover_info()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			draw_rain_layer = not draw_rain_layer
			queue_redraw()


func _draw() -> void:
	if _map_data.is_empty():
		draw_string(_get_default_font(), Vector2(12, 24), "No map data loaded.")
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
				if layer_index == 2 and not draw_rain_layer:
					continue
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
		_get_default_font(),
		Vector2(12, view_size.y - 12),
		"Map %s | Camera %d,%d" % [_map_data.get("id", "?"), _camera_tile.x, _camera_tile.y]
	)

	if debug_hover and _last_hover_info != "":
		draw_string(
			_get_default_font(),
			Vector2(12, view_size.y - 36),
			_last_hover_info
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
	_setup_audio()
	_play_map_music()


func _build_grh_index() -> void:
	_grh_entries.clear()
	_texture_cache.clear()
	_has_animations = false

	var entries = _grh_data.get("entries", [])
	for entry in entries:
		if entry.has("id"):
			_grh_entries[int(entry["id"])] = entry
			if int(entry.get("num_frames", 1)) > 1:
				_has_animations = true


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
	var tile_w = float(entry.get("tile_width", 1.0))
	var tile_h = float(entry.get("tile_height", 1.0))

	var dest_pos = position
	if tile_w != 1.0:
		dest_pos.x -= int(tile_w * float(tile_size) * 0.5) - int(float(tile_size) * 0.5)
	if tile_h != 1.0:
		dest_pos.y -= int(tile_h * float(tile_size)) - tile_size

	var src_rect = Rect2(sx, sy, w, h)
	var dest_rect = Rect2(dest_pos, Vector2(w, h))
	draw_texture_rect_region(texture, dest_rect, src_rect)
	return true


func _update_hover_info() -> void:
	if _map_data.is_empty():
		_last_hover_info = ""
		return

	var viewport_pos = get_viewport().get_mouse_position()
	var view_size = get_viewport_rect().size
	var tiles_x = int(view_size.x / float(tile_size)) + 2
	var tiles_y = int(view_size.y / float(tile_size)) + 2

	var start_x = clamp(_camera_tile.x - tiles_x / 2, 0, max(0, _map_width - tiles_x))
	var start_y = clamp(_camera_tile.y - tiles_y / 2, 0, max(0, _map_height - tiles_y))

	var tile_x = int(viewport_pos.x / float(tile_size)) + start_x
	var tile_y = int(viewport_pos.y / float(tile_size)) + start_y

	if tile_x < 0 or tile_x >= _map_width or tile_y < 0 or tile_y >= _map_height:
		_last_hover_info = ""
		return

	var layers = _map_data.get("layers", {})
	var map_layer = layers.get("map", {})
	var graphics_layers = map_layer.get("graphics", [])

	var ids = []
	for layer_index in range(3):
		var grh_index = _get_layer_value(graphics_layers, layer_index, tile_x, tile_y)
		ids.append(grh_index)

	var info = "Tile %d,%d | L1:%d L2:%d L3:%d" % [tile_x, tile_y, ids[0], ids[1], ids[2]]
	_last_hover_info = info


func _resolve_grh_entry(grh_index: int) -> Dictionary:
	if not _grh_entries.has(grh_index):
		return {}
	var entry = _grh_entries[grh_index]
	if entry.get("num_frames", 1) > 1:
		var frames = entry.get("frames", [])
		if frames.size() > 0:
			var frame_index = _select_animation_frame(entry, frames)
			if _grh_entries.has(frame_index):
				return _grh_entries[frame_index]
	return entry


func _select_animation_frame(entry: Dictionary, frames: Array) -> int:
	var num_frames = int(entry.get("num_frames", frames.size()))
	if num_frames <= 0:
		return int(frames[0])
	var speed = float(entry.get("speed", 0))
	var frame_duration = max(0.05, speed * grh_speed_scale)
	var frame = int(floor(_animation_time / frame_duration)) % num_frames
	frame = clamp(frame, 0, frames.size() - 1)
	return int(frames[frame])


func _get_texture(file_num: int) -> Texture2D:
	if _texture_cache.has(file_num):
		return _texture_cache[file_num]

	var texture: Texture2D = null
	var candidates = _build_candidate_paths(file_num)
	for path in candidates:
		if path.begins_with("res://"):
			if not ResourceLoader.exists(path):
				continue
		else:
			if not FileAccess.file_exists(path):
				continue

		var img = Image.new()
		var err = img.load(path)
		if err != OK:
			continue
		if apply_color_key:
			_apply_black_colorkey(img)
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
	paths.append("%s/grh%dM.bmp" % [base, file_num])
	paths.append("%s/GRH%dM.BMP" % [base, file_num])
	return paths


func _apply_black_colorkey(img: Image) -> void:
	var size = img.get_size()
	for y in range(size.y):
		for x in range(size.x):
			var c = img.get_pixel(x, y)
			if c.r <= 0.01 and c.g <= 0.01 and c.b <= 0.01:
				img.set_pixel(x, y, Color(0, 0, 0, 0))


func _setup_audio() -> void:
	if _audio_player != null:
		return
	_audio_player = AudioStreamPlayer.new()
	_audio_player.bus = "Master"
	add_child(_audio_player)


func _play_map_music() -> void:
	if not play_music:
		return
	if _map_data.is_empty():
		return

	var map_id = int(_map_data.get("id", 0))
	var meta = _map_data.get("meta", {})
	var sections = meta.get("sections", [])
	var music_num = ""
	for section in sections:
		if section.get("name", "") == "Map%d" % map_id:
			music_num = str(section.get("values", {}).get("MusicNum", ""))
			break

	if music_num == "":
		return

	var index = _parse_music_index(music_num)
	if index <= 0:
		return

	_music_index = index
	var stream = _load_music_stream(index)
	if stream == null:
		push_warning("Music not found for index %d" % index)
		return

	_audio_player.stream = stream
	_audio_player.play()


func _parse_music_index(value: String) -> int:
	var normalized = value.strip_edges()
	if normalized == "":
		return 0
	var parts = normalized.split("-")
	if parts.size() == 0:
		return 0
	return int(parts[0])


func _load_music_stream(index: int) -> AudioStream:
	var base = music_root
	if base.ends_with("/"):
		base = base.substr(0, base.length() - 1)
	var candidates = [
		"%s/Mus%d.ogg" % [base, index],
		"%s/mus%d.ogg" % [base, index],
	]
	for path in candidates:
		if ResourceLoader.exists(path):
			return load(path)
	return null


func _get_default_font() -> Font:
	return ThemeDB.get_default_theme().get_font("font", "Label")


func toggle_music() -> void:
	if _audio_player == null:
		return
	if _audio_player.playing:
		_audio_player.stop()
	else:
		_play_map_music()


func set_music_volume(value: float) -> void:
	if _audio_player == null:
		return
	_audio_player.volume_db = linear_to_db(clamp(value, 0.0, 1.0))


func is_music_playing() -> bool:
	if _audio_player == null:
		return false
	return _audio_player.playing


func is_rain_layer_enabled() -> bool:
	return draw_rain_layer


func is_blocked_overlay_enabled() -> bool:
	return show_blocked_overlay


func get_map_id() -> int:
	return int(_map_data.get("id", 0))


func get_music_index() -> int:
	return _music_index


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
