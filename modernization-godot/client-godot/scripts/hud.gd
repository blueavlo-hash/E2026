extends CanvasLayer

@onready var _viewer: Node = get_parent().get_node("MapViewer")
@onready var _info: Label = $Panel/VBox/Info
@onready var _toggles: Label = $Panel/VBox/Toggles
@onready var _editor_info: Label = $Panel/VBox/EditorInfo
@onready var _music_toggle: Button = $Panel/VBox/MusicToggle
@onready var _volume_slider: HSlider = $Panel/VBox/VolumeSlider
@onready var _editor_button: Button = $Panel/VBox/EditorButton
@onready var _inventory_button: Button = $Panel/VBox/InventoryButton
@onready var _sprite_button: Button = $Panel/VBox/SpriteBrowserButton
@onready var _editor_window: Window = get_parent().get_node("EditorWindow")
@onready var _inventory_window: Window = get_parent().get_node("InventoryWindow")
@onready var _sprite_window: Window = get_parent().get_node("SpriteBrowserWindow")
@onready var _edit_toggle: CheckBox = _editor_window.get_node("EditorPanel/EditorVBox/EditEnabled")
@onready var _tool_select: OptionButton = _editor_window.get_node("EditorPanel/EditorVBox/ToolSelect")
@onready var _layer_spin: SpinBox = _editor_window.get_node("EditorPanel/EditorVBox/EditorGrid/LayerSpin")
@onready var _grh_spin: SpinBox = _editor_window.get_node("EditorPanel/EditorVBox/EditorGrid/GrhSpin")
@onready var _grh_preview: TextureRect = _editor_window.get_node("EditorPanel/EditorVBox/EditorGrid/GrhPreview")
@onready var _grh_preview_info: Label = _editor_window.get_node("EditorPanel/EditorVBox/EditorGrid/GrhPreviewInfo")
@onready var _exit_map_spin: SpinBox = _editor_window.get_node("EditorPanel/EditorVBox/EditorGrid/ExitMapSpin")
@onready var _exit_x_spin: SpinBox = _editor_window.get_node("EditorPanel/EditorVBox/EditorGrid/ExitXSpin")
@onready var _exit_y_spin: SpinBox = _editor_window.get_node("EditorPanel/EditorVBox/EditorGrid/ExitYSpin")
@onready var _roof_layer_spin: SpinBox = _editor_window.get_node("EditorPanel/EditorVBox/EditorGrid/RoofLayerSpin")
@onready var _show_layer_1: CheckBox = _editor_window.get_node("EditorPanel/EditorVBox/LayerToggles/ShowLayer1")
@onready var _show_layer_2: CheckBox = _editor_window.get_node("EditorPanel/EditorVBox/LayerToggles/ShowLayer2")
@onready var _show_layer_3: CheckBox = _editor_window.get_node("EditorPanel/EditorVBox/LayerToggles/ShowLayer3")
@onready var _show_layer_4: CheckBox = _editor_window.get_node("EditorPanel/EditorVBox/LayerToggles/ShowLayer4")
@onready var _blocked_overlay: CheckBox = _editor_window.get_node("EditorPanel/EditorVBox/BlockedOverlayToggle")
@onready var _exit_overlay: CheckBox = _editor_window.get_node("EditorPanel/EditorVBox/ExitOverlayToggle")
@onready var _roof_fade_toggle: CheckBox = _editor_window.get_node("EditorPanel/EditorVBox/RoofFadeToggle")
@onready var _alpha_preview_toggle: CheckBox = _editor_window.get_node("EditorPanel/EditorVBox/AlphaPreviewRow/AlphaPreviewToggle")
@onready var _alpha_preview_spin: SpinBox = _editor_window.get_node("EditorPanel/EditorVBox/AlphaPreviewRow/AlphaPreviewSpin")
@onready var _north_exit_spin: SpinBox = _editor_window.get_node("EditorPanel/EditorVBox/EdgeGrid/NorthExitSpin")
@onready var _south_exit_spin: SpinBox = _editor_window.get_node("EditorPanel/EditorVBox/EdgeGrid/SouthExitSpin")
@onready var _west_exit_spin: SpinBox = _editor_window.get_node("EditorPanel/EditorVBox/EdgeGrid/WestExitSpin")
@onready var _east_exit_spin: SpinBox = _editor_window.get_node("EditorPanel/EditorVBox/EdgeGrid/EastExitSpin")
@onready var _apply_edge_button: Button = _editor_window.get_node("EditorPanel/EditorVBox/ApplyEdgeExits")
@onready var _save_button: Button = _editor_window.get_node("EditorPanel/EditorVBox/SaveButton")
@onready var _exit_dialog: AcceptDialog = _editor_window.get_node("ExitDialog")
@onready var _exit_dialog_map: SpinBox = _editor_window.get_node("ExitDialog/ExitDialogVBox/ExitDialogGrid/ExitDialogMapSpin")
@onready var _exit_dialog_x: SpinBox = _editor_window.get_node("ExitDialog/ExitDialogVBox/ExitDialogGrid/ExitDialogXSpin")
@onready var _exit_dialog_y: SpinBox = _editor_window.get_node("ExitDialog/ExitDialogVBox/ExitDialogGrid/ExitDialogYSpin")
@onready var _inventory_grid: GridContainer = _inventory_window.get_node("InventoryPanel/InventoryVBox/InventoryGrid")
@onready var _selected_label: Label = _inventory_window.get_node("InventoryPanel/InventoryVBox/SelectedLabel")
@onready var _equip_button: Button = _inventory_window.get_node("InventoryPanel/InventoryVBox/EquipButton")
@onready var _equipped_label: Label = _inventory_window.get_node("InventoryPanel/InventoryVBox/EquippedLabel")
@onready var _sprite_search: LineEdit = _sprite_window.get_node("SpriteBrowserPanel/SpriteBrowserVBox/SpriteSearch")
@onready var _sprite_list: ItemList = _sprite_window.get_node("SpriteBrowserPanel/SpriteBrowserVBox/SpriteContent/SpriteList")
@onready var _sprite_preview: TextureRect = _sprite_window.get_node("SpriteBrowserPanel/SpriteBrowserVBox/SpriteContent/SpritePreviewVBox/SpritePreview")
@onready var _sprite_info: Label = _sprite_window.get_node("SpriteBrowserPanel/SpriteBrowserVBox/SpriteContent/SpritePreviewVBox/SpriteInfo")
@onready var _sprite_frames: Label = _sprite_window.get_node("SpriteBrowserPanel/SpriteBrowserVBox/SpriteContent/SpritePreviewVBox/SpriteFrames")
@onready var _sprite_frame_list: ItemList = _sprite_window.get_node("SpriteBrowserPanel/SpriteBrowserVBox/SpriteContent/SpritePreviewVBox/SpriteFrameList")
@onready var _sprite_play: CheckBox = _sprite_window.get_node("SpriteBrowserPanel/SpriteBrowserVBox/SpriteControls/SpritePlayToggle")
@onready var _sprite_fps: SpinBox = _sprite_window.get_node("SpriteBrowserPanel/SpriteBrowserVBox/SpriteControls/SpriteFpsSpin")
@onready var _sprite_prev: Button = _sprite_window.get_node("SpriteBrowserPanel/SpriteBrowserVBox/SpriteControls/SpritePrev")
@onready var _sprite_next: Button = _sprite_window.get_node("SpriteBrowserPanel/SpriteBrowserVBox/SpriteControls/SpriteNext")
@onready var _sprite_frame_spin: SpinBox = _sprite_window.get_node("SpriteBrowserPanel/SpriteBrowserVBox/SpriteControls/SpriteFrameSpin")

