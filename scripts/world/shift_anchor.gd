class_name ShiftAnchor
extends Area3D
## A spot where Reality Shift works. With target_state set it always shifts to that
## state (one-way anchors); empty = cycle through the zone's states.

@export var zone_id: String = ""
@export var target_state: String = ""
@export var hint_key: String = "HINT_SHIFT_ANCHOR"

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(func(body): if body is Player: ShiftManager.set_anchor(self))
	body_exited.connect(func(body): if body is Player: ShiftManager.clear_anchor(self))

func _exit_tree() -> void:
	ShiftManager.clear_anchor(self)
