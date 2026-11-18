class_name Effects
extends RefCounted
## Executes data-driven effects. An effect is {"do": "<op>", ...args}. Shared by missions,
## dialogue, interactables and puzzles so content never needs bespoke code.
## Ops: set_flag, adjust_rel, set_chapter, add_item, remove_item, collect_fragment, unlock_ability,
##      start_dialogue, start_mission, complete_objective, goto_location, play_sfx, play_music,
##      solve_puzzle, toast, autosave, log_decision.

static func run(effects: Array) -> void:
	for e in effects:
		if e is Dictionary:
			run_one(e)
		else:
			Log.warn("Effects", "Effect must be an object: %s" % str(e))

static func run_one(e: Dictionary) -> void:
	var op := str(e.get("do", ""))
	match op:
		"set_flag":
			GameState.set_flag(str(e["flag"]), e.get("value", true))
		"adjust_rel":
			GameState.adjust_relationship(str(e["key"]), int(e.get("delta", 1)))
		"set_chapter":
			GameState.set_chapter(int(e["value"]))
		"add_item":
			InventoryManager.add_item(str(e["id"]), int(e.get("count", 1)))
		"remove_item":
			InventoryManager.remove_item(str(e["id"]), int(e.get("count", 1)))
		"collect_fragment":
			MemoryManager.collect(str(e["id"]))
		"unlock_ability":
			AbilityManager.unlock(str(e["id"]))
		"start_dialogue":
			DialogueManager.start(str(e["id"]))
		"start_mission":
			MissionManager.start_mission(str(e["id"]))
		"complete_objective":
			MissionManager.complete_objective(str(e["mission"]), str(e["objective"]))
		"goto_location":
			SceneManager.go_to_location(str(e["id"]), str(e.get("spawn", "")))
		"play_sfx":
			Audio.play_sfx(str(e["id"]))
		"play_music":
			Audio.play_music(str(e["id"]))
		"solve_puzzle":
			PuzzleManager.mark_solved(str(e["id"]))
		"toast":
			EventBus.toast_requested.emit(Loc.t(str(e["key"])))
		"autosave":
			SaveManager.autosave()
		"log_decision":
			GameState.log_decision(str(e["id"]), str(e.get("text_key", "")))
		_:
			Log.warn("Effects", "Unknown effect op '%s'" % op)