var _last_preview_grh: int = -1
var _inventory_slots: Array = []
var _selected_inventory_index: int = -1
var _ui_time: float = 0.0
var _sprite_ids: Array = []
var _sprite_selected_id: int = -1
var _sprite_frames_list: Array = []
var _sprite_time: float = 0.0
var _sprite_frame_index: int = 0

const INVENTORY_SLOTS := 16
const ICON_FPS := 6.0


func _ready() -> void:
	_music_toggle.pressed.connect(_on_music_toggle)
	_volume_slider.value_changed.connect(_on_volume_changed)
	_editor_button.pressed.connect(_on_editor_toggle)
	_inventory_button.pressed.connect(_on_inventory_toggle)
	_sprite_button.pressed.connect(_on_sprite_toggle)
	_editor_window.close_requested.connect(_on_editor_close_requested)
	_inventory_window.close_requested.connect(_on_inventory_close_requested)
	_sprite_window.close_requested.connect(_on_sprite_close_requested)
	_apply_edge_button.pressed.connect(_on_apply_edge_exits)
	_save_button.pressed.connect(_on_save_map)
	_edit_toggle.toggled.connect(_on_edit_toggle)
	_tool_select.item_selected.connect(_on_tool_selected)
	_layer_spin.value_changed.connect(_on_layer_changed)
	_grh_spin.value_changed.connect(_on_grh_changed)
	_exit_map_spin.value_changed.connect(_on_exit_map_changed)
	_exit_x_spin.value_changed.connect(_on_exit_x_changed)
	_exit_y_spin.value_changed.connect(_on_exit_y_changed)
	_roof_layer_spin.value_changed.connect(_on_roof_layer_changed)
	_show_layer_1.toggled.connect(_on_show_layer_1)
	_show_layer_2.toggled.connect(_on_show_layer_2)
	_show_layer_3.toggled.connect(_on_show_layer_3)
	_show_layer_4.toggled.connect(_on_show_layer_4)
	_blocked_overlay.toggled.connect(_on_blocked_overlay)
	_exit_overlay.toggled.connect(_on_exit_overlay)
	_roof_fade_toggle.toggled.connect(_on_roof_fade_toggle)
	_alpha_preview_toggle.toggled.connect(_on_alpha_preview_toggle)
	_alpha_preview_spin.value_changed.connect(_on_alpha_preview_value)
	_viewer.connect("exit_tile_requested", _on_exit_tile_requested)
	_exit_dialog.confirmed.connect(_on_exit_dialog_confirmed)
	_exit_dialog.canceled.connect(_on_exit_dialog_canceled)
	_equip_button.pressed.connect(_on_equip_pressed)
	_sprite_search.text_changed.connect(_on_sprite_search_changed)
	_sprite_list.item_selected.connect(_on_sprite_selected)
	_sprite_prev.pressed.connect(_on_sprite_prev)
	_sprite_next.pressed.connect(_on_sprite_next)
	_sprite_frame_spin.value_changed.connect(_on_sprite_frame_spin)
	_sprite_play.toggled.connect(_on_sprite_play_toggled)
	_sprite_frame_list.item_selected.connect(_on_sprite_frame_selected)
	_tool_select.clear()
	_tool_select.add_item("paint")
	_tool_select.add_item("erase")
	_tool_select.add_item("blocked")
	_tool_select.add_item("exit")
	_tool_select.add_item("interior")
	_tool_select.add_item("eyedrop")
	_build_inventory_slots()
	_build_sprite_list()
	set_process(true)
	set_process_input(true)


