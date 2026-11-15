class_name MissionTracker
extends VBoxContainer
## HUD list of the tracked mission and its objectives.

var _title := Label.new()
var _lines := VBoxContainer.new()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2(24, 24)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.add_theme_font_size_override("font_size", 22)
	add_child(_title)
	add_child(_lines)
	EventBus.mission_state_changed.connect(func(_i, _s): refresh())
	EventBus.mission_objective_progress.connect(func(_m, _o, _c, _r): refresh())
	EventBus.chapter_changed.connect(func(_c): refresh())
	EventBus.load_finished.connect(func(_s, _ok): refresh())
	refresh()

func refresh() -> void:
	for child in _lines.get_children():
		child.queue_free()
	var id := MissionManager.tracked_mission()
	var def := DataRegistry.get_mission(id) if id != "" else null
	visible = def != null
	if def == null:
		return
	_title.text = Localization.t(def.title_key)
	for o in def.objectives:
		var done := MissionManager.get_progress(id, o.id) >= o.count
		var line := Label.new()
		var suffix := "" if o.count <= 1 else " (%d/%d)" % [MissionManager.get_progress(id, o.id), o.count]
		line.text = "%s %s%s" % ["[x]" if done else "[ ]", Localization.t(o.text_key), suffix]
		line.modulate.a = 0.6 if done else 1.0
		_lines.add_child(line)
