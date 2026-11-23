class_name InteractionPrompt
extends CenterContainer
## Cinematic contextual interaction prompt with hold-progress ring/bar.

var _panel := PanelContainer.new()
var _hbox := HBoxContainer.new()
var _badge := Label.new()
var _label := Label.new()
var _bar := ProgressBar.new()
var _vbox := VBoxContainer.new()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	offset_bottom = -120
	offset_top = -180
	offset_left = -160
	offset_right = 160
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var pill_style := StyleBoxFlat.new()
	pill_style.bg_color = Color(0.04, 0.06, 0.1, 0.9)
	pill_style.border_width_left = 2
	pill_style.border_width_top = 2
	pill_style.border_width_right = 2
	pill_style.border_width_bottom = 2
	pill_style.border_color = Color(0.0, 0.94, 1.0, 0.85)
	pill_style.corner_radius_top_left = 20
	pill_style.corner_radius_top_right = 20
	pill_style.corner_radius_bottom_right = 20
	pill_style.corner_radius_bottom_left = 20
	pill_style.content_margin_left = 16.0
	pill_style.content_margin_right = 16.0
	pill_style.content_margin_top = 8.0
	pill_style.content_margin_bottom = 8.0
	_panel.add_theme_stylebox_override("panel", pill_style)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_badge.add_theme_font_size_override("font_size", 14)
	_badge.add_theme_color_override("font_color", Color(0.0, 0.94, 1.0, 1.0))
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_label.add_theme_font_size_override("font_size", 15)
	_label.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0, 1.0))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_hbox.theme_override_constants.separation = 8
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hbox.add_child(_badge)
	_hbox.add_child(_label)

	_bar.show_percentage = false
	_bar.max_value = 1.0
	_bar.custom_minimum_size = Vector2(160, 4)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox.theme_override_constants.separation = 4
	_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox.add_child(_hbox)
	_vbox.add_child(_bar)

	_panel.add_child(_vbox)
	add_child(_panel)

	visible = false
	EventBus.interaction_prompt_changed.connect(_on_prompt)
	EventBus.interaction_hold_progress.connect(_on_hold_progress)

func _on_prompt(show_it: bool, key: String) -> void:
	if show_it:
		var hint: String = {"keyboard_mouse": "[ E ]", "gamepad": "[ (A) ]", "touch": "[ TAP ]"}.get(InputService.device, "[ E ]")
		_badge.text = hint
		_label.text = Localization.t(key)
		_bar.visible = false
		visible = true
		modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 1.0, 0.15)
	else:
		visible = false

func _on_hold_progress(r: float) -> void:
	_bar.value = r
	_bar.visible = r > 0.0