func _process(_delta: float) -> void:
	if _viewer == null:
		return
	_ui_time += _delta
	_sprite_time += _delta

	var map_id = _viewer.call("get_map_id")
	var music_index = _viewer.call("get_music_index")
	var rain = _viewer.call("is_rain_layer_enabled")
	var blocked = _viewer.call("is_blocked_overlay_enabled")
	var music_playing = _viewer.call("is_music_playing")
	var edit_enabled = _viewer.get("edit_enabled")
	var edit_tool = _viewer.get("edit_tool")
	var edit_layer = _viewer.get("edit_layer_index")
	var edit_grh = _viewer.get("edit_grh_id")
	var exit_map = _viewer.get("edit_exit_map")
	var exit_x = _viewer.get("edit_exit_x")
	var exit_y = _viewer.get("edit_exit_y")

	_info.text = "Map: %s | Music: %s" % [str(map_id), str(music_index)]
	_toggles.text = "Rain: %s | Blocked: %s" % [str(rain), str(blocked)]
	_editor_info.text = "Edit: %s | Tool: %s | L:%d | Grh:%d | Exit:%d %d,%d" % [
		str(edit_enabled), str(edit_tool), int(edit_layer + 1), int(edit_grh), int(exit_map), int(exit_x), int(exit_y)
	]
	_music_toggle.text = "Music: %s" % ("Stop" if music_playing else "Play")
	_sync_editor_ui()
	_sync_inventory_ui()
	_sync_sprite_preview()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F8:
			_toggle_editor_window()
		elif event.keycode == KEY_I:
			_toggle_inventory_window()
		elif event.keycode == KEY_B:
			_toggle_sprite_window()


