class_name Interactable
extends Area3D
## Anything the player can use: clues, pickups, doors, NPCs, puzzle controls.
## Behaviour is configured by exported DATA; no per-object scripts are needed.
## Effects run in this order: flags, clue, item, fragment, mission, dialogue, puzzle, sound, travel.

enum Priority { AMBIENT, PICKUP, CLUE, STORY }   # higher wins: story > clue > pickup > ambient

signal interacted

@export var interactable_id: String = ""            # INT_<LOCATION>_<NAME>
@export var prompt_key: String = "PROMPT_EXAMINE"
@export var interact_priority: Priority = Priority.AMBIENT
## Seconds the button must be held (0 = instant).
@export var hold_time: float = 0.0
@export var conditions: ConditionSet
@export var once: bool = false
@export var enabled: bool = true

@export_group("Effects")
@export var set_flags: Array[String] = []
@export var give_clue: String = ""
@export var give_item: String = ""
@export var collect_fragment: String = ""
@export var start_mission: String = ""
@export var start_dialogue: String = ""
@export var puzzle_id: String = ""
@export var puzzle_symbol: String = ""
@export var play_cue: String = ""
@export var travel_to_location: String = ""
@export var travel_spawn: String = ""

func _ready() -> void:
	collision_layer = 4      # layer 3 "interactable"
	collision_mask = 0
	monitoring = false
	add_to_group("interactables")

func _done_flag() -> String:
	return "int_done_" + interactable_id.to_lower()

func can_interact() -> bool:
	if not enabled or not ConditionSet.check(conditions):
		return false
	if once and interactable_id != "" and GameState.get_flag(_done_flag(), false):
		return false
	return true

func interact() -> void:
	if not can_interact():
		return
	if once and interactable_id != "":
		GameState.set_flag(_done_flag(), true)
	for f in set_flags:
		GameState.set_flag(f, true)
	if give_clue != "": InventoryManager.add_clue(give_clue)
	if give_item != "": InventoryManager.add_item(give_item)
	if collect_fragment != "": MemoryManager.collect(collect_fragment)
	if start_mission != "": MissionManager.start_mission(start_mission)
	if start_dialogue != "": DialogueManager.start(start_dialogue)
	if puzzle_id != "":
		if puzzle_symbol != "":
			PuzzleManager.submit(puzzle_id, puzzle_symbol)
		else:
			PuzzleManager.start(puzzle_id)
	if play_cue != "": AudioManager.play_cue(play_cue)
	interacted.emit()
	EventBus.interaction_completed.emit(interactable_id)
	if travel_to_location != "":
		SceneRouter.change_location(travel_to_location, travel_spawn)
