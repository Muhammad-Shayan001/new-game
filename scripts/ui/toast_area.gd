class_name ToastArea
extends VBoxContainer
## Short pop-up messages ("Memory recovered", "Clue added").

func _ready() -> void:
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	position.y = 24
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.toast_requested.connect(show_toast)

func show_toast(text_key: String, kind: String = "info") -> void:
	var label := Label.new()
	label.text = Localization.t(text_key)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	if kind == "reward":
		label.modulate = Color(1.0, 0.9, 0.5)
	add_child(label)
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)