func _on_music_toggle() -> void:
	if _viewer == null:
		return
	_viewer.call("toggle_music")


func _on_volume_changed(value: float) -> void:
	if _viewer == null:
		return
	_viewer.call("set_music_volume", float(value))


func _on_editor_toggle() -> void:
	_toggle_editor_window()


func _on_editor_close_requested() -> void:
	_editor_window.visible = false


func _toggle_editor_window() -> void:
	_editor_window.visible = not _editor_window.visible
	if _editor_window.visible:
		_editor_window.grab_focus()


func _on_inventory_toggle() -> void:
	_toggle_inventory_window()


func _on_inventory_close_requested() -> void:
	_inventory_window.visible = false


func _toggle_inventory_window() -> void:
	_inventory_window.visible = not _inventory_window.visible
	if _inventory_window.visible:
		_inventory_window.grab_focus()


func _on_sprite_toggle() -> void:
	_toggle_sprite_window()


func _on_sprite_close_requested() -> void:
	_sprite_window.visible = false


func _toggle_sprite_window() -> void:
	_sprite_window.visible = not _sprite_window.visible
	if _sprite_window.visible:
		_sprite_window.grab_focus()


func _sync_editor_ui() -> void:
	if _viewer == null:
		return
	var edit_enabled = bool(_viewer.get("edit_enabled"))
	if _edit_toggle.button_pressed != edit_enabled:
		_edit_toggle.button_pressed = edit_enabled

	var edit_tool = str(_viewer.get("edit_tool"))
	var tool_index = -1
	for i in range(_tool_select.get_item_count()):
		if _tool_select.get_item_text(i) == edit_tool:
			tool_index = i
			break
	if tool_index >= 0 and _tool_select.selected != tool_index:
		_tool_select.select(tool_index)

	var layer_index = int(_viewer.get("edit_layer_index")) + 1
	if not _layer_spin.has_focus() and int(_layer_spin.value) != layer_index:
		_layer_spin.value = layer_index

	var grh_id = int(_viewer.get("edit_grh_id"))
	if not _grh_spin.has_focus() and int(_grh_spin.value) != grh_id:
		_grh_spin.value = grh_id
	if _last_preview_grh != grh_id:
		_last_preview_grh = grh_id
		_grh_preview.texture = _viewer.call("get_grh_preview_texture", grh_id)
		_grh_preview_info.text = str(_viewer.call("get_grh_preview_info", grh_id))

	var exit_map = int(_viewer.get("edit_exit_map"))
	if not _exit_map_spin.has_focus() and int(_exit_map_spin.value) != exit_map:
		_exit_map_spin.value = exit_map

	var exit_x = int(_viewer.get("edit_exit_x"))
	if not _exit_x_spin.has_focus() and int(_exit_x_spin.value) != exit_x:
		_exit_x_spin.value = exit_x

	var exit_y = int(_viewer.get("edit_exit_y"))
	if not _exit_y_spin.has_focus() and int(_exit_y_spin.value) != exit_y:
		_exit_y_spin.value = exit_y

	var roof_layer = int(_viewer.get("roof_layer_index")) + 1
	if not _roof_layer_spin.has_focus() and int(_roof_layer_spin.value) != roof_layer:
		_roof_layer_spin.value = roof_layer

	var show_1 = bool(_viewer.get("show_layer_1"))
	if _show_layer_1.button_pressed != show_1:
		_show_layer_1.button_pressed = show_1
	var show_2 = bool(_viewer.get("show_layer_2"))
	if _show_layer_2.button_pressed != show_2:
		_show_layer_2.button_pressed = show_2
	var show_3 = bool(_viewer.get("show_layer_3"))
	if _show_layer_3.button_pressed != show_3:
		_show_layer_3.button_pressed = show_3
	var show_4 = bool(_viewer.get("show_layer_4"))
	if _show_layer_4.button_pressed != show_4:
		_show_layer_4.button_pressed = show_4

	var blocked_overlay = bool(_viewer.get("show_blocked_overlay"))
	if _blocked_overlay.button_pressed != blocked_overlay:
		_blocked_overlay.button_pressed = blocked_overlay
	var exit_overlay = bool(_viewer.get("show_exit_overlay"))
	if _exit_overlay.button_pressed != exit_overlay:
		_exit_overlay.button_pressed = exit_overlay
	var roof_fade = bool(_viewer.get("roof_fade_enabled"))
	if _roof_fade_toggle.button_pressed != roof_fade:
		_roof_fade_toggle.button_pressed = roof_fade
	var alpha_preview = bool(_viewer.get("edit_alpha_preview"))
	if _alpha_preview_toggle.button_pressed != alpha_preview:
		_alpha_preview_toggle.button_pressed = alpha_preview
	var alpha_floor = float(_viewer.get("edit_alpha_floor"))
	if not _alpha_preview_spin.has_focus() and abs(_alpha_preview_spin.value - alpha_floor) > 0.001:
		_alpha_preview_spin.value = alpha_floor

	if not _north_exit_spin.has_focus():
		_north_exit_spin.value = int(_viewer.call("get_edge_exit", "north"))
	if not _south_exit_spin.has_focus():
		_south_exit_spin.value = int(_viewer.call("get_edge_exit", "south"))
	if not _west_exit_spin.has_focus():
		_west_exit_spin.value = int(_viewer.call("get_edge_exit", "west"))
	if not _east_exit_spin.has_focus():
		_east_exit_spin.value = int(_viewer.call("get_edge_exit", "east"))


