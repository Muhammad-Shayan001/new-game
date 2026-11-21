class_name AbilityHud
extends Control
## Clear activation feedback for the supernatural mechanics:
##  - ability list with Ready / Active (seconds) / Recharging (seconds)
##  - screen tint while Memory Sight is active
##  - contextual hints at Shift Anchors and Echo Sites
##  - recording indicator, echo captions, Echo Detection result text
## Listens to the EventBus only. "Reduce motion" removes fades.

const TINT_ALPHA := 0.10

var _tint := ColorRect.new()
var _slots := VBoxContainer.new()
var _hint := Label.new()
var _caption := Label.new()
var _recording := Label.new()
var _pulse := Label.new()
var _slot_labels: Dictionary = {}
var _caption_token := 0
var _pulse_token := 0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint.color = Color(0.5, 0.75, 1.0, 0.0)
	add_child(_tint)
	_slots.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_slots.position = Vector2(-340, 24)
	_slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_slots)
	for label in [_hint, _caption, _recording, _pulse]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		add_child(label)
		label.visible = false
	_hint.position.y -= 230
	_caption.position.y -= 260
	_caption.add_theme_font_size_override("font_size", 24)
	_recording.position.y = -680
	_pulse.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_pulse.position.y = 90
	_pulse.add_theme_font_size_override("font_size", 26)
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
			var label := Label.new()
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_slots.add_child(label)
			_slot_labels[def.id] = label
	_refresh_slots()

func _process(_delta: float) -> void:
	_refresh_slots()

func slot_text(ability_id: String) -> String:
	var def := DataRegistry.get_ability(ability_id)
	var state := Localization.t("UI_ABILITY_READY")
	if AbilityManager.is_active(ability_id):
		state = "%s %ds" % [Localization.t("UI_ABILITY_ACTIVE"), ceili(AbilityManager.active_left(ability_id))]
	elif AbilityManager.cooldown_left(ability_id) > 0.0:
		state = "%s %ds" % [Localization.t("UI_ABILITY_COOLDOWN"), ceili(AbilityManager.cooldown_left(ability_id))]
	return "[%d] %s: %s" % [def.input_slot, Localization.t(def.name_key), state]

func _refresh_slots() -> void:
	for id in _slot_labels:
		_slot_labels[id].text = slot_text(id)

func _reduce_motion() -> bool:
	return bool(SettingsManager.get_value("accessibility", "reduce_motion"))

func _set_tint(on: bool) -> void:
	var target := TINT_ALPHA if on else 0.0
	if _reduce_motion() or not is_inside_tree():
		_tint.color.a = target
	else:
		create_tween().tween_property(_tint, "color:a", target, 0.3)

func tint_alpha() -> float:
	return _tint.color.a

func _on_activated(id: String) -> void:
	if id == "ABIL_MEMORY_SIGHT":
		_set_tint(true)

func _on_ended(id: String) -> void:
	if id == "ABIL_MEMORY_SIGHT":
		_set_tint(false)

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
	_recording.text = "(o) " + Localization.t("UI_ECHO_RECORDING")

func _on_caption(_speaker: String, text_key: String) -> void:
	if not bool(SettingsManager.get_value("accessibility", "subtitles")):
		return
	_caption_token += 1
	var token := _caption_token
	_caption.text = Localization.t(text_key)
	_caption.visible = true
	get_tree().create_timer(2.2).timeout.connect(func(): if token == _caption_token: _caption.visible = false)

func _on_detected(_trace: String, distance: float, bearing: float) -> void:
	if not bool(SettingsManager.get_value("accessibility", "echo_visual_cues")):
		return
	var band := "UI_ECHO_VERY_CLOSE" if distance <= EchoDetection.VERY_CLOSE else ("UI_ECHO_CLOSE" if distance <= EchoDetection.CLOSE else "UI_ECHO_FAR")
	_show_pulse("%s, %s" % [Localization.t(band), Localization.t(_direction_key(bearing))])

## Direction words from the bearing (0 = ahead, +PI/2 = right): readable without sound or colour.
static func _direction_key(bearing: float) -> String:
	var a := wrapf(bearing, -PI, PI)
	if absf(a) <= PI / 4.0:
		return "UI_ECHO_AHEAD"
	if a > PI / 4.0 and a < 3.0 * PI / 4.0:
		return "UI_ECHO_RIGHT"
	if a < -PI / 4.0 and a > -3.0 * PI / 4.0:
		return "UI_ECHO_LEFT"
	return "UI_ECHO_BEHIND"

func _show_pulse(text: String) -> void:
	_pulse_token += 1
	var token := _pulse_token
	_pulse.text = text
	_pulse.visible = true
	get_tree().create_timer(3.0).timeout.connect(func(): if token == _pulse_token: _pulse.visible = false)

func pulse_text() -> String:
	return _pulse.text if _pulse.visible else ""
