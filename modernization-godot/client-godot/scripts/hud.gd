extends CanvasLayer

@onready var _viewer: Node = get_parent().get_node("MapViewer")
@onready var _info: Label = $Panel/VBox/Info
@onready var _toggles: Label = $Panel/VBox/Toggles
@onready var _music_toggle: Button = $Panel/VBox/MusicToggle
@onready var _volume_slider: HSlider = $Panel/VBox/VolumeSlider


func _ready() -> void:
	_music_toggle.pressed.connect(_on_music_toggle)
	_volume_slider.value_changed.connect(_on_volume_changed)
	set_process(true)


func _process(_delta: float) -> void:
	if _viewer == null:
		return

	var map_id = _viewer.call("get_map_id")
	var music_index = _viewer.call("get_music_index")
	var rain = _viewer.call("is_rain_layer_enabled")
	var blocked = _viewer.call("is_blocked_overlay_enabled")
	var music_playing = _viewer.call("is_music_playing")

	_info.text = "Map: %s | Music: %s" % [str(map_id), str(music_index)]
	_toggles.text = "Rain: %s | Blocked: %s" % [str(rain), str(blocked)]
	_music_toggle.text = "Music: %s" % ("Stop" if music_playing else "Play")


func _on_music_toggle() -> void:
	if _viewer == null:
		return
	_viewer.call("toggle_music")


func _on_volume_changed(value: float) -> void:
	if _viewer == null:
		return
	_viewer.call("set_music_volume", float(value))
