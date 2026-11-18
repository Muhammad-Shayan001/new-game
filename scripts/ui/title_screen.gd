extends Control
## Title screen: New Game, Continue, Settings (language), Quit. Debug builds also show the test arena.

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.09)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(460, 0)
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	var title := Label.new()
	title.text = "AFTERLIFE.EXE"
	title.add_theme_font_size_override("font_size", 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_button(box, "ui.new_game", func(): SceneManager.start_new_game())
	var cont := _button(box, "ui.continue", func(): SceneManager.continue_game(_latest_slot()))
	cont.disabled = _latest_slot() < 0
	_button(box, "ui.language", _cycle_language)
	if OS.is_debug_build():
		_button(box, "ui.test_arena", func(): SceneManager.start_new_game("LOC_DEV_TEST_ARENA"))
	if not OS.has_feature("web") and not OS.has_feature("android") and not OS.has_feature("ios"):
		_button(box, "ui.quit", func(): get_tree().quit())

func _button(parent: Node, key: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = Loc.t(key)
	b.custom_minimum_size.y = 76
	b.add_theme_font_size_override("font_size", 28)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _latest_slot() -> int:
	var best := -1
	var best_t := -1
	for s in range(SaveManager.SLOT_COUNT):
		var info := SaveManager.slot_info(s)
		if not info.is_empty() and int(info["saved_at"]) >= best_t:
			best_t = int(info["saved_at"])
			best = s
	return best

func _cycle_language() -> void:
	var langs := Loc.LANGUAGES
	var next := langs[(langs.find(Loc.language) + 1) % langs.size()]
	Settings.set_value("language", next)
	get_tree().reload_current_scene()