func _sync_inventory_ui() -> void:
	if _viewer == null:
		return
	var items: Array = _viewer.call("get_inventory_items")
	var equipped_name = str(_viewer.call("get_equipped_weapon_name"))
	if _inventory_slots.size() == 0:
		_build_inventory_slots()
	for i in range(_inventory_slots.size()):
		var btn: TextureButton = _inventory_slots[i]
		if i < items.size():
			var item = items[i]
			var icon_id = int(item.get("icon_grh", 0))
			var frames = item.get("icon_frames", [])
			if frames.size() > 0:
				var idx = int(floor(_ui_time * ICON_FPS)) % frames.size()
				icon_id = int(frames[idx])
			btn.texture_normal = _viewer.call("get_grh_icon_texture", icon_id)
			btn.texture_pressed = btn.texture_normal
			btn.texture_hover = btn.texture_normal
			btn.disabled = false
			btn.tooltip_text = str(item.get("name", "Unknown"))
		else:
			btn.texture_normal = null
			btn.texture_pressed = null
			btn.texture_hover = null
			btn.disabled = true
			btn.tooltip_text = ""
		btn.button_pressed = i == _selected_inventory_index
	_equipped_label.text = "Equipped: %s" % equipped_name
	var selected_name = "None"
	if _selected_inventory_index >= 0 and _selected_inventory_index < items.size():
		selected_name = str(items[_selected_inventory_index].get("name", "Unknown"))
	_selected_label.text = "Selected: %s" % selected_name


func _on_edit_toggle(pressed: bool) -> void:
	if _viewer == null:
		return
	_viewer.set("edit_enabled", pressed)


func _on_tool_selected(index: int) -> void:
	if _viewer == null:
		return
	var text = _tool_select.get_item_text(index)
	_viewer.set("edit_tool", text)


func _on_layer_changed(value: float) -> void:
	if _viewer == null:
		return
	_viewer.set("edit_layer_index", int(value) - 1)


func _on_grh_changed(value: float) -> void:
	if _viewer == null:
		return
	_viewer.set("edit_grh_id", int(value))


func _on_exit_map_changed(value: float) -> void:
	if _viewer == null:
		return
	_viewer.set("edit_exit_map", int(value))


func _on_exit_x_changed(value: float) -> void:
	if _viewer == null:
		return
	_viewer.set("edit_exit_x", int(value))


func _on_exit_y_changed(value: float) -> void:
	if _viewer == null:
		return
	_viewer.set("edit_exit_y", int(value))


func _on_roof_layer_changed(value: float) -> void:
	if _viewer == null:
		return
	_viewer.set("roof_layer_index", int(value) - 1)


func _on_show_layer_1(pressed: bool) -> void:
	if _viewer == null:
		return
	_viewer.set("show_layer_1", pressed)
	_viewer.queue_redraw()


func _on_show_layer_2(pressed: bool) -> void:
	if _viewer == null:
		return
	_viewer.set("show_layer_2", pressed)
	_viewer.queue_redraw()


