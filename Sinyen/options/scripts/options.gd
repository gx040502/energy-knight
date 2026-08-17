extends Control

signal closed

@onready var master_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/masterRow/masterSlider
@onready var master_value_label: Label = $PanelContainer/MarginContainer/VBoxContainer/masterRow/masterValueLabel
@onready var music_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/musicRow/musicSlider
@onready var music_value_label: Label = $PanelContainer/MarginContainer/VBoxContainer/musicRow/musicValueLabel
@onready var sfx_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/sfxRow/sfxSlider
@onready var sfx_value_label: Label = $PanelContainer/MarginContainer/VBoxContainer/sfxRow/sfxValueLabel
@onready var back_button: Button = $PanelContainer/MarginContainer/VBoxContainer/backButton

var _master_bus: int = -1
var _music_bus: int = -1
var _sfx_bus: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_master_bus = _resolve_bus(&"Master")
	_music_bus = _resolve_bus(&"Music")
	_sfx_bus = _resolve_bus(&"SFX")

	# Seed sliders from the live AudioServer state BEFORE connecting signals.
	_init_slider(master_slider, master_value_label, _master_bus)
	_init_slider(music_slider, music_value_label, _music_bus)
	_init_slider(sfx_slider, sfx_value_label, _sfx_bus)

	master_slider.value_changed.connect(_on_master_value_changed)
	music_slider.value_changed.connect(_on_music_value_changed)
	sfx_slider.value_changed.connect(_on_sfx_value_changed)
	back_button.pressed.connect(_on_back_pressed)

	back_button.grab_focus()


# --- Bus helpers ---

func _resolve_bus(bus_name: StringName) -> int:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		push_error("Options: audio bus '%s' not found. Add it in the Audio tab." % bus_name)
	return idx


func _init_slider(slider: HSlider, label: Label, bus_idx: int) -> void:
	if bus_idx < 0:
		slider.editable = false
		label.text = "N/A"
		return

	var linear: float = 0.0
	if not AudioServer.is_bus_mute(bus_idx):
		linear = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))

	# set_value_no_signal avoids firing value_changed during setup.
	slider.set_value_no_signal(clampf(linear, 0.0, 1.0))
	label.text = _format_percent(slider.value)


func _apply_volume(bus_idx: int, label: Label, value: float) -> void:
	if bus_idx < 0:
		return

	# linear_to_db(0.0) is -INF, which poisons the bus. Mute instead.
	if is_zero_approx(value):
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

	label.text = _format_percent(value)


func _format_percent(value: float) -> String:
	return "%d%%" % roundi(value * 100.0)


# --- Signal handlers ---

func _on_master_value_changed(value: float) -> void:
	_apply_volume(_master_bus, master_value_label, value)


func _on_music_value_changed(value: float) -> void:
	_apply_volume(_music_bus, music_value_label, value)


func _on_sfx_value_changed(value: float) -> void:
	_apply_volume(_sfx_bus, sfx_value_label, value)


func _on_back_pressed() -> void:
	closed.emit()
	#get_tree().change_scene_to_file("res://Sinyen/main_menu/scenes/main_menu.tscn")
