class_name DialogueBox
extends PanelContainer
## Cinematic cyber-noir dialogue subtitle box. Listens to DialogueManager.

const INPUT_GUARD := 0.25   # ignore the press that started the conversation

var _name_label := Label.new()
var _text_label := Label.new()
var _choices := VBoxContainer.new()
var _continue_hint := Label.new()
var _guard := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	offset_top = -210
	offset_bottom = -30
	offset_left = 60
	offset_right = -60

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.04, 0.07, 0.92)
	style.border_width_top = 2
	style.border_color = Color(0.0, 0.9, 1.0, 0.75)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 24.0
	style.content_margin_top = 16.0
	style.content_margin_right = 24.0
	style.content_margin_bottom = 16.0
	add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.theme_override_constants.separation = 8

	_name_label.add_theme_font_size_override("font_size", 18)
	_name_label.add_theme_color_override("font_color", Color(0.0, 0.94, 1.0, 1.0))

	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size.y = 50
	_text_label.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98, 1.0))

	_choices.theme_override_constants.separation = 6

	_continue_hint.text = "[ Tap / Press E to continue ]"
	_continue_hint.add_theme_font_size_override("font_size", 11)
	_continue_hint.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65, 0.7))
	_continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	box.add_child(_name_label)
	box.add_child(_text_label)
	box.add_child(_choices)
	box.add_child(_continue_hint)
	add_child(box)

	visible = false
	EventBus.dialogue_started.connect(func(_id): visible = true; _guard = INPUT_GUARD)
	EventBus.dialogue_line_shown.connect(_on_line)
	EventBus.dialogue_choices_presented.connect(_on_choices)
	EventBus.dialogue_finished.connect(func(_id): visible = false)
	EventBus.settings_changed.connect(func(s, _k, _v): if s == "accessibility": _apply_size())
	_apply_size()

func _apply_size() -> void:
	var sz_val = SettingsManager.get_value("accessibility", "subtitle_size")
	var sz_scale: float = float(sz_val) if sz_val != null and float(sz_val) > 0.0 else 1.0
	_text_label.add_theme_font_size_override("font_size", int(20.0 * sz_scale))

func _on_line(speaker_id: String, text_key: String) -> void:
	for c in _choices.get_children():
		c.queue_free()
	var speaker := DataRegistry.get_character(speaker_id) if speaker_id != "" else null
	_name_label.text = Localization.t(speaker.name_key) if speaker != null else ""
	_name_label.modulate = speaker.accent_color if speaker != null else Color.WHITE
	_text_label.text = Localization.t(text_key)
	_continue_hint.visible = true
	_guard = INPUT_GUARD

func _on_choices(choices: Array) -> void:
	_continue_hint.visible = false
	for c in choices:
		var b := Button.new()
		b.text = " ▶  " + Localization.t(c["text_key"])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var b_style := StyleBoxFlat.new()
		b_style.bg_color = Color(0.06, 0.09, 0.14, 0.9)
		b_style.border_width_left = 2
		b_style.border_color = Color(0.0, 0.94, 1.0, 0.6)
		b_style.content_margin_left = 12.0
		b_style.content_margin_top = 8.0
		b_style.content_margin_bottom = 8.0
		b.add_theme_stylebox_override("normal", b_style)
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