func _on_show_layer_3(pressed: bool) -> void:
	if _viewer == null:
		return
	_viewer.set("show_layer_3", pressed)
	_viewer.queue_redraw()


func _on_show_layer_4(pressed: bool) -> void:
	if _viewer == null:
		return
	_viewer.set("show_layer_4", pressed)
	_viewer.queue_redraw()


func _on_blocked_overlay(pressed: bool) -> void:
	if _viewer == null:
		return
	_viewer.set("show_blocked_overlay", pressed)
	_viewer.queue_redraw()


func _on_exit_overlay(pressed: bool) -> void:
	if _viewer == null:
		return
	_viewer.set("show_exit_overlay", pressed)
	_viewer.queue_redraw()


func _on_roof_fade_toggle(pressed: bool) -> void:
	if _viewer == null:
		return
	_viewer.set("roof_fade_enabled", pressed)
	_viewer.queue_redraw()


func _on_alpha_preview_toggle(pressed: bool) -> void:
	if _viewer == null:
		return
	_viewer.set("edit_alpha_preview", pressed)
	_viewer.queue_redraw()


func _on_alpha_preview_value(value: float) -> void:
	if _viewer == null:
		return
	_viewer.set("edit_alpha_floor", float(value))
	_viewer.queue_redraw()


func _on_apply_edge_exits() -> void:
	if _viewer == null:
		return
	_viewer.call("set_edge_exit", "north", int(_north_exit_spin.value))
	_viewer.call("set_edge_exit", "south", int(_south_exit_spin.value))
	_viewer.call("set_edge_exit", "west", int(_west_exit_spin.value))
	_viewer.call("set_edge_exit", "east", int(_east_exit_spin.value))


func _on_save_map() -> void:
	if _viewer == null:
		return
	_viewer.call("_save_map")


func _on_exit_tile_requested(tile_x: int, tile_y: int) -> void:
	if _viewer == null:
		return
	_exit_dialog_map.value = int(_viewer.get("edit_exit_map"))
	_exit_dialog_x.value = int(_viewer.get("edit_exit_x"))
	_exit_dialog_y.value = int(_viewer.get("edit_exit_y"))
	_exit_dialog.title = "Exit Target (%d,%d)" % [tile_x, tile_y]
	_exit_dialog.popup_centered()


func _on_exit_dialog_confirmed() -> void:
	if _viewer == null:
		return
	_viewer.call("apply_exit_target", int(_exit_dialog_map.value), int(_exit_dialog_x.value), int(_exit_dialog_y.value))


func _on_exit_dialog_canceled() -> void:
	if _viewer == null:
		return
	_viewer.call("cancel_exit_target")


func _on_equip_pressed() -> void:
	if _viewer == null:
		return
	_viewer.call("equip_item", int(_selected_inventory_index))
	_sync_inventory_ui()


func _build_inventory_slots() -> void:
	if _inventory_grid == null:
		return
	if _inventory_slots.size() > 0:
		return
	for i in range(INVENTORY_SLOTS):
		var btn := TextureButton.new()
		btn.custom_minimum_size = Vector2(48, 48)
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.toggle_mode = true
		btn.focus_mode = Control.FOCUS_NONE
		var normal = StyleBoxFlat.new()
		normal.bg_color = Color(0.12, 0.12, 0.14, 0.9)
		normal.border_color = Color(0.35, 0.35, 0.4, 1.0)
		normal.border_width_left = 1
		normal.border_width_top = 1
		normal.border_width_right = 1
		normal.border_width_bottom = 1
		var hover = StyleBoxFlat.new()
		hover.bg_color = Color(0.18, 0.18, 0.22, 0.95)
		hover.border_color = Color(0.8, 0.75, 0.3, 1.0)
		hover.border_width_left = 1
		hover.border_width_top = 1
		hover.border_width_right = 1
		hover.border_width_bottom = 1
		var pressed = StyleBoxFlat.new()
		pressed.bg_color = Color(0.22, 0.2, 0.12, 0.95)
		pressed.border_color = Color(1.0, 0.9, 0.4, 1.0)
		pressed.border_width_left = 1
		pressed.border_width_top = 1
		pressed.border_width_right = 1
		pressed.border_width_bottom = 1
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.pressed.connect(_on_inventory_slot_pressed.bind(i))
		_inventory_grid.add_child(btn)
		_inventory_slots.append(btn)


