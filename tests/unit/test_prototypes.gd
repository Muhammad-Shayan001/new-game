extends TestCase
## Prompt 08 completion gate: every ability is used in a real gameplay situation, and every
## prototype puzzle has a clear solution and completion state. These tests play the three
## graybox scenes through the real game scene and physics engine.

var game: GameRoot

func before_each() -> void:
	super.before_each()
	SettingsManager.path = "user://test_settings.cfg"
	SettingsManager.reset_to_defaults()

func after_each() -> void:
	Input.action_release("interact")
	get_tree().paused = false
	if game != null:
		game.queue_free()
		game = null
		await get_tree().process_frame
	SettingsManager.reset_to_defaults()

func _wait_until(condition: Callable, max_frames: int = 240) -> bool:
	for i in max_frames:
		if condition.call():
			return true
		await get_tree().physics_frame
	return false

func _boot() -> Player:
	SceneRouter.state = SceneRouter.State.IDLE
	SceneRouter.current_root = null
	SceneRouter.current_location_id = ""
	game = load("res://scenes/game_root.tscn").instantiate()
	add_child(game)
	await _wait_until(func(): return SceneRouter.current_location_id != "" and not SceneRouter.is_busy())
	return game.get_node("Player") as Player

func _goto(location_id: String) -> Node:
	await SceneRouter.change_location(location_id)
	await get_tree().physics_frame
	return SceneRouter.current_root

func _place(player: Player, pos: Vector3) -> void:
	player.place_at(Transform3D(Basis.IDENTITY, pos))

func _advance_abilities(seconds: float) -> void:
	for i in int(seconds / 0.1) + 1:
		AbilityManager._process(0.1)

# --- Memory Vision + Echo Detection: the clock room ----------------------------------------------------------
func test_clock_room_uses_memory_sight_pulse_logic_and_sequence() -> void:
	var player := await _boot()
	GameState.set_flag("ch1_started")
	AbilityManager.unlock("ABIL_MEMORY_SIGHT")
	MissionManager.refresh()
	assert_eq(MissionManager.state_of("CH1_S02"), MissionDef.State.ACTIVE, "the optional mission starts once Memory Sight is owned")
	# Clue 1 comes from another place: the station clock.
	var station := await _goto("LOC_UM_ECHO_STATION")
	(station.get_node("StationClock") as Interactable).interact()
	assert_true(GameState.has_clue("CLUE_STATION_CLOCK"))
	var room := await _goto("LOC_EC_HID_CLOCK_ROOM")
	assert_true(room is PrototypeLocation, "a real scene, not the placeholder")
	var writing := room.get_node("HiddenWriting") as Revealable
	var examine := writing.get_node("Examine") as Interactable
	var note := room.get_node("ClockmakerNote") as MemoryTrace
	var board := room.get_node("ClueBoard") as ClueBoard
	var lock := room.get_node("DialLock") as ConditionGate
	var dial4 := room.get_node("Dial4") as Interactable
	# Observation: nothing is visible until Memory Sight.
	assert_false(writing.visible)
	assert_false(examine.can_interact())
	assert_false(dial4.can_interact(), "the dial is locked")
	# Echo Detection leads to the hidden trace.
	var pulse := EchoDetection.pulse()
	assert_true(pulse["found"], "the pulse finds the clockmaker's note")
	assert_eq(pulse["trace_id"], "TRC_CH1_CLOCKMAKER_NOTE")
	assert_true(pulse["distance"] > 10.0 and pulse["distance"] < 20.0)
	assert_true(AbilityManager.activate("ABIL_MEMORY_SIGHT"))
	assert_true(writing.visible and note.visible, "Memory Sight reveals both")
	examine.interact()
	assert_true(GameState.has_clue("CLUE_CLOCK_WALL_WRITING"))
	(note.get_node("Examine") as Interactable).interact()
	assert_true(note.is_discovered())
	assert_eq(MissionManager.get_progress("CH1_S02", "find_the_note"), 1, "optional objective counted")
	# Logic: link the two clues on the board.
	assert_false(lock.is_open)
	board.interact()
	assert_true(PuzzleManager.is_solved("PZL_CH1_CLOCK_DEDUCTION"))
	assert_true(lock.is_open, "the dial lock opens")
	assert_eq(MissionManager.get_progress("CH1_S02", "link_the_clues"), 1)
	# Sequence: a wrong key, then the right keys.
	(room.get_node("Dial9") as Interactable).interact()
	assert_false(PuzzleManager.is_solved("PZL_CH1_CLOCK_4_17"))
	for digit in ["4", "1", "7"]:
		(room.get_node("Dial" + digit) as Interactable).interact()
	assert_true(PuzzleManager.is_solved("PZL_CH1_CLOCK_4_17"), "completion state")
	assert_true(GameState.get_flag("ch1_clock_solved"))
	assert_true(GameState.has_memory("CH1_F05"), "reward: The Clockmaker")
	assert_eq(MissionManager.state_of("CH1_S02"), MissionDef.State.COMPLETE)
	assert_false(EchoDetection.pulse()["found"] and false)
	EchoDetection._cooldown = 0.0
	assert_false(EchoDetection.pulse()["found"], "no undiscovered traces left")

