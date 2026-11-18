extends CanvasLayer
## In-game HUD: touch controls (joystick, camera pad, interact, sprint, context ability, pause),
## objective line, interaction prompt, toast messages. Layout mirrors for left-handed players.
## All values come from EventBus / managers; this script owns no gameplay state.

var joystick: TouchJoystick
var look_pad: TouchLookPad
var interact_button: TouchButton
var sprint_button: TouchButton
var ability_button: TouchButton
var pause_button: TouchButton
var objective_label: Label
var prompt_label: Label
var toast_label: Label
var _controls: Control
var _toast_tween: Tween

func _ready() -> void:
	layer = 10
	_build()
	EventBus.interaction_prompt_changed.connect(_on_prompt)
	EventBus.toast_requested.connect(_toast)
	EventBus.mission_state_changed.connect(func(_i, _s): _refresh_objective())
	EventBus.objective_completed.connect(func(_m, _o): _refresh_objective())
	EventBus.settings_changed.connect(func(k, _v): _on_setting(k))
	EventBus.ability_unlocked.connect(func(_i): _refresh_ability())
	EventBus.ability_ended.connect(func(_i): _refresh_ability())
	EventBus.input_device_changed.connect(func(_k): _update_touch_visibility())
	_refresh_objective()
	_refresh_ability()
	_update_touch_visibility()

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_controls = Control.new()
	_controls.name = "TouchControls"
	_controls.set_anchors_preset(Control.PRESET_FULL_RECT)
	_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_controls)

	# Order matters: pads first (bottom), buttons last (on top).
	joystick = TouchJoystick.new()
	joystick.name = "Joystick"
	_controls.add_child(joystick)
	look_pad = TouchLookPad.new()
	look_pad.name = "LookPad"
	_controls.add_child(look_pad)
	interact_button = _make_button("Interact", "interact", "E")
	sprint_button = _make_button("Sprint", "sprint", "RUN")
	sprint_button.toggle_mode = bool(Settings.value("sprint_toggle"))
	ability_button = _make_button("Ability", "context_ability", "")
	pause_button = _make_button("Pause", "", "II")
	pause_button.pressed_changed.connect(func(p): if p: EventBus.pause_requested.emit())

	objective_label = _make_label(Control.PRESET_TOP_LEFT, 22)
	objective_label.position = Vector2(24, 18)
	objective_label.size = Vector2(760, 60)
	root.add_child(objective_label)
	prompt_label = _make_label(Control.PRESET_CENTER_BOTTOM, 30)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(prompt_label)
	toast_label = _make_label(Control.PRESET_CENTER_TOP, 26)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.modulate.a = 0.0
	root.add_child(toast_label)
	get_viewport().size_changed.connect(func(): _layout())
	_layout()

func _make_button(node_name: String, action: String, caption: String) -> TouchButton:
	var b := TouchButton.new()
	b.name = node_name
	b.action = action
	b.caption = caption
	_controls.add_child(b)
	return b

func _make_label(preset: int, font_size: int) -> Label:
	var l := Label.new()
	l.set_anchors_preset(preset)
	l.add_theme_font_size_override("font_size", int(font_size * float(Settings.value("text_scale"))))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

## Positions everything from the viewport size so it adapts to any phone aspect ratio.
func _layout(viewport_size: Vector2 = Vector2.ZERO) -> void:
	var vp := viewport_size if viewport_size != Vector2.ZERO else get_viewport().get_visible_rect().size
	var left_handed := bool(Settings.value("left_handed"))
	var margin := 28.0
	var b := TouchButton.MIN_SIZE
	var move_side_left := not left_handed
	joystick.position = Vector2(0, vp.y * 0.35) if move_side_left else Vector2(vp.x * 0.5, vp.y * 0.35)
	joystick.size = Vector2(vp.x * 0.5, vp.y * 0.65)
	look_pad.position = Vector2(vp.x * 0.5, 0) if move_side_left else Vector2.ZERO
	look_pad.size = Vector2(vp.x * 0.5, vp.y)
	# buttons sit in the thumb arc on the look side
	var bx := vp.x - margin - b if move_side_left else margin
	var dir := -1.0 if move_side_left else 1.0
	interact_button.size = Vector2(b * 1.25, b * 1.25)
	interact_button.position = Vector2(bx - (b * 0.25 if move_side_left else 0.0), vp.y - margin - b * 1.25)
	sprint_button.size = Vector2(b, b)
	sprint_button.position = Vector2(bx + dir * (b * 1.45), vp.y - margin - b * 0.9)
	ability_button.size = Vector2(b, b)
	ability_button.position = Vector2(bx, vp.y - margin - b * 2.45)
	var pb := b * 0.85              # ~50dp on a typical phone: above the 48dp touch-target guideline
	pause_button.custom_minimum_size = Vector2(pb, pb)
	pause_button.size = Vector2(pb, pb)
	pause_button.position = Vector2(vp.x - margin - pb, margin) if move_side_left else Vector2(margin, margin)
	objective_label.position = Vector2(margin, margin + 70) if not move_side_left else Vector2(margin, margin)
	objective_label.size.x = vp.x * 0.55
	prompt_label.position = Vector2(vp.x * 0.5 - 300, vp.y - margin - 140)
	prompt_label.size = Vector2(600, 60)
	toast_label.position = Vector2(vp.x * 0.5 - 300, margin + 10)
	toast_label.size = Vector2(600, 60)

func _on_setting(key: String) -> void:
	if key == "left_handed":
		_layout()
	elif key == "touch_controls":
		_update_touch_visibility()
	elif key == "text_scale":
		for l in [objective_label, prompt_label, toast_label]:
			l.add_theme_font_size_override("font_size", int(26 * float(Settings.value("text_scale"))))

func _update_touch_visibility() -> void:
	_controls.visible = InputRouter.touch_ui_enabled() or InputRouter.last_device == "touch"

func _refresh_objective() -> void:
	objective_label.text = MissionManager.current_objective_text()

func _refresh_ability() -> void:
	var id := AbilityManager.context_ability_id()
	ability_button.visible = id != ""
	if id != "":
		ability_button.caption = Loc.t(str(DataRegistry.get_def("abilities", id)["name_key"])).substr(0, 4).to_upper()
	ability_button.queue_redraw()

func _on_prompt(text: String) -> void:
	prompt_label.text = text
	interact_button.highlighted = text != ""
	if text != "":
		var key: String = {"kbm": "[E] ", "gamepad": "(A) ", "touch": ""}.get(InputRouter.last_device, "")
		prompt_label.text = key + text

func _toast(text: String) -> void:
	toast_label.text = text
	toast_label.modulate.a = 1.0
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.5)

func _process(_delta: float) -> void:
	# keep the context ability button in sync with what is nearby
	if Engine.get_process_frames() % 15 == 0:
		_refresh_ability()
