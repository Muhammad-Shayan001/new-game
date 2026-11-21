class_name PlateController
extends Node
## Solves a puzzle when every plate of that puzzle is held at the same time for
## hold_seconds. Works for one player + an Echo ghost, or several players (co-op).

@export var puzzle_id: String = ""
@export var hold_seconds: float = 1.0

var held := 0.0

func _physics_process(delta: float) -> void:
	var plates := get_tree().get_nodes_in_group("plates_" + puzzle_id)
	if plates.is_empty() or PuzzleManager.is_solved(puzzle_id):
		return
	var all_pressed := true
	for p in plates:
		if not p.pressed:
			all_pressed = false
			break
	held = held + delta if all_pressed else 0.0
	if held >= hold_seconds:
		PuzzleManager.mark_solved(puzzle_id)
