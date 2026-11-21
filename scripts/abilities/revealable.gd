class_name Revealable
extends Node3D
## Anything hidden until Memory Sight is active: writing on walls, ladders, echoes of
## objects. Fades in (or switches instantly with "reduce motion"). An Interactable child
## named by interactable_path can only be used while the thing is revealed.

@export var interactable_path: NodePath
## Stay visible after the first time it was revealed (e.g. discovered writing).
@export var stay_visible_once_found: bool = false

var revealed := false
var found := false

func _ready() -> void:
	add_to_group("memory_sight_reveal")
	_apply(true)

func set_revealed(on: bool) -> void:
	if on == revealed:
		return
	revealed = on
	if on:
		found = true
	_apply(false)

func is_effectively_visible() -> bool:
	return revealed or (stay_visible_once_found and found)

func _apply(instant: bool) -> void:
	var show_it := is_effectively_visible()
	var interactable := get_node_or_null(interactable_path) as Interactable
	if interactable != null:
		interactable.enabled = revealed
	var fade := 0.0 if (instant or bool(SettingsManager.get_value("accessibility", "reduce_motion"))) else 0.35
	if show_it:
		visible = true
	for n in find_children("*", "GeometryInstance3D", true, false):
		_fade_to(n, "transparency", 0.0 if show_it else 1.0, fade)
	for l in find_children("*", "Label3D", true, false):
		_fade_to(l, "modulate:a", 1.0 if show_it else 0.0, fade)
	if not show_it:
		if fade == 0.0:
			visible = false
		else:
			get_tree().create_timer(fade).timeout.connect(func(): if not is_effectively_visible(): visible = false)

func _fade_to(node: Node, property: String, target: float, fade: float) -> void:
	if fade == 0.0 or not is_inside_tree():
		node.set_indexed(property, target)
	else:
		create_tween().tween_property(node, property, target, fade)
