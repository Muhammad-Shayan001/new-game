extends TestCase
## Save/load: round trip, backup fallback, tamper detection, version rules, migration.

func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()

func test_round_trip_all_state() -> void:
	GameState.set_chapter(2)
	GameState.set_flag("spared_forgotten")
	GameState.set_flag("deep_fragments", 1)
	GameState.add_clue("CLUE_A")
	GameState.unlock_memory("CH1_F01")
	GameState.enter_location("LOC_EC_MAIN_STREET", "from_station")
	GameState.mission_states["CH1_M01"] = MissionDef.State.COMPLETE
	GameState.mission_progress["CH1_M02"] = {"reach_ec_main_street": 1}
	GameState.inventory["ITEM_ARCHIVE_CARD"] = 1
	GameState.abilities.append("ABIL_MEMORY_SIGHT")
	GameState.puzzles["PZL_CH1_CLOCK_4_17"] = {"solved": true, "hints": 2}
	GameState.choices.append("asked_maya_if_real")
	GameState.shift_states["SHF_CH3_ANCHOR_BRIDGE"] = "other_side"
	GameState.discovered_traces.append("TRC_CH1_CLOCKMAKER_NOTE")
	GameState.info.append("INFO_ARV_KEEPS_RECORDS")
	GameState.echoes_seen.append("ECH_CH3_TAPE_LOADING")
	GameState.mission_checkpoints["CH1_M02"] = {"location": "LOC_EC_SAFE_ROOM", "spawn": "default", "objectives_done": 2}
	MissionManager.refresh()   # loading re-evaluates missions, so start from the refreshed state
	var expected := GameState.to_dict()
	assert_true(SaveManager.save_game(1))
	GameState.reset()
	assert_true(SaveManager.load_game(1))
	assert_eq(GameState.to_dict(), expected)

func test_invalid_slot_is_refused() -> void:
	assert_false(SaveManager.save_game(9))
	assert_false(SaveManager.load_game(9))

func test_missing_slot() -> void:
	assert_false(SaveManager.load_game(2))
	assert_eq(SaveManager.last_error, "no save file")

func test_backup_used_when_main_file_is_corrupt() -> void:
	GameState.set_flag("first")
	SaveManager.save_game(1)
	GameState.set_flag("second")
	SaveManager.save_game(1)               # first save becomes the .bak
	_write(SaveManager.slot_path(1), "{ not json")
	GameState.reset()
	assert_true(SaveManager.load_game(1), SaveManager.last_error)
	assert_true(GameState.get_flag("first"))
	assert_false(GameState.get_flag("second"), "backup is the older save")

func test_tampered_save_is_rejected() -> void:
	GameState.set_chapter(1)
	SaveManager.save_game(3)
	var text := FileAccess.get_file_as_string(SaveManager.slot_path(3))
	var data: Dictionary = JSON.parse_string(text)
	data["state_json"] = (data["state_json"] as String).replace('"chapter":1', '"chapter":6')
	_write(SaveManager.slot_path(3), JSON.stringify(data))
	GameState.reset()
	assert_false(SaveManager.load_game(3))
	assert_true(SaveManager.last_error.contains("checksum"), SaveManager.last_error)
	assert_eq(GameState.chapter, 1, "state untouched by a bad save")

func test_newer_save_version_is_refused() -> void:
	SaveManager.save_game(1)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveManager.slot_path(1)))
	data["version"] = GameVersion.SAVE_VERSION + 1
	_write(SaveManager.slot_path(1), JSON.stringify(data))
	assert_false(SaveManager.load_game(1))
	assert_true(SaveManager.last_error.contains("newer"), SaveManager.last_error)

func test_legacy_v1_save_is_migrated() -> void:
	DirAccess.make_dir_recursive_absolute(SaveManager.save_dir)
	var legacy := {"version": 1, "state": {"chapter": 2, "flags": {"ch1_started": true, "deep_fragments": 1.0},
		"clues": ["CLUE_A"], "memories": ["CH1_F01"], "current_location": "LOC_EC_MAIN_STREET",
		"visited_locations": ["LOC_UM_ECHO_STATION"]}}
	_write(SaveManager.slot_path(2), JSON.stringify(legacy))
	assert_true(SaveManager.load_game(2), SaveManager.last_error)
	assert_eq(GameState.chapter, 2)
	assert_eq(typeof(GameState.get_flag("deep_fragments")), TYPE_INT)
	assert_eq(GameState.inventory.size(), 0)
	assert_eq(GameState.last_spawn_id, "default")

func test_list_and_delete_slots() -> void:
	GameState.set_chapter(3)
	SaveManager.save_game(2)
	var slots := SaveManager.list_slots()
	assert_eq(slots.size(), 4)
	assert_true(slots[2]["exists"])
	assert_eq(slots[2]["chapter"], 3)
	assert_false(slots[1]["exists"])
	SaveManager.delete_slot(2)
	assert_false(SaveManager.list_slots()[2]["exists"])

func test_autosave_respects_blocks() -> void:
	GameState.autosave_blocks = 1
	assert_false(SaveManager.autosave("test"))
	GameState.autosave_blocks = 0
	assert_true(SaveManager.autosave("test"))
	assert_true(FileAccess.file_exists(SaveManager.slot_path(0)))

func test_v2_save_is_migrated_to_v3() -> void:
	DirAccess.make_dir_recursive_absolute(SaveManager.save_dir)
	var state := {"chapter": 3, "flags": {}, "mission_states": {"CH1_M01": 3}, "inventory": {}, "abilities": []}
	var text := JSON.stringify(state, "", true)
	var envelope := {"version": 2, "game_version": "0.1.0", "saved_at": 1, "meta": {}, "checksum": text.sha256_text(), "state_json": text}
	_write(SaveManager.slot_path(1), JSON.stringify(envelope))
	assert_true(SaveManager.load_game(1), SaveManager.last_error)
	assert_eq(GameState.chapter, 3)
	assert_eq(GameState.shift_states.size(), 0)
	assert_eq(GameState.info.size(), 0)
	assert_eq(GameState.mission_checkpoints.size(), 0)
