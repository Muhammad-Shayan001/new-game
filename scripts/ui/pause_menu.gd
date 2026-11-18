extends CanvasLayer
## Pause menu (works with touch, mouse, keyboard and gamepad). Pausing freezes the tree.

var _panel: PanelContainer
var _vbox: VBoxContainer
var _opened: bool = false

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(560, 0)
	_panel.visible = false
	add_child(_panel)
	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(_vbox)
	_rebuild()
	EventBus.pause_requested.connect(toggle)

func _rebuild() -> void:
	for c in _vbox.get_children():
		c.queue_free()
	var title := Label.new()
	title.text = Loc.t("ui.paused")
	title.add_theme_font_size_override("font_size", 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(title)
	_add_button("ui.resume", toggle)
	_add_button("ui.save", _save)
	_add_slider("ui.volume", "master_volume", 0.0, 1.0)
	_add_slider("ui.camera_sensitivity", "camera_sensitivity", 0.3, 2.5)
	_add_check("ui.subtitles", "subtitles")
	_add_check("ui.invert_y", "invert_y")
	_add_check("ui.left_handed", "left_handed")
	_add_check("ui.reduced_motion", "reduced_motion")
	_add_button("ui.touch_controls", _cycle_touch)
	_add_button("ui.quit_to_title", _quit)

func _add_button(key: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = Loc.t(key)
	b.custom_minimum_size.y = 68
	b.pressed.connect(cb)
	_vbox.add_child(b)

func _add_slider(key: String, setting: String, lo: float, hi: float) -> void:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = Loc.t(key)
	l.custom_minimum_size.x = 240
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.05
	s.value = float(Settings.value(setting))
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.custom_minimum_size.y = 48
	s.value_changed.connect(func(v): Settings.set_value(setting, v))
	row.add_child(s)
	_vbox.add_child(row)

func _add_check(key: String, setting: String) -> void:
	var c := CheckButton.new()
	c.text = Loc.t(key)
	c.button_pressed = bool(Settings.value(setting))
	c.custom_minimum_size.y = 56
	c.toggled.connect(func(v): Settings.set_value(setting, v))
	_vbox.add_child(c)

func toggle() -> void:
	if DialogueManager.is_active():
		return
	_opened = not _opened
	_panel.visible = _opened
	get_tree().paused = _opened
	if _opened:
		InputRouter.push_lock("pause")
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		InputRouter.pop_lock("pause")

func _cycle_touch() -> void:
	var modes := ["auto", "on", "off"]
	var next: String = modes[(modes.find(str(Settings.value("touch_controls"))) + 1) % modes.size()]
	Settings.set_value("touch_controls", next)
	EventBus.toast_requested.emit("%s: %s" % [Loc.t("ui.touch_controls"), next])

func _save() -> void:
	if SaveManager.save_game(1):
		EventBus.toast_requested.emit(Loc.t("ui.saved"))

func _quit() -> void:
	toggle()
	SceneManager.return_to_title()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()
