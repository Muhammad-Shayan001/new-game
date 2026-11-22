class_name PauseMenu
extends PanelContainer
## Pause screen: resume, save to a manual slot, main menu, quit. Opened through EventBus.pause_requested.

var _status := Label.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(320, 0)
	var box := VBoxContainer.new()
	var title := Label.new()
	title.text = Localization.t("UI_PAUSED")
	box.add_child(title)
	box.add_child(_button("UI_RESUME", func(): EventBus.pause_requested.emit(false)))
	for slot in SaveManager.MANUAL_SLOTS:
		box.add_child(_button_text("%s %d" % [Localization.t("UI_SAVE_SLOT"), slot], func(): _save(slot)))
	box.add_child(_button_text("MAIN MENU", _return_to_main_menu))
	if not OS.has_feature("mobile"):
		box.add_child(_button("UI_QUIT", func(): get_tree().quit()))
	box.add_child(_status)
	add_child(box)
	visible = false
	EventBus.pause_requested.connect(func(paused): visible = paused; _status.text = "")

func _button(key: String, action: Callable) -> Button:
	return _button_text(Localization.t(key), action)

func _button_text(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(action)
	return b

func _save(slot: int) -> void:
	_status.text = Localization.t("UI_SAVED") if SaveManager.save_game(slot) else Localization.t("UI_SAVE_FAILED")

func _return_to_main_menu() -> void:
	EventBus.pause_requested.emit(false)
	var main_menu: MainMenu = get_tree().root.find_child("MainMenu", true, false) as MainMenu
	if main_menu != null:
		InputService.push_lock("main_menu")
		main_menu.show_menu()
