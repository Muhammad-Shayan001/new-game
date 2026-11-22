class_name MainMenu
extends Control

## Main Menu for AFTERLIFE.EXE
## Features high-contrast cyber-noir styling, Continue, New Game, Settings, and Credits.

signal start_game_requested
signal continue_game_requested

@onready var _continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var _new_game_button: Button = $CenterContainer/VBoxContainer/NewGameButton
@onready var _settings_button: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var _credits_button: Button = $CenterContainer/VBoxContainer/CreditsButton
@onready var _quit_button: Button = $CenterContainer/VBoxContainer/QuitButton
@onready var _credits_panel: PanelContainer = $CreditsPanel
@onready var _close_credits_btn: Button = $CreditsPanel/VBoxContainer/CloseCreditsButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_ui()
	_refresh_buttons()

func _setup_ui() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_credits_button.pressed.connect(_on_credits_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_close_credits_btn.pressed.connect(func(): _credits_panel.visible = false)
	_credits_panel.visible = false
	if OS.has_feature("mobile"):
		_quit_button.visible = false

func _refresh_buttons() -> void:
	var can_continue: bool = SaveManager.has_save(SaveManager.AUTO_SLOT)
	_continue_button.disabled = not can_continue
	_continue_button.modulate = Color(1, 1, 1, 1) if can_continue else Color(0.5, 0.5, 0.5, 0.5)

func _on_continue_pressed() -> void:
	AudioManager.play_cue("sfx_phone_buzz")
	continue_game_requested.emit()
	visible = false

func _on_new_game_pressed() -> void:
	AudioManager.play_cue("sfx_ability_shift")
	start_game_requested.emit()
	visible = false

func _on_settings_pressed() -> void:
	var settings_scene: PackedScene = load("res://scenes/ui/settings_menu.tscn")
	if settings_scene == null:
		EventBus.toast_requested.emit("TOAST_SETTINGS_LOAD_FAILED", "warning")
		return
	var settings_node: SettingsMenu = settings_scene.instantiate()
	add_child(settings_node)
	settings_node.closed.connect(func(): pass)  # queue_free handled inside SettingsMenu

func _on_credits_pressed() -> void:
	_credits_panel.visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()

func show_menu() -> void:
	visible = true
	_refresh_buttons()
