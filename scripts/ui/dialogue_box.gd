class_name DialogueBox
extends PanelContainer
## Subtitle-style dialogue panel. Listens to DialogueManager signals on the EventBus and
## reports player input back with advance() / choose(). Contains no story data.

const INPUT_GUARD := 0.25   # ignore the press that started the conversation

var _name_label := Label.new()
var _text_label := Label.new()
var _choices := VBoxContainer.new()
var _guard := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	offset_top = -190
	offset_bottom = -20
	offset_left = 40
	offset_right = -40
	var box := VBoxContainer.new()
	_name_label.add_theme_font_size_override("font_size", 20)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size.y = 56
	box.add_child(_name_label)
	box.add_child(_text_label)
	box.add_child(_choices)
	add_child(box)
	visible = false
	EventBus.dialogue_started.connect(func(_id): visible = true; _guard = INPUT_GUARD)
	EventBus.dialogue_line_shown.connect(_on_line)
	EventBus.dialogue_choices_presented.connect(_on_choices)
	EventBus.dialogue_finished.connect(func(_id): visible = false)
	EventBus.settings_changed.connect(func(s, _k, _v): if s == "accessibility": _apply_size())
	_apply_size()

func _apply_size() -> void:
	_text_label.add_theme_font_size_override("font_size",
		int(22.0 * float(SettingsManager.get_value("accessibility", "subtitle_size"))))

func _on_line(speaker_id: String, text_key: String) -> void:
	for c in _choices.get_children():
		c.queue_free()
	var speaker := DataRegistry.get_character(speaker_id) if speaker_id != "" else null
	_name_label.text = Localization.t(speaker.name_key) if speaker != null else ""
	_name_label.modulate = speaker.accent_color if speaker != null else Color.WHITE
	_text_label.text = Localization.t(text_key)
	_guard = INPUT_GUARD

func _on_choices(choices: Array) -> void:
	for c in choices:
		var b := Button.new()
		b.text = Localization.t(c["text_key"])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var index: int = c["index"]
		b.pressed.connect(func(): DialogueManager.choose(index))
		_choices.add_child(b)

func _process(delta: float) -> void:
	if not visible:
		return
	_guard = maxf(_guard - delta, 0.0)
	if _guard == 0.0 and Input.is_action_just_pressed(InputActions.INTERACT):
		DialogueManager.advance()

func _gui_input(event: InputEvent) -> void:
	if visible and _guard == 0.0 and event is InputEventMouseButton and event.pressed:
		DialogueManager.advance()
	elif visible and _guard == 0.0 and event is InputEventScreenTouch and event.pressed:
		DialogueManager.advance()
