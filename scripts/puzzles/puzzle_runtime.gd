class_name PuzzleRuntime
extends RefCounted
## Logic for one puzzle type. PuzzleManager creates one per started puzzle.
## To add a type: extend this class and register it in PuzzleManager.RUNTIMES.

enum Result { PROGRESS, FAILED, SOLVED }

var def: PuzzleDef

func _init(puzzle_def: PuzzleDef) -> void:
	def = puzzle_def

func submit(_value: Variant) -> Result:
	return Result.FAILED

func reset() -> void:
	pass
