class_name AbilityHud
extends Control
## Full supernatural feedback:
##  - Memory Vision full-screen desaturation / anomaly shader
##  - Ability slots with Ready / Active / Cooldown status
##  - Shift Anchor and Time Echo contextual indicators
##  - Echo Detection direction text

const SHADER_PATH := "res://assets/shaders/memory_vision.gdshader"

var _tint := ColorRect.new()
var _mat: ShaderMaterial = null
var _slots := VBoxContainer.new()
var _hint := Label.new()
var _caption := Label.new()
var _recording := Label.new()
var _pulse := Label.new()
var _slot_labels: Dictionary = {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Fullscreen post-process tint
	_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint.color = Color(1, 1, 1, 1)

	if ResourceLoader.exists(SHADER_PATH):
		var shader := load(SHADER_PATH) as Shader
		if shader != null:
			_mat = ShaderMaterial.new()
			_mat.shader = shader
			_mat.set_shader_parameter("vision_active", 0.0)
			_tint.material = _mat

	add_child(_tint)

	# Ability Slots HUD (top-right)
	_slots.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_slots.offset_left = -260
	_slots.offset_top = 24
	_slots.offset_right = -24
	_slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_slots)

	# Prompts & indicators
	for label in [_hint, _caption, _recording, _pulse]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		label.visible = false
		add_child(label)

	_hint.offset_top = -240
	_hint.offset_bottom = -210
	_hint.add_theme_font_size_override("font_size", 16)
	_hint.add_theme_color_override("font_color", Color(0.0, 0.94, 1.0, 0.9))

	_caption.offset_top = -280
	_caption.offset_bottom = -240
	_caption.add_theme_font_size_override("font_size", 22)
	_caption.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6, 1.0))

	_recording.offset_top = -320
	_recording.offset_bottom = -290
	_recording.add_theme_font_size_override("font_size", 16)
	_recording.add_theme_color_override("font_color", Color(1.0, 0.2, 0.3, 1.0))

	_pulse.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_pulse.offset_top = 80
	_pulse.offset_bottom = 120
	_pulse.add_theme_font_size_override("font_size", 20)
	_pulse.add_theme_color_override("font_color", Color(0.0, 0.94, 1.0, 1.0))

	EventBus.ability_activated.connect(_on_activated)
	EventBus.ability_ended.connect(_on_ended)
	EventBus.ability_unlocked.connect(func(_id): _rebuild_slots())
	EventBus.load_finished.connect(func(_s, _ok): _rebuild_slots())
	EventBus.shift_anchor_changed.connect(_on_anchor)
	EventBus.echo_site_changed.connect(_on_site)
	EventBus.echo_recording_changed.connect(_on_recording)
	EventBus.echo_caption.connect(_on_caption)
	EventBus.echo_detected.connect(_on_detected)
	EventBus.echo_nothing_found.connect(func(): _show_pulse(Localization.t("UI_ECHO_NOTHING")))
	_rebuild_slots()

func _rebuild_slots() -> void:
	for c in _slots.get_children():
		c.queue_free()
	_slot_labels.clear()

	for def in DataRegistry.all("ability"):
		if GameState.has_ability(def.id):
			var slot_panel := PanelContainer.new()
			var p_style := StyleBoxFlat.new()
			p_style.bg_color = Color(0.04, 0.06, 0.09, 0.8)
			p_style.border_width_right = 2
			p_style.border_color = Color(0.0, 0.9, 1.0, 0.6)
			p_style.content_margin_left = 10.0
			p_style.content_margin_right = 10.0
			p_style.content_margin_top = 4.0
			p_style.content_margin_bottom = 4.0
			slot_panel.add_theme_stylebox_override("panel", p_style)

			var label := Label.new()
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.add_theme_font_size_override("font_size", 12)
			slot_panel.add_child(label)
			_slots.add_child(slot_panel)
			_slot_labels[def.id] = label
	_refresh_slots()

func _process(_delta: float) -> void:
	_refresh_slots()

func slot_text(ability_id: String) -> String:
	var def := DataRegistry.get_ability(ability_id)
	var state := Localization.t("UI_ABILITY_READY")
	if AbilityManager.is_active(ability_id):
		state = "%s (%ds)" % [Localization.t("UI_ABILITY_ACTIVE"), ceili(AbilityManager.active_left(ability_id))]
	elif AbilityManager.cooldown_left(ability_id) > 0.0:
		state = "%s (%ds)" % [Localization.t("UI_ABILITY_COOLDOWN"), ceili(AbilityManager.cooldown_left(ability_id))]
	return "[%d] %s: %s" % [def.input_slot, Localization.t(def.name_key), state]

func _refresh_slots() -> void:
	for id in _slot_labels:
		_slot_labels[id].text = slot_text(id)

func _set_vision_shader(active: bool) -> void:
	if _mat == null:
		return
	var target: float = 1.0 if active else 0.0
	var tween := create_tween()
	tween.tween_method(func(v: float): _mat.set_shader_parameter("vision_active", v),
		float(_mat.get_shader_parameter("vision_active")), target, 0.35)

func _on_activated(id: String) -> void:
	if id == "ABIL_MEMORY_SIGHT":
		_set_vision_shader(true)

func _on_ended(id: String) -> void:
	if id == "ABIL_MEMORY_SIGHT":
		_set_vision_shader(false)

func _on_anchor(_zone: String, available: bool) -> void:
	_hint.visible = available
	if available:
		_hint.text = Localization.t("HINT_SHIFT_ANCHOR")

func _on_site(_echo_id: String, available: bool) -> void:
	_hint.visible = available
	if available:
		var site := TimeEchoManager.current_site()
		_hint.text = Localization.t(site.hint_key if site != null else "HINT_ECHO_SITE")

func _on_recording(on: bool) -> void:
	_recording.visible = on
	_recording.text = "● " + Localization.t("UI_ECHO_RECORDING")

func _on_caption(text_key: String) -> void:
	_caption.text = Localization.t(text_key)
	_caption.visible = true
	var tween := create_tween()
	tween.tween_interval(3.5)
	tween.tween_callback(func(): _caption.visible = false)

func _on_detected(distance: String, direction: String) -> void:
	_show_pulse("%s (%s)" % [Localization.t(distance), Localization.t(direction)])

func _show_pulse(text: String) -> void:
	_pulse.text = text
	_pulse.visible = true
	var tween := create_tween()
	tween.tween_interval(2.5)
	tween.tween_callback(func(): _pulse.visible = false)