func _on_inventory_slot_pressed(index: int) -> void:
	_selected_inventory_index = index
	_sync_inventory_ui()


func _build_sprite_list() -> void:
	if _viewer == null:
		return
	if _sprite_ids.size() > 0:
		return
	_sprite_ids = _viewer.call("get_grh_ids")
	_refresh_sprite_list("")


func _refresh_sprite_list(filter_text: String) -> void:
	_sprite_list.clear()
	var filter = filter_text.strip_edges()
	for id in _sprite_ids:
		var text = str(id)
		if filter != "" and text.findn(filter) == -1:
			continue
		_sprite_list.add_item(text)


func _on_sprite_search_changed(new_text: String) -> void:
	_refresh_sprite_list(new_text)


func _on_sprite_selected(index: int) -> void:
	var text = _sprite_list.get_item_text(index)
	if text.is_valid_int():
		_sprite_selected_id = int(text)
	else:
		_sprite_selected_id = -1
	_sprite_time = 0.0
	_sprite_frame_index = 0
	_update_sprite_frames()


func _update_sprite_frames() -> void:
	if _viewer == null or _sprite_selected_id < 0:
		_sprite_frames_list = []
		return
	_sprite_frames_list = _viewer.call("get_grh_frames", _sprite_selected_id)
	_sprite_frame_spin.max_value = max(0, _sprite_frames_list.size() - 1)
	_sprite_frame_spin.value = 0
	_sprite_frame_list.clear()
	for i in range(_sprite_frames_list.size()):
		_sprite_frame_list.add_item(str(_sprite_frames_list[i]))


func _sync_sprite_preview() -> void:
	if not _sprite_window.visible:
		return
	if _sprite_selected_id < 0:
		_sprite_preview.texture = null
		_sprite_info.text = "GRH: -"
		_sprite_frames.text = "Frames: -"
		return
	var entry: Dictionary = _viewer.call("get_grh_entry_info", _sprite_selected_id)
	var file_num = int(entry.get("file_num", 0))
	var w = int(entry.get("pixel_width", 0))
	var h = int(entry.get("pixel_height", 0))
	_sprite_info.text = "GRH: %d | File: %d | %dx%d" % [_sprite_selected_id, file_num, w, h]
	if _sprite_frames_list.size() == 0:
		_update_sprite_frames()
	var frame_id = _sprite_selected_id
	if _sprite_frames_list.size() > 0:
		if _sprite_play.button_pressed:
			var fps = max(1.0, float(_sprite_fps.value))
			var idx = int(floor(_sprite_time * fps)) % _sprite_frames_list.size()
			frame_id = int(_sprite_frames_list[idx])
		else:
			var idx = clamp(_sprite_frame_index, 0, _sprite_frames_list.size() - 1)
			frame_id = int(_sprite_frames_list[idx])
	_sprite_frames.text = "Frames: %d" % _sprite_frames_list.size()
	_sprite_frames.text = "Frames: %d | Current: %d" % [_sprite_frames_list.size(), frame_id]
	var tex = _viewer.call("get_grh_icon_texture", frame_id)
	if tex == null:
		tex = _viewer.call("get_grh_preview_texture", frame_id)
	_sprite_preview.texture = tex


func _on_sprite_prev() -> void:
	if _sprite_frames_list.size() == 0:
		return
	_sprite_frame_index = max(0, _sprite_frame_index - 1)
	_sprite_frame_spin.value = _sprite_frame_index


func _on_sprite_next() -> void:
	if _sprite_frames_list.size() == 0:
		return
	_sprite_frame_index = min(_sprite_frames_list.size() - 1, _sprite_frame_index + 1)
	_sprite_frame_spin.value = _sprite_frame_index


func _on_sprite_frame_spin(value: float) -> void:
	_sprite_frame_index = int(value)


func _on_sprite_frame_selected(index: int) -> void:
	if _sprite_frames_list.size() == 0:
		return
	_sprite_frame_index = clamp(index, 0, _sprite_frames_list.size() - 1)
	_sprite_frame_spin.value = _sprite_frame_index
	_sprite_play.button_pressed = false


func _on_sprite_play_toggled(_pressed: bool) -> void:
	_sprite_time = 0.0
