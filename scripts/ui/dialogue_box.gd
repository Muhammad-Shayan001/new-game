extends CanvasLayer
## Subtitle-style dialogue UI. Tap/click/Interact advances; choices are large buttons (touch friendly).
## Listens to EventBus only; DialogueManager owns the logic.

var _panel: PanelContainer
var _speaker: Label
var _text: RichTextLabel
var _choices: VBoxContainer
var _hint: Label
var _typing: Tween

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_panel.visible = false
	EventBus.dialogue_started.connect(func(_id): _panel.visible = true)
	EventBus.dialogue_line_shown.connect(_on_line)
	EventBus.dialogue_choices_shown.connect(_on_choices)
	EventBus.dialogue_finished.connect(func(_id): _panel.visible = false)

func _build() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.anchor_top = 0.62
	_panel.offset_left = 24
	_panel.offset_right = -24
	_panel.offset_bottom = -20
	_panel.offset_top = 0
	_panel.gui_input.connect(_on_gui_input)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_panel.add_child(box)
	var scale := float(Settings.value("text_scale"))
	_speaker = Label.new()
	_speaker.add_theme_font_size_override("font_size", int(26 * scale))
	_speaker.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	box.add_child(_speaker)
	_text = RichTextLabel.new()
	_text.fit_content = true
	_text.scroll_active = false
	_text.add_theme_font_size_override("normal_font_size", int(28 * scale))
	_text.custom_minimum_size.y = 90
	box.add_child(_text)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 6)
	box.add_child(_choices)
	_hint = Label.new()
	_hint.text = "▼"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(_hint)

func _on_line(_node_id: String, speaker_id: String, text: String) -> void:
	_clear_choices()
	_speaker.text = Loc.t("char." + speaker_id) if speaker_id != "" else ""
	_speaker.visible = speaker_id != ""
	_text.text = text
	if Loc.is_rtl():
		_text.layout_direction = Control.LAYOUT_DIRECTION_RTL
	else:
		_text.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_hint.visible = true
	if _typing:
		_typing.kill()
	if bool(Settings.value("reduced_motion")):
		_text.visible_ratio = 1.0
	else:
		_text.visible_ratio = 0.0
		_typing = create_tween()
		_typing.tween_property(_text, "visible_ratio", 1.0, clampf(text.length() * 0.018, 0.2, 2.0))

func _on_choices(choices: Array) -> void:
	_clear_choices()
	_hint.visible = false
	for c: Dictionary in choices:
		var b := Button.new()
		b.text = c["text"]
		b.custom_minimum_size.y = 64
		b.add_theme_font_size_override("font_size", int(26 * float(Settings.value("text_scale"))))
		b.pressed.connect(DialogueManager.choose.bind(int(c["index"])))
		_choices.add_child(b)

func _clear_choices() -> void:
	for c in _choices.get_children():
		c.queue_free()

func _on_gui_input(event: InputEvent) -> void:
	var tapped: bool = (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed)
	if tapped:
		_advance()

func _advance() -> void:
	if _typing and _typing.is_running():
		_typing.kill()
		_text.visible_ratio = 1.0
		return
	DialogueManager.advance()

func _unhandled_input(event: InputEvent) -> void:
	if _panel.visible and (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")):
		_advance()
		get_viewport().set_input_as_handled()
