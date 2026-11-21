extends TestCase
## Completion gate: a developer can add a character, mission, location or puzzle
## by adding DATA only. Nothing below touches a system script.

var host: Node3D

func before_each() -> void:
	super.before_each()
	host = Node3D.new()
	add_child(host)
	SceneRouter.fade_time = 0.0
	SceneRouter.state = SceneRouter.State.IDLE
	SceneRouter.current_root = null
	SceneRouter.current_location_id = ""
	SceneRouter.register_host(host)

func after_each() -> void:
	SceneRouter.current_root = null
	host.queue_free()
	DataRegistry.reload()

func test_new_location_character_dialogue_mission_and_puzzle_end_to_end() -> void:
	# 1. New location (planned, no scene yet) connected to an existing one.
	var loc := LocationDef.new()
	loc.id = "LOC_EC_BAKERY"
	loc.name_key = "UI_PAUSED"
	var door := LocationConnection.new()
	door.to_location = "LOC_EC_MAIN_STREET"
	loc.connections.assign([door])
	assert_true(DataRegistry.register_runtime(loc))
	# 2. New character with a dialogue.
	var chr := CharacterDef.new()
	chr.id = "BKR"
	chr.name_key = "UI_QUIT"
	chr.default_dialogue = "DLG_BAKER_HELLO"
	assert_true(DataRegistry.register_runtime(chr))
	var dlg := DialogueDef.new()
	dlg.id = "DLG_BAKER_HELLO"
	dlg.start_id = "hello"
	var line := DialogueNode.new()
	line.id = "hello"
	line.speaker_id = "BKR"
	line.text_key = "UI_RESUME"
	line.set_flags.assign(["met_baker"])
	dlg.nodes.assign([line])
	assert_true(DataRegistry.register_runtime(dlg))
	# 3. New puzzle.
	var puzzle := PuzzleDef.new()
	puzzle.id = "PZL_CH1_OVEN"
	puzzle.solution.assign(["a", "b"])
	puzzle.hint_keys.assign(["UI_RESUME", "UI_QUIT", "UI_PAUSED"])
	puzzle.reward_items.assign(["ITEM_ARCHIVE_CARD"])
	puzzle.accessibility_notes = "No timer."
	puzzle.title_key = "UI_PAUSED"
	var baker_state := StoryStateDef.new()
	baker_state.id = "met_baker"
	baker_state.description = "Test state: the baker was met."
	assert_true(DataRegistry.register_runtime(baker_state))
	assert_true(DataRegistry.register_runtime(puzzle))
	# 4. New mission wiring it all together.
	var mission := MissionDef.new()
	mission.id = "CH1_S77"
	mission.mission_type = MissionDef.Type.OPTIONAL
	mission.title_key = "UI_PAUSED"
	mission.locations.assign(["LOC_EC_BAKERY"])
	var talk := ObjectiveDef.new()
	talk.id = "talk"
	talk.text_key = "UI_RESUME"
	talk.objective_kind = ObjectiveDef.Kind.DIALOGUE
	talk.target = "DLG_BAKER_HELLO"
	var bake := ObjectiveDef.new()
	bake.id = "bake"
	bake.text_key = "UI_RESUME"
	bake.objective_kind = ObjectiveDef.Kind.PUZZLE
	bake.target = "PZL_CH1_OVEN"
	mission.objectives.assign([talk, bake])
	assert_true(DataRegistry.register_runtime(mission))
	# The whole content set validates (references, ids, translations) with no code change.
	var errors := DataRegistry.validate_all()
	assert_eq(errors.size(), 0, "\n".join(errors))
	# Play it.
	GameState.set_flag("ch1_started")
	MissionManager.refresh()
	assert_eq(MissionManager.state_of("CH1_S77"), MissionDef.State.ACTIVE)
	var ok: bool = await SceneRouter.change_location("LOC_EC_BAKERY")
	assert_true(ok, "unbuilt location is reachable through the placeholder scene")
	var npc: NpcActor = load("res://scenes/characters/npc_base.tscn").instantiate()
	npc.character_id = "BKR"
	SceneRouter.current_root.add_child(npc)
	(npc.get_node("Interactable") as Interactable).interact()
	DialogueManager.advance()
	assert_true(GameState.get_flag("met_baker"))
	assert_eq(MissionManager.get_progress("CH1_S77", "talk"), 1)
	PuzzleManager.submit("PZL_CH1_OVEN", "a")
	PuzzleManager.submit("PZL_CH1_OVEN", "b")
	assert_true(GameState.has_item("ITEM_ARCHIVE_CARD"), "puzzle reward")
	assert_eq(MissionManager.state_of("CH1_S77"), MissionDef.State.COMPLETE)
