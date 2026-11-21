class_name ConditionGate
extends Node3D
## Reusable barrier: open (hidden, no collision) while its ConditionSet is met.
## Reacts to flags, puzzles, shifts, deductions, items, missions and story states.

@export var conditions: ConditionSet
## true: open when met (a door). false: closed when met (a barrier that appears).
@export var open_when_met: bool = true

var is_open := false

func _ready() -> void:
	add_to_group("condition_gates")
	GameState.flag_changed.connect(func(_f, _v): refresh())
	EventBus.puzzle_solved.connect(func(_p): refresh())
	EventBus.shift_state_changed.connect(func(_z, _s): refresh())
	EventBus.deduction_made.connect(func(_d): refresh())
	EventBus.item_added.connect(func(_i, _n): refresh())
	EventBus.mission_completed.connect(func(_m): refresh())
	EventBus.story_state_changed.connect(func(_s, _v): refresh())
	EventBus.clue_added.connect(func(_c): refresh())
	refresh()

func refresh() -> void:
	var met := ConditionSet.check(conditions)
	is_open = met if open_when_met else not met
	visible = not is_open
	for c in find_children("*", "CollisionShape3D", true, false):
		(c as CollisionShape3D).set_deferred("disabled", is_open)