# --- Reality Shift: the anchor fields --------------------------------------------------------------------------
func test_anchor_fields_use_reality_shift_to_cross_and_exit() -> void:
	var player := await _boot()
	AbilityManager.unlock("ABIL_REALITY_SHIFT")
	var field := await _goto("LOC_DL_ANCHOR_FIELDS")
	var bridge := field.get_node("Bridge") as ShiftableObject
	var sigil_holder := field.get_node("OtherSideSigil") as ShiftableObject
	var sigil := sigil_holder.get_node("Sigil") as Interactable
	var gate := field.get_node("ExitGate") as ConditionGate
	var portal := field.get_node("ExitPortal") as Interactable
	# Initial state: no bridge, no sigil, sealed exit.
	assert_eq(ShiftManager.get_state("SHF_CH3_ANCHOR_BRIDGE"), "echo_city")
	assert_false(bridge.visible)
	assert_false(sigil.can_interact(), "state-specific clue is not there yet")
	assert_false(portal.can_interact())
	assert_false(AbilityManager.activate("ABIL_REALITY_SHIFT"), "needs an anchor")
	# Anchor A: shift to the Other Side.
	_place(player, Vector3(0, 0.1, 4.5))
	assert_true(await _wait_until(func(): return ShiftManager.current_anchor() != null))
	assert_true(AbilityManager.activate("ABIL_REALITY_SHIFT"))
	assert_eq(ShiftManager.get_state("SHF_CH3_ANCHOR_BRIDGE"), "other_side")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_true(bridge.visible and bridge.solid, "alternate route appears")
	assert_true(sigil_holder.visible)
	# Walk across the real bridge collider.
	_place(player, Vector3(0, 0.1, 1.5))
	for i in 20:
		await get_tree().physics_frame
	assert_true(player.global_position.y > -0.5, "the bridge holds the player")
	_place(player, Vector3(3.5, 0.1, -5.5))
	await get_tree().physics_frame
	assert_true(sigil.can_interact())
	sigil.interact()
	assert_true(GameState.has_clue("CLUE_ANCHOR_SIGIL"), "state-specific clue")
	assert_false(gate.is_open, "needs Echo City as well")
	# Anchor B: back to Echo City, which opens the gate. The bridge disappears behind us.
	_place(player, Vector3(0, 0.1, -4.5))
	assert_true(await _wait_until(func(): return ShiftManager.current_anchor() != null and ShiftManager.current_anchor().name == "AnchorB"))
	_advance_abilities(1.2)
	await get_tree().create_timer(0.7).timeout
	assert_true(AbilityManager.activate("ABIL_REALITY_SHIFT"))
	assert_eq(ShiftManager.get_state("SHF_CH3_ANCHOR_BRIDGE"), "echo_city")
	assert_true(gate.is_open, "puzzle dependency: sigil clue AND echo_city")
	assert_false(bridge.visible)
	_place(player, Vector3(0, 0.1, -9.5))
	assert_true(portal.can_interact())
	portal.interact()
	assert_true(PuzzleManager.is_solved("PZL_CH3_ANCHOR_BRIDGE"), "completion state")
	assert_true(GameState.get_flag("shift_anchor_bridge_solved"))
	assert_true(field.get_node("KeptBridge").visible, "the route stays, nobody is stranded")

