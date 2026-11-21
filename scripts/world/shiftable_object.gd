class_name ShiftableObject
extends Node3D
## Anything that changes with a Reality Shift zone: visibility, solidity (alternate routes),
## state-specific clues (put an Interactable inside). Put colliders and meshes underneath.

@export var zone_id: String = ""
## States in which the object is visible. Empty = always.
@export var visible_in_states: Array[String] = []
## States in which it is solid / usable. Empty = same as visible.
@export var solid_in_states: Array[String] = []

var shown := true
var solid := true

func _ready() -> void:
	add_to_group("shiftables")
	apply_state(zone_id, ShiftManager.get_state(zone_id))   # matches a loaded save

func apply_state(zone: String, state: String) -> void:
	if zone != zone_id:
		return
	shown = visible_in_states.is_empty() or state in visible_in_states
	solid = shown if solid_in_states.is_empty() else state in solid_in_states
	visible = shown
	for c in find_children("*", "CollisionShape3D", true, false):
		(c as CollisionShape3D).set_deferred("disabled", not solid)
	for i in find_children("*", "Interactable", true, false):
		(i as Interactable).enabled = solid        # state-specific clues exist only in their state

## Collision shapes that are currently solid (used for the safe-transition check).
func solid_shapes() -> Array:
	if not solid:
		return []
	return find_children("*", "CollisionShape3D", true, false).filter(
		func(c): return c.get_parent() is StaticBody3D or c.get_parent() is AnimatableBody3D)
