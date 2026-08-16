extends CanvasLayer

const MAIN_MENU_PATH: String = "res://Sinyen/main_menu/scenes/main_menu.tscn"
const OPTIONS_PATH: String = "res://Sinyen/options/scenes/options.tscn"

@onready var color_rect: ColorRect = $ColorRect
@onready var panel_container: PanelContainer = $PanelContainer
@onready var resume_button: Button = $PanelContainer/VBoxContainer/resumeButton
@onready var restart_button: Button = $PanelContainer/VBoxContainer/restartButton
@onready var settings_button: Button = $PanelContainer/VBoxContainer/settingsButton
@onready var quit_button: Button = $PanelContainer/VBoxContainer/quitButton
@onready var pause_button: Button = $PauseButtonLayer/pauseButton

var _options_instance: Control = null
var _pause_action: StringName = &"ui_cancel"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true
	_set_menu_visible(false)

	if InputMap.has_action(&"pause"):
		_pause_action = &"pause"

	pause_button.pressed.connect(toggle_pause)
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(_pause_action):
		return

	toggle_pause()
	get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	if _options_instance != null:
		_close_options()
	elif get_tree().paused:
		_resume()
	else:
		_pause()


func _set_menu_visible(is_open: bool) -> void:
	color_rect.visible = is_open
	panel_container.visible = is_open
	pause_button.visible = not is_open


func _pause() -> void:
	_set_menu_visible(true)
	get_tree().paused = true
	resume_button.grab_focus()


func _resume() -> void:
	get_tree().paused = false
	_set_menu_visible(false)


# --- Button handlers ---

func _on_resume_pressed() -> void:
	_resume()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	_set_menu_visible(false)
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _on_settings_pressed() -> void:
	if _options_instance != null:
		return

	var packed: PackedScene = load(OPTIONS_PATH) as PackedScene
	if packed == null:
		push_error("PauseMenu: failed to load options scene at %s" % OPTIONS_PATH)
		return

	_options_instance = packed.instantiate() as Control
	_options_instance.closed.connect(_close_options)
	add_child(_options_instance)
	panel_container.visible = false


func _close_options() -> void:
	if _options_instance == null:
		return

	_options_instance.queue_free()
	_options_instance = null
	panel_container.visible = true
	settings_button.grab_focus()