func test_anchor_fields_gate_stays_closed_without_the_sigil() -> void:
	var player := await _boot()
	var field := await _goto("LOC_DL_ANCHOR_FIELDS")
	var gate := field.get_node("ExitGate") as ConditionGate
	assert_false(gate.is_open)
	ShiftManager.set_state("SHF_CH3_ANCHOR_BRIDGE", "other_side")
	ShiftManager.busy = false
	ShiftManager.set_state("SHF_CH3_ANCHOR_BRIDGE", "echo_city")
	assert_false(gate.is_open, "echo_city alone is not enough")

func test_reality_shift_moves_the_player_out_of_a_new_solid_object() -> void:
	var player := await _boot()
	var field := await _goto("LOC_DL_ANCHOR_FIELDS")
	_place(player, Vector3(0, -0.15, 0.0))          # standing in the space the bridge will fill
	assert_true(ShiftManager.set_state("SHF_CH3_ANCHOR_BRIDGE", "other_side"))
	for i in 6:
		await get_tree().physics_frame
	assert_true(player.global_position.y > 0.3, "rescued to a safe point, not stuck inside the bridge")
	assert_true(absf(player.global_position.z) > 3.0, "moved to a platform")

func test_reality_shift_zone_state_is_restored_from_a_save() -> void:
	await _boot()
	await _goto("LOC_DL_ANCHOR_FIELDS")
	ShiftManager.set_state("SHF_CH3_ANCHOR_BRIDGE", "other_side")
	assert_true(SaveManager.save_game(0))
	game.queue_free()
	game = null
	await get_tree().process_frame
	GameState.reset()
	ShiftManager.reset_runtime()
	await _boot()                                    # GameRoot continues from the autosave slot
	assert_eq(SceneRouter.current_location_id, "LOC_DL_ANCHOR_FIELDS")
	assert_true((SceneRouter.current_root.get_node("Bridge") as ShiftableObject).visible, "the bridge is there after loading")
	assert_true((SceneRouter.current_root.get_node("OtherSideSigil/Sigil") as Interactable).enabled)

# --- Time Echo: the gallery ----------------------------------------------------------------------------------------
func test_gallery_time_echo_replay_then_memory_reconstruction() -> void:
	var player := await _boot()
	AbilityManager.unlock("ABIL_TIME_ECHO")
	GameState.set_flag("ch1_started")
	var gallery := await _goto("LOC_DL_ECHO_GALLERY")
	var board := gallery.get_node("ReelBoard") as ReconstructionBoard
	var circle := gallery.get_node("ReelBoard/Cards/tape_circle") as Interactable
	var square := gallery.get_node("ReelBoard/Cards/tape_square") as Interactable
	var triangle := gallery.get_node("ReelBoard/Cards/tape_triangle") as Interactable
	var slot := func(n: int): return gallery.get_node("ReelBoard/Slots/Slot%d" % n) as Interactable
	# Without watching, the player can still guess; a wrong order clears gently.
	triangle.interact()
	slot.call(1).interact()
	circle.interact()
	slot.call(2).interact()
	square.interact()
	slot.call(3).interact()
	assert_false(PuzzleManager.is_solved("PZL_CH3_TAPE_ORDER"))
	assert_eq(board.slots, ["", "", ""], "wrong arrangement clears the slots, no penalty")
	# Watch the echo at the Echo Site.
	_place(player, Vector3(-8, 0.1, 5))
	assert_true(await _wait_until(func(): return TimeEchoManager.current_site() != null))
	var captions := watch(EventBus.echo_caption)
	assert_true(AbilityManager.activate("ABIL_TIME_ECHO"))
	assert_true(TimeEchoManager.is_busy())
	TimeEchoManager.advance(10.0)
	assert_false(TimeEchoManager.is_busy())
	assert_eq(captions.size(), 4)
	assert_true(GameState.has_clue("CLUE_TAPE_ORDER"))
	assert_true("ECH_CH3_TAPE_LOADING" in GameState.echoes_seen)
	# Rebuild the order from the memory: circle, square, triangle.
	circle.interact()
	slot.call(1).interact()
	square.interact()
	slot.call(2).interact()
	assert_eq((gallery.get_node("ReelBoard/Slots/Slot2/Text") as Label3D).text, "2: Square reel", "slot text names the card")
	triangle.interact()
	slot.call(3).interact()
	assert_true(PuzzleManager.is_solved("PZL_CH3_TAPE_ORDER"), "completion state")
	assert_true(GameState.has_memory("CH3_F04"), "reward: Echo of a Birthday")
	assert_true(GameState.get_flag("tape_order_solved"))

