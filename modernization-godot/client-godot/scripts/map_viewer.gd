extends Node2D

@export var map_json_path: String = "res://data/maps/Map1.json"
@export var grh_json_path: String = "res://data/client/grh_data.json"
@export var body_json_path: String = "res://data/client/body.json"
@export var head_json_path: String = "res://data/client/head.json"
@export var weapon_anim_json_path: String = "res://data/client/weapon_anim.json"
@export var map_data_root: String = "res://data/maps"
@export var asset_root: String = "res://assets/grh"
@export var music_root: String = "res://assets/music"
@export var tile_size: int = 32
@export var show_blocked_overlay: bool = true
@export var show_exit_overlay: bool = true
@export var draw_rain_layer: bool = false
@export var show_layer_1: bool = true
@export var show_layer_2: bool = true
@export var show_layer_3: bool = true
@export var show_layer_4: bool = true
@export var roof_layer_index: int = 3
@export var roof_fade_enabled: bool = true
@export var roof_fade_speed: float = 6.0
@export var play_music: bool = true
@export var grh_speed_scale: float = 0.04
@export var apply_color_key: bool = true
@export var color_key_tolerance: float = 0.06
@export_enum("auto", "topleft", "magenta", "black", "custom") var color_key_mode: String = "auto"
@export var custom_color_key: Color = Color(1.0, 0.0, 1.0)
@export var flood_fill_background: bool = true
@export var debug_color_key: bool = false
@export var debug_color_key_file: int = 0
@export var player_enabled: bool = true
@export var player_grh_id: int = 0
@export var player_body_id: int = 1
@export var player_head_id: int = 1
@export var player_head_offset: Vector2 = Vector2(0, -27)
@export var player_speed_tiles: float = 5.0
@export var follow_player: bool = true
@export var camera_follow_speed: float = 16.0
@export var player_render_smooth: float = 12.0
@export var movement_substeps: int = 4
@export var player_start_tile: Vector2i = Vector2i(27, 18)
@export var debug_hover: bool = true
@export var debug_overlap: bool = false
@export var edit_enabled: bool = true
@export_enum("paint", "erase", "blocked", "exit", "interior", "eyedrop") var edit_tool: String = "paint"
@export var edit_layer_index: int = 0
@export var edit_grh_id: int = 1
@export var edit_exit_map: int = 1
@export var edit_exit_x: int = 10
@export var edit_exit_y: int = 10
@export var edit_alpha_preview: bool = false
@export var edit_alpha_floor: float = 0.3
@export var starter_sword_enabled: bool = true
@export var attack_duration: float = 0.25
@export var attack_cooldown: float = 0.35
@export var weapon_hold_offset_n: Vector2 = Vector2(0, -10)
@export var weapon_hold_offset_e: Vector2 = Vector2(2, -4)
@export var weapon_hold_offset_s: Vector2 = Vector2(0, 6)
@export var weapon_hold_offset_w: Vector2 = Vector2(-2, -4)
@export var weapon_swing_offset_n: Vector2 = Vector2(0, -8)
@export var weapon_swing_offset_e: Vector2 = Vector2(16, 0)
@export var weapon_swing_offset_s: Vector2 = Vector2(0, 8)
@export var weapon_swing_offset_w: Vector2 = Vector2(-16, 0)
@export var npc_enabled: bool = true
@export var npc_grh_id: int = 10032
@export var npc_frames: Array = []
@export var npc_anim_fps: float = 8.0
@export var npc_spawn_tile: Vector2i = Vector2i(28, 18)
@export var npc_max_hp: int = 10
@export var npc_hit_range: float = 1.2
@export var npc_hit_fov: float = 0.7
@export var npc_damage: int = 3
@export var weapon_frame_fps: float = 12.0

var _map_data: Dictionary = {}
var _grh_data: Dictionary = {}
var _grh_entries: Dictionary = {}
var _body_entries: Dictionary = {}
var _head_entries: Dictionary = {}
var _weapon_anim_entries: Dictionary = {}
var _texture_cache: Dictionary = {}
var _texture_cache_floor: Dictionary = {}
var _icon_texture_cache: Dictionary = {}
var _map_width: int = 0
var _map_height: int = 0
var _camera_pos: Vector2 = Vector2.ZERO
var _camera_render_pos: Vector2 = Vector2.ZERO
var _camera_speed: float = 10.0
var _animation_time: float = 0.0
var _has_animations: bool = false
var _audio_player: AudioStreamPlayer = null
var _music_index: int = 0
var _last_hover_info: String = ""
var _last_color_key_settings: Dictionary = {}
var _player_pos: Vector2 = Vector2.ZERO
var _player_render_pos: Vector2 = Vector2.ZERO
var _player_dir: int = 2
var _player_anim_time: float = 0.0
var _weapon_anim_time: float = 0.0
var _player_moving: bool = false
var _exit_cooldown: float = 0.0
var _interior_alphas: Dictionary = {}
var _player_interior_id: int = 0
var _last_edit_tile: Vector2i = Vector2i(-1, -1)
var _pending_exit_tile: Vector2i = Vector2i(-1, -1)
var _overlap_anchor: Vector2i = Vector2i(-1, -1)
var _overlap_grh_id: int = 0
var _overlap_layer: int = -1
var _player_input_dir: Vector2 = Vector2.ZERO
var _move_accum: float = 0.0
var _prev_player_pos: Vector2 = Vector2.ZERO
var _prev_camera_pos: Vector2 = Vector2.ZERO
var _inventory: Array = []
var _equipped_weapon_index: int = -1
var _attack_timer: float = 0.0
var _attack_cooldown_timer: float = 0.0
var _attack_requested: bool = false
var _attack_hit_applied: bool = false

var _npcs: Array = []
var _npc_anim_time: float = 0.0

const FIXED_STEP := 1.0 / 60.0

signal exit_tile_requested(tile_x: int, tile_y: int)

const DIR_KEYS = ["Walk1", "Walk2", "Walk3", "Walk4"]
const HEAD_KEYS = ["Head1", "Head2", "Head3", "Head4"]
const WEAPON_KEYS = ["WeaponWalk1", "WeaponWalk2", "WeaponWalk3", "WeaponWalk4"]


func _ready() -> void:
	_load_data()
	queue_redraw()


func _process(delta: float) -> void:
	if _color_key_settings_changed():
		_texture_cache.clear()
		queue_redraw()

	if player_enabled and not _map_data.is_empty():
		_player_input_dir = _get_player_input_dir()
		_player_moving = _player_input_dir != Vector2.ZERO
		if _player_moving:
			_update_player_direction(_player_input_dir)
			_player_anim_time += delta
		else:
			_player_anim_time = 0.0
		if npc_enabled:
			_npc_anim_time += delta
		if _player_moving or _attack_timer > 0.0:
			_weapon_anim_time += delta
		else:
			_weapon_anim_time = 0.0
		_move_accum = min(_move_accum + delta, 0.25)
		var step_count = 0
		while _move_accum >= FIXED_STEP and step_count < 5:
			_prev_player_pos = _player_pos
			_prev_camera_pos = _camera_pos
			if _attack_cooldown_timer > 0.0:
				_attack_cooldown_timer = max(0.0, _attack_cooldown_timer - FIXED_STEP)
			if _attack_requested and _attack_cooldown_timer <= 0.0:
				_attack_requested = false
				_attack_timer = attack_duration
				_attack_cooldown_timer = attack_cooldown
				_weapon_anim_time = 0.0
				_attack_hit_applied = false
			if _attack_timer > 0.0:
				_attack_timer = max(0.0, _attack_timer - FIXED_STEP)
				if not _attack_hit_applied and _attack_timer <= attack_duration * 0.6:
					_apply_attack_hit()
					_attack_hit_applied = true
			_fixed_move(FIXED_STEP)
			if follow_player:
				_camera_pos = _player_pos
				_camera_pos.x = clamp(_camera_pos.x, 0.0, max(0.0, float(_map_width - 1)))
				_camera_pos.y = clamp(_camera_pos.y, 0.0, max(0.0, float(_map_height - 1)))
			_move_accum -= FIXED_STEP
			step_count += 1
		var alpha = _move_accum / FIXED_STEP
		_player_render_pos = _prev_player_pos.lerp(_player_pos, alpha)
		_camera_render_pos = _player_render_pos if follow_player else _prev_camera_pos.lerp(_camera_pos, alpha)

	var move = Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT):
		move.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		move.x += 1.0
	if Input.is_key_pressed(KEY_UP):
		move.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN):
		move.y += 1.0

	if not follow_player and move != Vector2.ZERO:
		_camera_pos.x = clamp(
			_camera_pos.x + move.x * _camera_speed * delta,
			0.0,
			max(0.0, float(_map_width - 1))
		)
		_camera_pos.y = clamp(
			_camera_pos.y + move.y * _camera_speed * delta,
			0.0,
			max(0.0, float(_map_height - 1))
		)
		_camera_render_pos = _camera_pos
		queue_redraw()

	if _has_animations:
		_animation_time += delta
		queue_redraw()

	if debug_hover:
		_update_hover_info()

	if _exit_cooldown > 0.0:
		_exit_cooldown = max(0.0, _exit_cooldown - delta)

	if roof_fade_enabled:
		_update_roof_fade(delta)



