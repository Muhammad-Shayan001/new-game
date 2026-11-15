class_name InteractionPrompt
extends CenterContainer
## "Press E to examine" prompt with a hold-progress bar. Reacts to EventBus only.

var _label := Label.new()
var _bar := ProgressBar.new()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	position.y -= 140
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	_label.add_theme_font_size_override("font_size", 22)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bar.show_percentage = false
	_bar.max_value = 1.0
	_bar.custom_minimum_size = Vector2(180, 8)
	box.add_child(_label)
	box.add_child(_bar)
	add_child(box)
	visible = false
	EventBus.interaction_prompt_changed.connect(_on_prompt)
	EventBus.interaction_hold_progress.connect(func(r): _bar.value = r; _bar.visible = r > 0.0)

func _on_prompt(show_it: bool, key: String) -> void:
	visible = show_it
	if show_it:
		var hint: String = {"keyboard_mouse": "[E] ", "gamepad": "[A] ", "touch": ""}.get(InputService.device, "")
		_label.text = hint + Localization.t(key)
	_bar.visible = false