func test_gallery_plates_are_solved_alone_with_an_echo_ghost() -> void:
	var player := await _boot()
	AbilityManager.unlock("ABIL_TIME_ECHO")
	var gallery := await _goto("LOC_DL_ECHO_GALLERY")
	var plate_a := gallery.get_node("PlateA") as PressurePlate
	var plate_b := gallery.get_node("PlateB") as PressurePlate
	# Alone, one plate is not enough.
	_place(player, Vector3(12, 0.1, -4))
	assert_true(await _wait_until(func(): return plate_b.pressed))
	await get_tree().create_timer(1.3).timeout
	assert_false(PuzzleManager.is_solved("PZL_CH3_ECHO_PLATES"), "needs both plates")
	# Record a walk onto plate A.
	_place(player, Vector3(8, 0.1, 8))
	assert_true(await _wait_until(func(): return TimeEchoManager.current_site() != null and TimeEchoManager.current_site().allow_recording))
	_advance_abilities(1.0)
	assert_true(AbilityManager.activate("ABIL_TIME_ECHO"))
	assert_true(TimeEchoManager.recording)
	for i in 40:
		_place(player, Vector3(8, 0.1, 8).lerp(Vector3(4, 0.1, -4), float(i) / 39.0))
		TimeEchoManager.advance(0.1)
	for i in 10:
		TimeEchoManager.advance(0.1)                    # stand on the plate a moment
	_advance_abilities(0.7)
	assert_true(AbilityManager.activate("ABIL_TIME_ECHO"))
	assert_false(TimeEchoManager.recording)
	var ghost := TimeEchoManager.player_echoes[0]
	ghost.advance(60.0)                                    # the ghost finishes its walk and stays on plate A
	assert_true(await _wait_until(func(): return plate_a.pressed), "the ghost holds plate A")
	_place(player, Vector3(12, 0.1, -4))
	assert_true(await _wait_until(func(): return PuzzleManager.is_solved("PZL_CH3_ECHO_PLATES"), 300), "completion state: both plates held for one second")
	assert_true(GameState.get_flag("echo_plates_solved"))

func test_leaving_and_returning_resets_the_unsolved_plates_puzzle() -> void:
	var player := await _boot()
	AbilityManager.unlock("ABIL_TIME_ECHO")
	await _goto("LOC_DL_ECHO_GALLERY")
	assert_false(PuzzleManager.is_solved("PZL_CH3_ECHO_PLATES"), "the puzzle starts unsolved")
	var resets := watch(EventBus.puzzle_reset)
	var left := await SceneRouter.change_location("LOC_DL_ANCHOR_FIELDS")
	assert_true(left)
	assert_true(resets.size() >= 1, "ON_LEAVE reset policy")
	assert_eq(TimeEchoManager.player_echoes.size(), 0)

# --- the completion gate as data -------------------------------------------------------------------------------------
func test_every_ability_is_used_in_a_real_gameplay_situation() -> void:
	var needed := {"ABIL_MEMORY_SIGHT": false, "ABIL_REALITY_SHIFT": false, "ABIL_TIME_ECHO": false}
	for p in DataRegistry.all("puzzle"):
		var loc := DataRegistry.get_location(p.location_id)
		for a in p.required_abilities:
			if needed.has(a) and loc.status != LocationDef.BuildStatus.PLANNED:
				needed[a] = true
	for a in needed:
		assert_true(needed[a], "%s is required by a puzzle in a playable scene" % a)
	for id in ["CH1_M02", "CH3_M01"]:
		assert_false(DataRegistry.get_mission(id).reward_abilities.is_empty(), "%s grants an ability, so the player owns it before the puzzle" % id)
	assert_true("ABIL_MEMORY_SIGHT" in DataRegistry.get_mission("CH1_M02").reward_abilities)
	assert_true("ABIL_REALITY_SHIFT" in DataRegistry.get_mission("CH3_M01").reward_abilities)
	assert_true("ABIL_TIME_ECHO" in DataRegistry.get_mission("CH3_M01").reward_abilities)
