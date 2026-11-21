class_name ClueBoard
extends Interactable
## Logic puzzle component. Linking two clues the player owns produces a Deduction.
## If puzzle_id is set the puzzle is solved when the deduction is made.

@export var deduction_id: String = ""

func interact() -> void:
	if not can_interact():
		return
	var deduction := DataRegistry.get_deduction(deduction_id)
	if deduction == null:
		GameLog.error("ClueBoard", "unknown deduction '%s'" % deduction_id)
		return
	var made := InventoryManager.link_clues(deduction.clue_a, deduction.clue_b)
	if made == "":
		EventBus.toast_requested.emit("TOAST_CLUES_DONT_FIT", "info")
		return
	if puzzle_id != "":
		PuzzleManager.mark_solved(puzzle_id)
	super.interact()