func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			draw_rain_layer = not draw_rain_layer
			queue_redraw()
		elif event.keycode == KEY_C:
			_texture_cache.clear()
			queue_redraw()
		elif event.keycode == KEY_F:
			follow_player = not follow_player
			queue_redraw()
		elif event.keycode == KEY_E:
			show_exit_overlay = not show_exit_overlay
			queue_redraw()
		elif event.keycode == KEY_O:
			debug_overlap = not debug_overlap
			queue_redraw()
		elif event.keycode == KEY_F1:
			edit_enabled = not edit_enabled
			queue_redraw()
		elif event.keycode == KEY_F2:
			edit_tool = "paint"
		elif event.keycode == KEY_F3:
			edit_tool = "erase"
		elif event.keycode == KEY_F4:
			edit_tool = "blocked"
		elif event.keycode == KEY_F5:
			edit_tool = "exit"
		elif event.keycode == KEY_F6:
			edit_tool = "interior"
		elif event.keycode == KEY_F7:
			edit_tool = "eyedrop"
		elif event.keycode == KEY_1:
			edit_layer_index = 0
		elif event.keycode == KEY_2:
			edit_layer_index = 1
		elif event.keycode == KEY_3:
			edit_layer_index = 2
		elif event.keycode == KEY_4:
			edit_layer_index = 3
		elif event.keycode == KEY_BRACKETLEFT:
			edit_grh_id = max(0, edit_grh_id - 1)
		elif event.keycode == KEY_BRACKETRIGHT:
			edit_grh_id = edit_grh_id + 1
		elif event.keycode == KEY_SPACE:
			if _has_weapon_equipped():
				_attack_requested = true
		elif event.keycode == KEY_S and event.ctrl_pressed:
			_save_map()

	if edit_enabled and event is InputEventMouseButton and event.pressed:
		_handle_edit_click(event)
	elif edit_enabled and event is InputEventMouseMotion:
		var left_down = (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
		var right_down = (event.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0
		if left_down or right_down:
			_handle_edit_drag(left_down, right_down)


func _draw() -> void:
	if _map_data.is_empty():
		draw_string(_get_default_font(), Vector2(12, 24), "No map data loaded.")
		return

	var view = _get_view_params()
	var view_size = view["view_size"]
	var tiles_x = view["tiles_x"]
	var tiles_y = view["tiles_y"]
	var start_x = view["start_x"]
	var start_y = view["start_y"]
	var cam_tile = view["cam_tile"]
	var end_x = min(_map_width, start_x + tiles_x)
	var end_y = min(_map_height, start_y + tiles_y)
	var cam_offset = view["cam_offset"]

	var layers = _map_data.get("layers", {})
	var map_layer = layers.get("map", {})
	var blocked = map_layer.get("blocked", [])
	var graphics_layers = map_layer.get("graphics", [])
	var inf_layer = layers.get("inf", {})
	var exit_map = inf_layer.get("tile_exit_map", [])
	var exit_x = inf_layer.get("tile_exit_x", [])
	var exit_y = inf_layer.get("tile_exit_y", [])
	var edge_exits = _get_edge_exits()

	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			var screen_pos = Vector2(
				(x - start_x) * tile_size - cam_offset.x,
				(y - start_y) * tile_size - cam_offset.y
			)

			for layer_index in range(4):
				if layer_index == 2 and not draw_rain_layer and roof_layer_index != 2:
					continue
				if layer_index == 0 and not show_layer_1:
					continue
				if layer_index == 1 and not show_layer_2:
					continue
				if layer_index == 2 and not show_layer_3:
					continue
				if layer_index == 3 and not show_layer_4:
					continue
				var grh_index = _get_layer_value(graphics_layers, layer_index, x, y)
				if grh_index > 0:
					var alpha = 1.0
					if roof_fade_enabled and layer_index == roof_layer_index:
						alpha = _get_roof_alpha(x, y)
					var preview = edit_alpha_preview
					if not _draw_grh(grh_index, screen_pos, alpha, preview):
						var color = _color_from_id(grh_index)
						draw_rect(Rect2(screen_pos, Vector2(tile_size, tile_size)), color)

			if show_blocked_overlay and _get_grid_value(blocked, x, y) == 1:
				draw_rect(
					Rect2(screen_pos, Vector2(tile_size, tile_size)),
					Color(1.0, 0.1, 0.1, 0.35),
					true
				)
			if show_exit_overlay and _get_grid_value(exit_map, x, y) > 0:
				draw_rect(
					Rect2(screen_pos, Vector2(tile_size, tile_size)),
					Color(0.2, 0.9, 1.0, 0.25),
					true
				)
			if show_exit_overlay:
				if edge_exits["north"] > 0 and y == 0:
					draw_rect(
						Rect2(screen_pos, Vector2(tile_size, tile_size)),
						Color(0.1, 0.6, 1.0, 0.2),
						true
					)
				if edge_exits["south"] > 0 and y == _map_height - 1:
					draw_rect(
						Rect2(screen_pos, Vector2(tile_size, tile_size)),
						Color(0.1, 0.6, 1.0, 0.2),
						true
					)
				if edge_exits["west"] > 0 and x == 0:
					draw_rect(
						Rect2(screen_pos, Vector2(tile_size, tile_size)),
						Color(0.1, 0.6, 1.0, 0.2),
						true
					)
				if edge_exits["east"] > 0 and x == _map_width - 1:
					draw_rect(
						Rect2(screen_pos, Vector2(tile_size, tile_size)),
						Color(0.1, 0.6, 1.0, 0.2),
						true
					)

	_draw_player(start_x, start_y, cam_offset)
	_draw_npcs(start_x, start_y, cam_offset)

	draw_string(
		_get_default_font(),
		Vector2(12, view_size.y - 12),
		"Map %s | Camera %d,%d | Player %d,%d | Follow %s" % [
			_map_data.get("id", "?"),
			cam_tile.x,
			cam_tile.y,
			int(round(_player_pos.x)),
			int(round(_player_pos.y)),
			follow_player
		]
	)

	if debug_hover and _last_hover_info != "":
		draw_string(
			_get_default_font(),
			Vector2(12, view_size.y - 36),
			_last_hover_info
		)
	if debug_overlap and _overlap_anchor.x >= 0:
		var anchor_pos = Vector2(
			(_overlap_anchor.x - start_x) * tile_size - cam_offset.x,
			(_overlap_anchor.y - start_y) * tile_size - cam_offset.y
		)
		draw_rect(Rect2(anchor_pos, Vector2(tile_size, tile_size)), Color(1.0, 0.6, 0.1, 0.8), false, 2.0)
	if edit_enabled:
		_draw_edit_cursor(start_x, start_y, cam_offset)


func _get_view_params() -> Dictionary:
	var view_size = get_viewport_rect().size
	var tiles_x = int(view_size.x / float(tile_size)) + 2
	var tiles_y = int(view_size.y / float(tile_size)) + 2
	var cam_tile = Vector2i(int(floor(_camera_render_pos.x)), int(floor(_camera_render_pos.y)))
	var max_start_x = max(0, _map_width - tiles_x)
	var max_start_y = max(0, _map_height - tiles_y)
	var start_x = clamp(cam_tile.x - tiles_x / 2, 0, max_start_x)
	var start_y = clamp(cam_tile.y - tiles_y / 2, 0, max_start_y)
	var cam_offset = Vector2(
		(_camera_render_pos.x - float(cam_tile.x)) * float(tile_size),
		(_camera_render_pos.y - float(cam_tile.y)) * float(tile_size)
	)
	if start_x == 0 or start_x == max_start_x:
		cam_offset.x = 0.0
	if start_y == 0 or start_y == max_start_y:
		cam_offset.y = 0.0
	return {
		"view_size": view_size,
		"tiles_x": tiles_x,
		"tiles_y": tiles_y,
		"start_x": start_x,
		"start_y": start_y,
		"cam_offset": cam_offset,
		"cam_tile": cam_tile,
	}


func _draw_edit_cursor(start_x: int, start_y: int, cam_offset: Vector2) -> void:
	var tile = _get_mouse_tile()
	if tile.x < 0:
		return
	var screen_pos = Vector2(
		(tile.x - start_x) * tile_size - cam_offset.x,
		(tile.y - start_y) * tile_size - cam_offset.y
	)
	draw_rect(Rect2(screen_pos, Vector2(tile_size, tile_size)), Color(1.0, 1.0, 0.2, 0.35), false, 2.0)


func _load_data() -> void:
	_map_data = _load_json(map_json_path)
	_grh_data = _load_json(grh_json_path)
	_body_entries = _load_ini_list(body_json_path)
	_head_entries = _load_ini_list(head_json_path)
	_weapon_anim_entries = _load_ini_list(weapon_anim_json_path)

	if _map_data.is_empty():
		push_warning("Map data not found: %s" % map_json_path)
		return

	var map_layer = _map_data.get("layers", {}).get("map", {})
	_map_width = int(map_layer.get("width", 0))
	_map_height = int(map_layer.get("height", 0))
	if _map_width <= 0 or _map_height <= 0:
		push_warning("Map dimensions missing in %s" % map_json_path)

	_player_pos = _resolve_player_spawn()
	_player_render_pos = _player_pos
	_camera_pos = _player_pos
	_camera_render_pos = _camera_pos
	_prev_player_pos = _player_pos
	_prev_camera_pos = _camera_pos
	_build_grh_index()
	_ensure_graphics_layers(4)
	_ensure_editor_layers()
	_ensure_starter_items()
	_seed_npcs()
	_setup_audio()
	_play_map_music()


func _load_map_by_id(map_id: int, spawn_x: int, spawn_y: int) -> void:
	var path = _resolve_map_path(map_id)
	if path == "":
		push_warning("Map %d not found in %s" % [map_id, map_data_root])
		return
	var data = _load_json(path)
	if data.is_empty():
		push_warning("Map data not found: %s" % path)
		return
	_map_data = data
	_map_data["id"] = map_id
	var map_layer = _map_data.get("layers", {}).get("map", {})
	_map_width = int(map_layer.get("width", 0))
	_map_height = int(map_layer.get("height", 0))
	_player_pos = Vector2(spawn_x, spawn_y)
	_player_render_pos = _player_pos
	_camera_pos = _player_pos
	_camera_render_pos = _camera_pos
	_prev_player_pos = _player_pos
	_prev_camera_pos = _camera_pos
	_ensure_graphics_layers(4)
	_ensure_editor_layers()
	_exit_cooldown = 0.3
	_ensure_starter_items()
	_seed_npcs()
	_play_map_music()
	queue_redraw()


func _build_grh_index() -> void:
	_grh_entries.clear()
	_texture_cache.clear()
	_texture_cache_floor.clear()
	_icon_texture_cache.clear()
	_has_animations = false

	var entries = _grh_data.get("entries", [])
	for entry in entries:
		if entry.has("id"):
			_grh_entries[int(entry["id"])] = entry
			if int(entry.get("num_frames", 1)) > 1:
				_has_animations = true


func _draw_grh(grh_index: int, position: Vector2, alpha: float = 1.0, preview_alpha: bool = false) -> bool:
	var entry = _resolve_grh_entry(grh_index)
	if entry.is_empty():
		return false
	if not entry.has("file_num"):
		return false

	var file_num = int(entry["file_num"])
	var texture = _get_texture(file_num) if not preview_alpha else _get_texture_with_alpha_floor(file_num, edit_alpha_floor)
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
	draw_texture_rect_region(texture, dest_rect, src_rect, Color(1.0, 1.0, 1.0, alpha))
	return true


func _draw_grh_at_time(grh_index: int, position: Vector2, time: float) -> bool:
	var entry = _resolve_grh_entry_at_time(grh_index, time)
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


func _draw_player(start_x: int, start_y: int, cam_offset: Vector2) -> void:
	if not player_enabled:
		return
	if _player_pos.x < start_x or _player_pos.y < start_y:
		return
	var screen_x = (_player_render_pos.x - float(start_x)) * float(tile_size) - cam_offset.x
	var screen_y = (_player_render_pos.y - float(start_y)) * float(tile_size) - cam_offset.y
	var view_size = get_viewport_rect().size
	if screen_x < -tile_size or screen_y < -tile_size:
		return
	if screen_x > view_size.x or screen_y > view_size.y:
		return
	var pos = Vector2(screen_x, screen_y)
	if player_grh_id > 0:
		_draw_grh_at_time(player_grh_id, pos, _player_anim_time)
	else:
		var body_grh = _get_body_walk_grh(player_body_id, _player_dir)
		var head_grh = _get_head_walk_grh(player_head_id, _player_dir)
		var weapon_anim_id = _get_equipped_weapon_anim_id()
		var weapon_grh = _get_weapon_walk_grh(weapon_anim_id, _player_dir)
		var weapon_icon = _get_equipped_weapon_icon_grh()
		var weapon_direct = _get_equipped_weapon_grh()
		var weapon_frame = _get_equipped_weapon_frame()
		_draw_grh_at_time(body_grh, pos, _player_anim_time)
		if weapon_grh > 0 or weapon_direct > 0 or weapon_frame > 0 or weapon_icon > 0:
			var weapon_pos = pos + _get_weapon_offset(_player_dir, _attack_timer > 0.0)
			var weapon_draw_id = weapon_grh if weapon_grh > 0 else (weapon_frame if weapon_frame > 0 else (weapon_direct if weapon_direct > 0 else weapon_icon))
			_draw_grh_at_time(weapon_draw_id, weapon_pos, _weapon_anim_time)
		if head_grh > 0:
			var offset = _get_body_head_offset(player_body_id, player_head_offset)
			_draw_grh_at_time(head_grh, pos + offset, _player_anim_time)
		return
	draw_rect(Rect2(pos, Vector2(tile_size, tile_size)), Color(1.0, 0.8, 0.2, 0.9), true)


func _draw_npcs(start_x: int, start_y: int, cam_offset: Vector2) -> void:
	if not npc_enabled:
		return
	for npc in _npcs:
		if npc.get("dead", false):
			continue
		var pos: Vector2 = npc.get("pos", Vector2.ZERO)
		var screen_x = (pos.x - float(start_x)) * float(tile_size) - cam_offset.x
		var screen_y = (pos.y - float(start_y)) * float(tile_size) - cam_offset.y
		var view_size = get_viewport_rect().size
		if screen_x < -tile_size or screen_y < -tile_size:
			continue
		if screen_x > view_size.x or screen_y > view_size.y:
			continue
		var draw_pos = Vector2(screen_x, screen_y)
		if npc_frames.size() > 0:
			var frame_id = _select_item_frame(npc_frames, _npc_anim_time, npc_anim_fps)
			_draw_grh_at_time(frame_id, draw_pos, _npc_anim_time)
		elif npc_grh_id > 0:
			_draw_grh_at_time(npc_grh_id, draw_pos, _npc_anim_time)
		else:
			draw_rect(Rect2(draw_pos, Vector2(tile_size, tile_size)), Color(0.9, 0.2, 0.2, 0.9), true)
		var hp = int(npc.get("hp", 0))
		draw_string(_get_default_font(), draw_pos + Vector2(0, -4), str(hp))


func _update_hover_info() -> void:
	if _map_data.is_empty():
		_last_hover_info = ""
		return

	var viewport_pos = get_viewport().get_mouse_position()
	var view = _get_view_params()
	var start_x = view["start_x"]
	var start_y = view["start_y"]
	var cam_offset = view["cam_offset"]

	var tile_x = int((viewport_pos.x + cam_offset.x) / float(tile_size)) + start_x
	var tile_y = int((viewport_pos.y + cam_offset.y) / float(tile_size)) + start_y

	if tile_x < 0 or tile_x >= _map_width or tile_y < 0 or tile_y >= _map_height:
		_last_hover_info = ""
		return

	var layers = _map_data.get("layers", {})
	var map_layer = layers.get("map", {})
	var graphics_layers = map_layer.get("graphics", [])

	var ids = []
	for layer_index in range(4):
		var grh_index = _get_layer_value(graphics_layers, layer_index, tile_x, tile_y)
		ids.append(grh_index)

	var info = "Tile %d,%d | L1:%d L2:%d L3:%d L4:%d" % [
		tile_x, tile_y, ids[0], ids[1], ids[2], ids[3]
	]
	if debug_overlap:
		var overlap = _find_overlapping_grh(tile_x, tile_y)
		if overlap.is_empty():
			_overlap_anchor = Vector2i(-1, -1)
			_overlap_layer = -1
			_overlap_grh_id = 0
			info += " | Overlap: none"
		else:
			_overlap_anchor = overlap["anchor"]
			_overlap_layer = overlap["layer"]
			_overlap_grh_id = overlap["grh"]
			info += " | Overlap: L%d GRH:%d @ %d,%d" % [
				_overlap_layer + 1,
				_overlap_grh_id,
				_overlap_anchor.x,
				_overlap_anchor.y
			]
	_last_hover_info = info


func _update_player(delta: float) -> void:
	if _exit_cooldown <= 0.0 and not _map_data.is_empty():
		_try_exit_tile()

	if roof_fade_enabled:
		_player_interior_id = _get_interior_id(int(round(_player_pos.x)), int(round(_player_pos.y)))


func _resolve_player_spawn() -> Vector2:
	if _map_data.is_empty() or _map_width <= 0 or _map_height <= 0:
		return Vector2.ZERO

	if player_start_tile.x >= 0 and player_start_tile.y >= 0:
		if not _is_blocked_tile(player_start_tile.x, player_start_tile.y):
			return Vector2(player_start_tile.x, player_start_tile.y)

	var center = Vector2i(int(_map_width / 2), int(_map_height / 2))
	if not _is_blocked_tile(center.x, center.y):
		return Vector2(center.x, center.y)

	var max_radius = max(_map_width, _map_height)
	for radius in range(1, max_radius):
		for y in range(center.y - radius, center.y + radius + 1):
			for x in range(center.x - radius, center.x + radius + 1):
				if x < 0 or y < 0 or x >= _map_width or y >= _map_height:
					continue
				if not _is_blocked_tile(x, y):
					return Vector2(x, y)

	return Vector2(0, 0)


func _seed_npcs() -> void:
	_npcs.clear()
	if not npc_enabled:
		return
	if npc_frames.size() == 0:
		for i in range(10032, 10064):
			npc_frames.append(i)
	var pos = Vector2(npc_spawn_tile.x, npc_spawn_tile.y)
	_npcs.append({
		"id": 1,
		"pos": pos,
		"hp": npc_max_hp,
		"dead": false
	})


func _apply_attack_hit() -> void:
	if _npcs.size() == 0:
		return
	var dir = _dir_to_vector(_player_dir)
	var origin = _player_pos
	var best_index = -1
	var best_dist = 999.0
	for i in range(_npcs.size()):
		var npc = _npcs[i]
		if npc.get("dead", false):
			continue
		var pos: Vector2 = npc.get("pos", Vector2.ZERO)
		var to_npc = pos - origin
		var dist = to_npc.length()
		if dist > npc_hit_range:
			continue
		var dot = 0.0
		if dist > 0.001:
			dot = dir.dot(to_npc / dist)
		if dot < npc_hit_fov:
			continue
		if dist < best_dist:
			best_dist = dist
			best_index = i
	if best_index == -1:
		return
	var npc = _npcs[best_index]
	var hp = int(npc.get("hp", 0))
	hp -= npc_damage
	npc["hp"] = hp
	if hp <= 0:
		npc["dead"] = true
	_npcs[best_index] = npc


func _dir_to_vector(dir: int) -> Vector2:
	match dir:
		0:
			return Vector2(0, -1)
		1:
			return Vector2(1, 0)
		2:
			return Vector2(0, 1)
		3:
			return Vector2(-1, 0)
	return Vector2.ZERO


func _get_player_input_dir() -> Vector2:
	var move = Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		move.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		move.x += 1.0
	if Input.is_key_pressed(KEY_W):
		move.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		move.y += 1.0
	if move == Vector2.ZERO:
		return move
	if move.length() > 1.0:
		move = move.normalized()
	return move


func _fixed_move(step_time: float) -> void:
	if _player_input_dir == Vector2.ZERO:
		return
	var step = _player_input_dir * player_speed_tiles * step_time
	_move_with_substeps(step)
	_clamp_player_pos()


func _ensure_editor_layers() -> void:
	var layers = _map_data.get("layers", {})
	if not layers.has("editor"):
		layers["editor"] = {}
	var editor = layers.get("editor", {})
	if not editor.has("interior"):
		var interior = []
		for y in range(_map_height):
			var row = []
			row.resize(_map_width)
			for x in range(_map_width):
				row[x] = 0
			interior.append(row)
		editor["interior"] = interior
		layers["editor"] = editor
		_map_data["layers"] = layers
	_inter_sync_alphas()


func _ensure_graphics_layers(count: int) -> void:
	var layers = _map_data.get("layers", {})
	var map_layer = layers.get("map", {})
	var graphics_layers = map_layer.get("graphics", [])
	if graphics_layers.size() >= count:
		return
	for layer_index in range(graphics_layers.size(), count):
		var layer = []
		for y in range(_map_height):
			var row = []
			row.resize(_map_width)
			for x in range(_map_width):
				row[x] = 0
			layer.append(row)
		graphics_layers.append(layer)
	map_layer["graphics"] = graphics_layers
	layers["map"] = map_layer
	_map_data["layers"] = layers


func _inter_sync_alphas() -> void:
	_interior_alphas.clear()
	var interior = _get_interior_grid()
	if interior.size() == 0:
		return
	_interior_alphas[1] = 1.0


func _get_interior_grid() -> Array:
	var layers = _map_data.get("layers", {})
	var editor = layers.get("editor", {})
	return editor.get("interior", [])


func _get_interior_id(x: int, y: int) -> int:
	var interior = _get_interior_grid()
	if interior.size() == 0:
		return 0
	if y < 0 or y >= interior.size():
		return 0
	var row = interior[y]
	if x < 0 or x >= row.size():
		return 0
	return int(row[x])


func _update_roof_fade(delta: float) -> void:
	if _interior_alphas.is_empty():
		return
	var step = clamp(roof_fade_speed * delta, 0.0, 1.0)
	var target = 1.0
	if _player_interior_id > 0:
		target = 0.0
	var current = float(_interior_alphas.get(1, 1.0))
	_interior_alphas[1] = lerp(current, target, step)
	queue_redraw()


func _get_roof_alpha(x: int, y: int) -> float:
	var region_id = _get_interior_id(x, y)
	if region_id <= 0:
		return 1.0
	return float(_interior_alphas.get(1, 1.0))


func _is_blocked_tile(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= _map_width or y >= _map_height:
		return true
	var layers = _map_data.get("layers", {})
	var map_layer = layers.get("map", {})
	var blocked = map_layer.get("blocked", [])
	return _get_grid_value(blocked, x, y) == 1




func _try_exit_tile() -> void:
	var tile_x = int(round(_player_pos.x))
	var tile_y = int(round(_player_pos.y))
	var exit = _get_exit_at(tile_x, tile_y)
	if exit.is_empty():
		_try_edge_exit(tile_x, tile_y)
		return
	var map_id = int(exit.get("map", 0))
	var spawn_x = int(exit.get("x", tile_x))
	var spawn_y = int(exit.get("y", tile_y))
	if map_id > 0:
		_load_map_by_id(map_id, spawn_x, spawn_y)


func _get_exit_at(x: int, y: int) -> Dictionary:
	var layers = _map_data.get("layers", {})
	var inf_layer = layers.get("inf", {})
	var exit_map = inf_layer.get("tile_exit_map", [])
	var exit_x = inf_layer.get("tile_exit_x", [])
	var exit_y = inf_layer.get("tile_exit_y", [])
	if _get_grid_value(exit_map, x, y) <= 0:
		return {}
	return {
		"map": _get_grid_value(exit_map, x, y),
		"x": _get_grid_value(exit_x, x, y),
		"y": _get_grid_value(exit_y, x, y),
	}


func _move_with_substeps(step: Vector2) -> void:
	var steps = max(1, movement_substeps)
	var step_x = step.x / steps
	var step_y = step.y / steps
	for i in range(steps):
		var new_x = _player_pos.x + step_x
		var test_y = int(round(_player_pos.y))
		if not _is_blocked_tile(int(round(new_x)), test_y):
			_player_pos.x = new_x
		var new_y = _player_pos.y + step_y
		var test_x = int(round(_player_pos.x))
		if not _is_blocked_tile(test_x, int(round(new_y))):
			_player_pos.y = new_y


func _clamp_player_pos() -> void:
	_player_pos.x = clamp(_player_pos.x, 0.0, max(0.0, float(_map_width - 1)))
	_player_pos.y = clamp(_player_pos.y, 0.0, max(0.0, float(_map_height - 1)))


func _handle_edit_click(event: InputEventMouseButton) -> void:
	if _map_data.is_empty():
		return
	var tile = _get_mouse_tile()
	if tile.x < 0:
		return
	_last_edit_tile = tile
	var left_click = event.button_index == MOUSE_BUTTON_LEFT
	var right_click = event.button_index == MOUSE_BUTTON_RIGHT
	_apply_edit(tile.x, tile.y, left_click, right_click)



func _handle_edit_drag(left_down: bool, right_down: bool) -> void:
	if _map_data.is_empty():
		return
	if edit_tool == "exit":
		return
	var tile = _get_mouse_tile()
	if tile.x < 0:
		return
	if tile == _last_edit_tile:
		return
	_last_edit_tile = tile
	_apply_edit(tile.x, tile.y, left_down, right_down)


func _get_mouse_tile() -> Vector2i:
	var viewport_pos = get_viewport().get_mouse_position()
	var view = _get_view_params()
	var start_x = view["start_x"]
	var start_y = view["start_y"]
	var cam_offset = view["cam_offset"]
	var tile_x = int((viewport_pos.x + cam_offset.x) / float(tile_size)) + start_x
	var tile_y = int((viewport_pos.y + cam_offset.y) / float(tile_size)) + start_y
	if tile_x < 0 or tile_x >= _map_width or tile_y < 0 or tile_y >= _map_height:
		return Vector2i(-1, -1)
	return Vector2i(tile_x, tile_y)


func _apply_edit(tile_x: int, tile_y: int, left_click: bool, right_click: bool) -> void:
	var layers = _map_data.get("layers", {})
	var map_layer = layers.get("map", {})
	var graphics_layers = map_layer.get("graphics", [])
	var blocked = map_layer.get("blocked", [])
	var inf_layer = layers.get("inf", {})
	var exit_map = inf_layer.get("tile_exit_map", [])
	var exit_x = inf_layer.get("tile_exit_x", [])
	var exit_y = inf_layer.get("tile_exit_y", [])
	var interior = _get_interior_grid()

	match edit_tool:
		"paint":
			if edit_layer_index >= 0 and edit_layer_index < graphics_layers.size() and left_click:
				graphics_layers[edit_layer_index][tile_y][tile_x] = edit_grh_id
		"erase":
			if edit_layer_index >= 0 and edit_layer_index < graphics_layers.size():
				if left_click or right_click:
					if right_click:
						for layer_index in range(graphics_layers.size()):
							graphics_layers[layer_index][tile_y][tile_x] = 0
					else:
						graphics_layers[edit_layer_index][tile_y][tile_x] = 0
		"blocked":
			if blocked.size() > 0:
				if left_click:
					blocked[tile_y][tile_x] = 1
				elif right_click:
					blocked[tile_y][tile_x] = 0
		"exit":
			if exit_map.size() > 0:
				if left_click:
					_request_exit_target(tile_x, tile_y)
				elif right_click:
					exit_map[tile_y][tile_x] = 0
					exit_x[tile_y][tile_x] = 0
					exit_y[tile_y][tile_x] = 0
		"interior":
			if interior.size() > 0:
				if left_click:
					interior[tile_y][tile_x] = 1
				elif right_click:
					interior[tile_y][tile_x] = 0
		"eyedrop":
			if edit_layer_index >= 0 and edit_layer_index < graphics_layers.size() and left_click:
				edit_grh_id = int(graphics_layers[edit_layer_index][tile_y][tile_x])

	map_layer["graphics"] = graphics_layers
	map_layer["blocked"] = blocked
	layers["map"] = map_layer
	inf_layer["tile_exit_map"] = exit_map
	inf_layer["tile_exit_x"] = exit_x
	inf_layer["tile_exit_y"] = exit_y
	layers["inf"] = inf_layer
	if interior.size() > 0:
		var editor = layers.get("editor", {})
		editor["interior"] = interior
		layers["editor"] = editor
	_map_data["layers"] = layers
	queue_redraw()


func _request_exit_target(tile_x: int, tile_y: int) -> void:
	_pending_exit_tile = Vector2i(tile_x, tile_y)
	emit_signal("exit_tile_requested", tile_x, tile_y)


func apply_exit_target(map_id: int, spawn_x: int, spawn_y: int) -> void:
	if _pending_exit_tile.x < 0:
		return
	var tile_x = _pending_exit_tile.x
	var tile_y = _pending_exit_tile.y
	_pending_exit_tile = Vector2i(-1, -1)
	var layers = _map_data.get("layers", {})
	var inf_layer = layers.get("inf", {})
	var exit_map = inf_layer.get("tile_exit_map", [])
	var exit_x = inf_layer.get("tile_exit_x", [])
	var exit_y = inf_layer.get("tile_exit_y", [])
	if exit_map.size() == 0:
		return
	exit_map[tile_y][tile_x] = map_id
	exit_x[tile_y][tile_x] = spawn_x
	exit_y[tile_y][tile_x] = spawn_y
	inf_layer["tile_exit_map"] = exit_map
	inf_layer["tile_exit_x"] = exit_x
	inf_layer["tile_exit_y"] = exit_y
	layers["inf"] = inf_layer
	_map_data["layers"] = layers
	queue_redraw()


func cancel_exit_target() -> void:
	_pending_exit_tile = Vector2i(-1, -1)


func _save_map() -> void:
	if _map_data.is_empty():
		return
	var json = JSON.stringify(_map_data, "  ")
	if not _write_text(map_json_path, json):
		var fallback = "user://Map%d.json" % int(_map_data.get("id", 0))
		if _write_text(fallback, json):
			push_warning("Saved to %s (res:// is read-only)" % fallback)
		else:
			push_error("Failed to save map JSON.")


func _write_text(path: String, text: String) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	return true


func _try_edge_exit(x: int, y: int) -> void:
	var exits = _get_edge_exits()
	if _map_width <= 0 or _map_height <= 0:
		return

	if y <= 0 and exits["north"] > 0:
		_load_map_by_id(exits["north"], clamp(x, 0, _map_width - 1), max(0, _map_height - 6))
		return
	if y >= _map_height - 1 and exits["south"] > 0:
		_load_map_by_id(exits["south"], clamp(x, 0, _map_width - 1), min(_map_height - 1, 5))
		return
	if x <= 0 and exits["west"] > 0:
		_load_map_by_id(exits["west"], max(0, _map_width - 9), clamp(y, 0, _map_height - 1))
		return
	if x >= _map_width - 1 and exits["east"] > 0:
		_load_map_by_id(exits["east"], min(_map_width - 1, 9), clamp(y, 0, _map_height - 1))
		return


func _get_edge_exits() -> Dictionary:
	var section = _get_map_meta_section()
	return {
		"north": _get_meta_int(section, "NorthExit"),
		"south": _get_meta_int(section, "SouthExit"),
		"west": _get_meta_int(section, "WestExit"),
		"east": _get_meta_int(section, "EastExit"),
	}


func _get_map_meta_section() -> Dictionary:
	var meta = _map_data.get("meta", {})
	for section in meta.get("sections", []):
		if section.get("name", "") == "Map%d" % int(_map_data.get("id", 0)):
			return section.get("values", {})
	return {}


func _get_or_create_meta_section() -> Dictionary:
	var meta = _map_data.get("meta", {})
	var sections = meta.get("sections", [])
	var target_name = "Map%d" % int(_map_data.get("id", 0))
	for section in sections:
		if section.get("name", "") == target_name:
			if not section.has("values"):
				section["values"] = {}
			meta["sections"] = sections
			_map_data["meta"] = meta
			return section.get("values", {})
	var new_section = {"name": target_name, "values": {}}
	sections.append(new_section)
	meta["sections"] = sections
	_map_data["meta"] = meta
	return new_section["values"]


func set_edge_exit(direction: String, map_id: int) -> void:
	var values = _get_or_create_meta_section()
	var key = ""
	match direction:
		"north":
			key = "NorthExit"
		"south":
			key = "SouthExit"
		"east":
			key = "EastExit"
		"west":
			key = "WestExit"
	if key == "":
		return
	values[key] = str(map_id)
	queue_redraw()


func get_edge_exit(direction: String) -> int:
	var section = _get_map_meta_section()
	var key = ""
	match direction:
		"north":
			key = "NorthExit"
		"south":
			key = "SouthExit"
		"east":
			key = "EastExit"
		"west":
			key = "WestExit"
	if key == "":
		return 0
	return _get_meta_int(section, key)


func _get_meta_int(section: Dictionary, key: String) -> int:
	if not section.has(key):
		return 0
	var value = str(section.get(key, ""))
	if value == "":
		return 0
	var parts = value.split("-")
	var head = parts[0] if parts.size() > 0 else value
	return int(head) if head.is_valid_int() else 0


func _resolve_map_path(map_id: int) -> String:
	var filename = "Map%d.json" % map_id
	var root = map_data_root
	if root.ends_with("/"):
		root = root.substr(0, root.length() - 1)
	var candidate = "%s/%s" % [root, filename]
	if _map_path_exists(candidate):
		return candidate
	if root.begins_with("res://"):
		var project_path = ProjectSettings.globalize_path("res://")
		var alt = project_path.path_join("..").path_join("data").path_join("maps").path_join(filename)
		if FileAccess.file_exists(alt):
			return alt
	return ""


func _map_path_exists(path: String) -> bool:
	if path.begins_with("res://"):
		return ResourceLoader.exists(path)
	return FileAccess.file_exists(path)


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


func _resolve_grh_entry_at_time(grh_index: int, time: float) -> Dictionary:
	if not _grh_entries.has(grh_index):
		return {}
	var entry = _grh_entries[grh_index]
	if entry.get("num_frames", 1) > 1:
		var frames = entry.get("frames", [])
		if frames.size() > 0:
			var frame_index = _select_animation_frame_at_time(entry, frames, time)
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


func _select_animation_frame_at_time(entry: Dictionary, frames: Array, time: float) -> int:
	var num_frames = int(entry.get("num_frames", frames.size()))
	if num_frames <= 0:
		return int(frames[0])
	var speed = float(entry.get("speed", 0))
	var frame_duration = max(0.05, speed * grh_speed_scale)
	var frame = int(floor(time / frame_duration)) % num_frames
	frame = clamp(frame, 0, frames.size() - 1)
	return int(frames[frame])


func _load_ini_list(path: String) -> Dictionary:
	var data = _load_json(path)
	var map: Dictionary = {}
	for item in data.get("items", []):
		if item.has("id"):
			map[int(item["id"])] = item.get("values", {})
	return map


func _get_body_walk_grh(body_id: int, direction: int) -> int:
	var entry = _body_entries.get(body_id, {})
	if entry.is_empty():
		return 0
	var key = DIR_KEYS[clamp(direction, 0, DIR_KEYS.size() - 1)]
	return int(entry.get(key, 0))


func _get_head_walk_grh(head_id: int, direction: int) -> int:
	var entry = _head_entries.get(head_id, {})
	if entry.is_empty():
		return 0
	var key = HEAD_KEYS[clamp(direction, 0, HEAD_KEYS.size() - 1)]
	return int(entry.get(key, 0))


func _get_weapon_walk_grh(weapon_anim_id: int, direction: int) -> int:
	if weapon_anim_id <= 0:
		return 0
	var entry = _weapon_anim_entries.get(weapon_anim_id, {})
	if entry.is_empty():
		return 0
	var key = WEAPON_KEYS[clamp(direction, 0, WEAPON_KEYS.size() - 1)]
	return int(entry.get(key, 0))


func _get_equipped_weapon_anim_id() -> int:
	if _equipped_weapon_index < 0 or _equipped_weapon_index >= _inventory.size():
		return 0
	var item = _inventory[_equipped_weapon_index]
	return int(item.get("weapon_anim_id", 0))


func _get_equipped_weapon_icon_grh() -> int:
	if _equipped_weapon_index < 0 or _equipped_weapon_index >= _inventory.size():
		return 0
	var item = _inventory[_equipped_weapon_index]
	return int(item.get("icon_grh", 0))


func _get_equipped_weapon_grh() -> int:
	if _equipped_weapon_index < 0 or _equipped_weapon_index >= _inventory.size():
		return 0
	var item = _inventory[_equipped_weapon_index]
	return int(item.get("weapon_grh", 0))


func _has_weapon_equipped() -> bool:
	if _equipped_weapon_index < 0 or _equipped_weapon_index >= _inventory.size():
		return false
	var item = _inventory[_equipped_weapon_index]
	if int(item.get("weapon_anim_id", 0)) > 0:
		return true
	if int(item.get("weapon_grh", 0)) > 0:
		return true
	if int(item.get("icon_grh", 0)) > 0:
		return true
	return false


func _get_equipped_weapon_frame() -> int:
	if _equipped_weapon_index < 0 or _equipped_weapon_index >= _inventory.size():
		return 0
	var item = _inventory[_equipped_weapon_index]
	var frames = item.get("weapon_frames", [])
	if frames.size() == 0:
		return 0
	return _select_item_frame(frames, _weapon_anim_time, weapon_frame_fps)


func _select_item_frame(frames: Array, time: float, fps: float) -> int:
	if frames.size() == 0:
		return 0
	var rate = max(1.0, fps)
	var frame = int(floor(time * rate)) % frames.size()
	return int(frames[frame])


func _get_weapon_offset(direction: int, attacking: bool) -> Vector2:
	var base = Vector2.ZERO
	match direction:
		0:
			base = weapon_hold_offset_n
		1:
			base = weapon_hold_offset_e
		2:
			base = weapon_hold_offset_s
		3:
			base = weapon_hold_offset_w
	if not attacking:
		return base
	var progress = 1.0 - clamp(_attack_timer / max(0.001, attack_duration), 0.0, 1.0)
	var swing = Vector2.ZERO
	match direction:
		0:
			swing = weapon_swing_offset_n
		1:
			swing = weapon_swing_offset_e
		2:
			swing = weapon_swing_offset_s
		3:
			swing = weapon_swing_offset_w
	return base + swing * progress


func _get_body_head_offset(body_id: int, fallback: Vector2) -> Vector2:
	var entry = _body_entries.get(body_id, {})
	if entry.is_empty():
		return fallback
	var x = float(entry.get("HeadoffsetX", fallback.x))
	var y = float(entry.get("HeadoffsetY", fallback.y))
	return Vector2(x, y)


func _update_player_direction(move: Vector2) -> void:
	if abs(move.x) > abs(move.y):
		_player_dir = 1 if move.x > 0 else 3
	else:
		_player_dir = 2 if move.y > 0 else 0


func _get_texture(file_num: int) -> Texture2D:
	if _texture_cache.has(file_num):
		return _texture_cache[file_num]

	var texture: Texture2D = null
	var candidates = _build_candidate_paths(file_num)
	for path in candidates:
		var img: Image = null
		if path.begins_with("res://"):
			if not ResourceLoader.exists(path):
				continue
			var tex_res = load(path)
			if tex_res is Texture2D:
				img = tex_res.get_image()
		else:
			if not FileAccess.file_exists(path):
				continue
			var raw = Image.new()
			var err = raw.load(path)
			if err == OK:
				img = raw

		if img == null or img.is_empty():
			continue
		if img.get_format() != Image.FORMAT_RGBA8:
			img.convert(Image.FORMAT_RGBA8)
		var mask = _load_mask_image(file_num)
		if mask != null:
			if mask.get_format() != Image.FORMAT_RGBA8:
				mask.convert(Image.FORMAT_RGBA8)
			_apply_mask_alpha(img, mask)
		elif apply_color_key:
			_apply_black_colorkey(img)
		if debug_color_key and debug_color_key_file > 0 and file_num == debug_color_key_file:
			_log_alpha_stats(file_num, img)
		texture = ImageTexture.create_from_image(img)
		if texture != null:
			break

	_texture_cache[file_num] = texture
	return texture


func _get_texture_with_alpha_floor(file_num: int, floor_alpha: float) -> Texture2D:
	var key = "%d|%.2f" % [file_num, floor_alpha]
	if _texture_cache_floor.has(key):
		return _texture_cache_floor[key]

	var texture: Texture2D = null
	var candidates = _build_candidate_paths(file_num)
	for path in candidates:
		var img: Image = null
		if path.begins_with("res://"):
			if not ResourceLoader.exists(path):
				continue
			var tex_res = load(path)
			if tex_res is Texture2D:
				img = tex_res.get_image()
		else:
			if not FileAccess.file_exists(path):
				continue
			var raw = Image.new()
			var err = raw.load(path)
			if err == OK:
				img = raw

		if img == null or img.is_empty():
			continue
		if img.get_format() != Image.FORMAT_RGBA8:
			img.convert(Image.FORMAT_RGBA8)
		var mask = _load_mask_image(file_num)
		if mask != null:
			if mask.get_format() != Image.FORMAT_RGBA8:
				mask.convert(Image.FORMAT_RGBA8)
			_apply_mask_alpha(img, mask)
		elif apply_color_key:
			_apply_black_colorkey(img)
		_apply_alpha_floor(img, floor_alpha)
		texture = ImageTexture.create_from_image(img)
		if texture != null:
			break

	_texture_cache_floor[key] = texture
	return texture


func _apply_alpha_floor(img: Image, floor_alpha: float) -> void:
	var size = img.get_size()
	var floor = clamp(floor_alpha, 0.0, 1.0)
	for y in range(size.y):
		for x in range(size.x):
			var c = img.get_pixel(x, y)
			if c.a < floor:
				c.a = floor
				img.set_pixel(x, y, c)


func _build_candidate_paths(file_num: int) -> Array:
	var base = asset_root
	if base.ends_with("/"):
		base = base.substr(0, base.length() - 1)
	var paths = []
	paths.append("%s/Grh%d.png" % [base, file_num])
	paths.append("%s/grh%d.png" % [base, file_num])
	paths.append("%s/GRH%d.PNG" % [base, file_num])
	paths.append("%s/Grh%d.bmp" % [base, file_num])
	paths.append("%s/grh%d.bmp" % [base, file_num])
	paths.append("%s/GRH%d.BMP" % [base, file_num])
	paths.append("%s/grh%dM.bmp" % [base, file_num])
	paths.append("%s/GRH%dM.BMP" % [base, file_num])
	return paths


func _build_mask_paths(file_num: int) -> Array:
	var base = asset_root
	if base.ends_with("/"):
		base = base.substr(0, base.length() - 1)
	var paths = []
	paths.append("%s/Grh%dM.png" % [base, file_num])
	paths.append("%s/grh%dM.png" % [base, file_num])
	paths.append("%s/GRH%dM.PNG" % [base, file_num])
	paths.append("%s/Grh%dM.bmp" % [base, file_num])
	paths.append("%s/grh%dM.bmp" % [base, file_num])
	paths.append("%s/GRH%dM.BMP" % [base, file_num])
	return paths


func _load_mask_image(file_num: int) -> Image:
	var candidates = _build_mask_paths(file_num)
	for path in candidates:
		if path.begins_with("res://"):
			if not ResourceLoader.exists(path):
				continue
		else:
			if not FileAccess.file_exists(path):
				continue

		var img = Image.new()
		var err = img.load(path)
		if err == OK:
			return img
	return null


func _apply_mask_alpha(img: Image, mask: Image) -> void:
	var size = img.get_size()
	if mask.get_size() != size:
		mask.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
	for y in range(size.y):
		for x in range(size.x):
			var c = img.get_pixel(x, y)
			var m = mask.get_pixel(x, y)
			var lum = (m.r + m.g + m.b) / 3.0
			c.a = clamp(1.0 - lum, 0.0, 1.0)
			img.set_pixel(x, y, c)


func _apply_black_colorkey(img: Image) -> void:
	var key = _get_color_key(img)
	if flood_fill_background:
		_apply_colorkey_flood(img, key, color_key_tolerance)
		if color_key_mode == "auto" and _border_has_magenta(img):
			_apply_colorkey_flood(img, Color(1.0, 0.0, 1.0), color_key_tolerance)
		return

	var size = img.get_size()
	for y in range(size.y):
		for x in range(size.x):
			var c = img.get_pixel(x, y)
			if _color_near(c, key, color_key_tolerance):
				img.set_pixel(x, y, Color(0, 0, 0, 0))


func _get_color_key(img: Image) -> Color:
	match color_key_mode:
		"topleft":
			return img.get_pixel(0, 0)
		"magenta":
			return Color(1.0, 0.0, 1.0)
		"black":
			return Color(0.0, 0.0, 0.0)
		"custom":
			return custom_color_key
		_:
			return _auto_color_key(img)


func _auto_color_key(img: Image) -> Color:
	var size = img.get_size()
	if size.x <= 1 or size.y <= 1:
		return img.get_pixel(0, 0)

	var counts: Dictionary = {}
	var total = 0

	for x in range(size.x):
		_accum_color(img.get_pixel(x, 0), counts)
		_accum_color(img.get_pixel(x, size.y - 1), counts)
		total += 2

	for y in range(1, size.y - 1):
		_accum_color(img.get_pixel(0, y), counts)
		_accum_color(img.get_pixel(size.x - 1, y), counts)
		total += 2

	var best_key = img.get_pixel(0, 0)
	var best_count = 0
	for key in counts.keys():
		var count = int(counts[key])
		if count > best_count:
			best_count = count
			best_key = _unpack_color(int(key))

	if total > 0 and float(best_count) / float(total) >= 0.25:
		return best_key

	return img.get_pixel(0, 0)


func _accum_color(color: Color, counts: Dictionary) -> void:
	var key = _pack_color(color)
	if counts.has(key):
		counts[key] = int(counts[key]) + 1
	else:
		counts[key] = 1


func _pack_color(color: Color) -> int:
	var r = int(clamp(round(color.r * 255.0), 0.0, 255.0))
	var g = int(clamp(round(color.g * 255.0), 0.0, 255.0))
	var b = int(clamp(round(color.b * 255.0), 0.0, 255.0))
	return (r << 16) | (g << 8) | b


func _unpack_color(key: int) -> Color:
	var r = float((key >> 16) & 0xFF) / 255.0
	var g = float((key >> 8) & 0xFF) / 255.0
	var b = float(key & 0xFF) / 255.0
	return Color(r, g, b)


func _color_near(a: Color, b: Color, tol: float) -> bool:
	return abs(a.r - b.r) <= tol and abs(a.g - b.g) <= tol and abs(a.b - b.b) <= tol


func _color_key_settings_changed() -> bool:
	var current = {
		"apply_color_key": apply_color_key,
		"color_key_tolerance": color_key_tolerance,
		"color_key_mode": color_key_mode,
		"custom_color_key": custom_color_key,
		"flood_fill_background": flood_fill_background,
		"edit_alpha_preview": edit_alpha_preview,
		"edit_alpha_floor": edit_alpha_floor,
	}
	if _last_color_key_settings.is_empty():
		_last_color_key_settings = current
		return false
	for key in current.keys():
		if _last_color_key_settings.get(key) != current[key]:
			_last_color_key_settings = current
			return true
	return false


func _log_alpha_stats(file_num: int, img: Image) -> void:
	var size = img.get_size()
	var total = size.x * size.y
	var transparent = 0
	for y in range(size.y):
		for x in range(size.x):
			if img.get_pixel(x, y).a <= 0.01:
				transparent += 1
	var pct = 0.0
	if total > 0:
		pct = float(transparent) / float(total) * 100.0
	print("GRH file %d alpha: %d/%d (%.1f%%) format=%d" % [file_num, transparent, total, pct, img.get_format()])


func _border_has_magenta(img: Image) -> bool:
	var size = img.get_size()
	if size.x == 0 or size.y == 0:
		return false
	var magenta = Color(1.0, 0.0, 1.0)
	var hit = 0
	var total = 0
	for x in range(size.x):
		total += 1
		if _color_near(img.get_pixel(x, 0), magenta, color_key_tolerance):
			hit += 1
		total += 1
		if _color_near(img.get_pixel(x, size.y - 1), magenta, color_key_tolerance):
			hit += 1
	for y in range(1, size.y - 1):
		total += 1
		if _color_near(img.get_pixel(0, y), magenta, color_key_tolerance):
			hit += 1
		total += 1
		if _color_near(img.get_pixel(size.x - 1, y), magenta, color_key_tolerance):
			hit += 1
	if total == 0:
		return false
	return float(hit) / float(total) >= 0.05


func _apply_colorkey_flood(img: Image, key: Color, tol: float) -> void:
	var size = img.get_size()
	if size.x == 0 or size.y == 0:
		return

	var width = size.x
	var height = size.y
	var visited = PackedByteArray()
	visited.resize(width * height)
	var queue: Array = []
	var idx = 0

	for x in range(width):
		_enqueue_colorkey(img, visited, queue, x, 0, key, tol)
		if height > 1:
			_enqueue_colorkey(img, visited, queue, x, height - 1, key, tol)

	for y in range(1, height - 1):
		_enqueue_colorkey(img, visited, queue, 0, y, key, tol)
		if width > 1:
			_enqueue_colorkey(img, visited, queue, width - 1, y, key, tol)

	while idx < queue.size():
		var pos = int(queue[idx])
		idx += 1
		var x = pos % width
		var y = pos / width
		var c = img.get_pixel(x, y)
		c.a = 0.0
		img.set_pixel(x, y, c)

		var nx = x - 1
		var ny = y
		_enqueue_colorkey(img, visited, queue, nx, ny, key, tol)
		nx = x + 1
		_enqueue_colorkey(img, visited, queue, nx, ny, key, tol)
		nx = x
		ny = y - 1
		_enqueue_colorkey(img, visited, queue, nx, ny, key, tol)
		ny = y + 1
		_enqueue_colorkey(img, visited, queue, nx, ny, key, tol)


func _enqueue_colorkey(img: Image, visited: PackedByteArray, queue: Array, x: int, y: int, key: Color, tol: float) -> void:
	var size = img.get_size()
	if x < 0 or y < 0 or x >= size.x or y >= size.y:
		return
	var width = size.x
	var index = y * width + x
	if visited[index] == 1:
		return
	if not _color_near(img.get_pixel(x, y), key, tol):
		return
	visited[index] = 1
	queue.append(index)


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


func get_inventory_items() -> Array:
	return _inventory


func get_equipped_weapon_name() -> String:
	if _equipped_weapon_index < 0 or _equipped_weapon_index >= _inventory.size():
		return "None"
	var item = _inventory[_equipped_weapon_index]
	return str(item.get("name", "Unknown"))


func equip_item(index: int) -> void:
	if index < 0 or index >= _inventory.size():
		_equipped_weapon_index = -1
		return
	if _equipped_weapon_index == index:
		_equipped_weapon_index = -1
	else:
		_equipped_weapon_index = index
	_weapon_anim_time = 0.0


func _ensure_starter_items() -> void:
	if not starter_sword_enabled:
		return
	if _inventory.size() > 0:
		return
	var sword = {
		"id": "starter_sword",
		"name": "Rusty Sword",
		"type": "weapon",
		"damage": 3,
		"icon_grh": 5009,
		"weapon_grh": 0,
		"weapon_anim_id": 1
	}
	_inventory.append(sword)
	_equipped_weapon_index = 0


func get_grh_preview_texture(grh_id: int) -> Texture2D:
	var entry = _resolve_grh_entry(grh_id)
	if entry.is_empty():
		return null
	if not entry.has("file_num"):
		return null
	var file_num = int(entry["file_num"])
	return _get_texture(file_num)


func get_grh_icon_texture(grh_id: int) -> Texture2D:
	if grh_id <= 0:
		return null
	if _icon_texture_cache.has(grh_id):
		return _icon_texture_cache[grh_id]

	var entry = _resolve_icon_entry(grh_id)
	if entry.is_empty() or not entry.has("file_num"):
		return null
	var file_num = int(entry["file_num"])
	var texture = _get_texture(file_num)
	if texture == null:
		return null

	var sx = int(entry.get("sx", 0))
	var sy = int(entry.get("sy", 0))
	var w = int(entry.get("pixel_width", tile_size))
	var h = int(entry.get("pixel_height", tile_size))
	var img = texture.get_image()
	var rect = Rect2i(sx, sy, w, h)
	if rect.position.x < 0 or rect.position.y < 0:
		return null
	if rect.position.x + rect.size.x > img.get_width() or rect.position.y + rect.size.y > img.get_height():
		return null
	var sub = img.get_region(rect)
	var icon_tex = ImageTexture.create_from_image(sub)
	_icon_texture_cache[grh_id] = icon_tex
	return icon_tex


func _resolve_icon_entry(grh_id: int) -> Dictionary:
	if not _grh_entries.has(grh_id):
		return {}
	var entry = _grh_entries[grh_id]
	if entry.get("num_frames", 1) > 1:
		var frames = entry.get("frames", [])
		if frames.size() > 0 and _grh_entries.has(int(frames[0])):
			return _grh_entries[int(frames[0])]
	return entry


func get_grh_preview_info(grh_id: int) -> String:
	var entry = _resolve_grh_entry(grh_id)
	if entry.is_empty():
		return "Grh %d (missing)" % grh_id
	if not entry.has("file_num"):
		return "Grh %d (no file)" % grh_id
	var file_num = int(entry["file_num"])
	var w = int(entry.get("pixel_width", tile_size))
	var h = int(entry.get("pixel_height", tile_size))
	return "Grh %d -> File %d (%dx%d)" % [grh_id, file_num, w, h]


func get_grh_ids() -> Array:
	var ids: Array = []
	for key in _grh_entries.keys():
		ids.append(int(key))
	ids.sort()
	return ids


func get_grh_entry_info(grh_id: int) -> Dictionary:
	if not _grh_entries.has(grh_id):
		return {}
	return _grh_entries[grh_id]


func get_grh_frames(grh_id: int) -> Array:
	if not _grh_entries.has(grh_id):
		return []
	var entry = _grh_entries[grh_id]
	if entry.is_empty():
		return []
	if int(entry.get("num_frames", 1)) > 1:
		return entry.get("frames", [])
	return [grh_id]


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


func _find_overlapping_grh(tile_x: int, tile_y: int) -> Dictionary:
	if _map_data.is_empty():
		return {}
	var layers = _map_data.get("layers", {})
	var map_layer = layers.get("map", {})
	var graphics_layers = map_layer.get("graphics", [])
	if graphics_layers.size() == 0:
		return {}

	var target = Vector2(tile_x * tile_size + 1, tile_y * tile_size + 1)
	for layer_index in range(graphics_layers.size() - 1, -1, -1):
		var layer = graphics_layers[layer_index]
		for y in range(_map_height):
			var row = layer[y]
			for x in range(_map_width):
				var grh_index = int(row[x])
				if grh_index <= 0:
					continue
				var entry = _resolve_grh_entry(grh_index)
				if entry.is_empty() or not entry.has("file_num"):
					continue
				var w = int(entry.get("pixel_width", tile_size))
				var h = int(entry.get("pixel_height", tile_size))
				var tile_w = float(entry.get("tile_width", 1.0))
				var tile_h = float(entry.get("tile_height", 1.0))
				var dest_pos = Vector2(x * tile_size, y * tile_size)
				if tile_w != 1.0:
					dest_pos.x -= int(tile_w * float(tile_size) * 0.5) - int(float(tile_size) * 0.5)
				if tile_h != 1.0:
					dest_pos.y -= int(tile_h * float(tile_size)) - tile_size
				var rect = Rect2(dest_pos, Vector2(w, h))
				if rect.has_point(target):
					return {
						"layer": layer_index,
						"grh": grh_index,
						"anchor": Vector2i(x, y)
					}
	return {}


func _color_from_id(value: int) -> Color:
	var r = float((value * 73) % 255) / 255.0
	var g = float((value * 151) % 255) / 255.0
	var b = float((value * 199) % 255) / 255.0
	return Color(r, g, b, 1.0)
