class_name MissionTracker
extends Control
## HUD card displaying the active investigation and current objectives.
## Designed with cyber-noir minimalism: clean typography, status pips, and smooth transitions.

var _panel := PanelContainer.new()
var _vbox := VBoxContainer.new()
var _tag_label := Label.new()
var _title_label := Label.new()
var _separator := HSeparator.new()
var _lines_box := VBoxContainer.new()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2(24, 24)
	custom_minimum_size = Vector2(300, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Styling the card
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.05, 0.08, 0.85)
	style.border_width_left = 3
	style.border_color = Color(0.0, 0.9, 1.0, 0.8)
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 14.0
	style.content_margin_top = 10.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 10.0
	_panel.add_theme_stylebox_override("panel", style)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_tag_label.text = "CURRENT INVESTIGATION"
	_tag_label.add_theme_font_size_override("font_size", 10)
	_tag_label.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0, 0.75))
	_tag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98, 1.0))
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_separator.add_theme_constant_override("separation", 6)
	_separator.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_lines_box.theme_override_constants.separation = 4
	_lines_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_vbox.theme_override_constants.separation = 3
	_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox.add_child(_tag_label)
	_vbox.add_child(_title_label)
	_vbox.add_child(_separator)
	_vbox.add_child(_lines_box)

	_panel.add_child(_vbox)
	add_child(_panel)

	EventBus.mission_state_changed.connect(func(_i, _s): refresh())
	EventBus.mission_objective_progress.connect(func(_m, _o, _c, _r): refresh())
	EventBus.chapter_changed.connect(func(_c): refresh())
	EventBus.load_finished.connect(func(_s, _ok): refresh())
	refresh()

func refresh() -> void:
	for child in _lines_box.get_children():
		child.queue_free()

	var id := MissionManager.tracked_mission()
	var def := DataRegistry.get_mission(id) if id != "" else null
	visible = def != null
	if def == null:
		return

	_title_label.text = Localization.t(def.title_key)

	for o in def.objectives:
		var done := MissionManager.get_progress(id, o.id) >= o.count
		var line := HBoxContainer.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var pip := Label.new()
		pip.text = "✓ " if done else "▶ "
		pip.add_theme_font_size_override("font_size", 12)
		pip.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0, 0.9) if not done else Color(0.4, 0.7, 0.5, 0.6))
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var desc := Label.new()
		var suffix := "" if o.count <= 1 else " (%d/%d)" % [MissionManager.get_progress(id, o.id), o.count]
		desc.text = "%s%s" % [Localization.t(o.text_key), suffix]
		desc.add_theme_font_size_override("font_size", 13)
		desc.add_theme_color_override("font_color", Color(0.9, 0.92, 0.96, 1.0) if not done else Color(0.5, 0.55, 0.6, 0.6))
		desc.mouse_filter = Control.MOUSE_FILTER_IGNORE

		line.add_child(pip)
		line.add_child(desc)
		_lines_box.add_child(line)
