extends "res://tests/test_case.gd"

func _populate() -> void:
	GameState.set_flag("f1", true)
	GameState.set_chapter(3)
	GameState.adjust_relationship("maya_trust", 2)
	GameState.enter_location("LOC_EC_MAIN_STREET")
	InventoryManager.add_item("ITEM_ARCHIVE_CARD")
	MemoryManager.collect("CH2_F05")
	PuzzleManager.mark_solved("PZL_EC_01")
	AbilityManager.unlock("ABL_REALITY_SHIFT")

func test_round_trip_all_systems() -> void:
	_populate()
	ok(SaveManager.save_game(2), "save")
	SaveManager.reset_all()
	eq(GameState.chapter, 1, "reset worked")
	ok(SaveManager.load_game(2), "load")
	eq(GameState.chapter, 3, "chapter")
	ok(GameState.get_flag("f1"), "flag")
	eq(GameState.get_relationship("maya_trust"), 2, "relationship")
	eq(GameState.current_location, "LOC_EC_MAIN_STREET", "location")
	ok(InventoryManager.has_item("ITEM_ARCHIVE_CARD"), "inventory")
	ok(MemoryManager.has_fragment("CH2_F05"), "memory")
	ok(PuzzleManager.is_solved("PZL_EC_01"), "puzzle")
	ok(AbilityManager.is_unlocked("ABL_REALITY_SHIFT"), "ability")
	SaveManager.delete_slot(2)

func test_mission_progress_survives_save() -> void:
	EventBus.location_entered.emit("LOC_UM_ECHO_STATION")
	SaveManager.save_game(2)
	var before := MissionManager.objectives_done("CH1_M01")
	SaveManager.reset_all()
	SaveManager.load_game(2)
	eq(MissionManager.objectives_done("CH1_M01"), before, "objective progress restored")
	eq(MissionManager.get_state("CH1_M01"), "ACTIVE", "state restored")
	SaveManager.delete_slot(2)

func test_migration_from_schema_1() -> void:
	var old := {"version": 1, "state": {"chapter": 2, "flags": {"x": true}, "clues": ["ITEM_ARCHIVE_CARD"],
		"memories": ["CH1_F01"], "current_location": "LOC_EC_PARK", "visited_locations": ["LOC_EC_PARK"]}}
	var f := FileAccess.open("user://saves/slot_3.json", FileAccess.WRITE)
	if f == null:
		DirAccess.make_dir_recursive_absolute("user://saves")
		f = FileAccess.open("user://saves/slot_3.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(old))
	f.close()
	ok(SaveManager.load_game(3), "v1 save loads")
	eq(GameState.chapter, 2, "chapter migrated")
	ok(InventoryManager.has_item("ITEM_ARCHIVE_CARD"), "clues became items")
	ok(MemoryManager.has_fragment("CH1_F01"), "memories became fragments")
	SaveManager.delete_slot(3)

func test_newer_schema_rejected() -> void:
	DirAccess.make_dir_recursive_absolute("user://saves")
	var f := FileAccess.open("user://saves/slot_3.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"schema_version": 99, "systems": {}}))
	f.close()
	ok(not SaveManager.load_game(3), "future save refused")
	SaveManager.delete_slot(3)

func test_corrupt_save_falls_back_to_backup() -> void:
	GameState.set_chapter(4)
	SaveManager.save_game(2)
	GameState.set_chapter(5)
	SaveManager.save_game(2)               # creates .bak of the chapter-4 save
	var f := FileAccess.open("user://saves/slot_2.json", FileAccess.WRITE)
	f.store_string("{ this is not json")
	f.close()
	ok(SaveManager.load_game(2), "loads from backup")
	eq(GameState.chapter, 4, "backup content")
	SaveManager.delete_slot(2)

func test_missing_slot_and_invalid_slot() -> void:
	ok(not SaveManager.load_game(3), "empty slot")
	ok(not SaveManager.save_game(9), "invalid slot rejected")
	eq(SaveManager.slot_info(3), {}, "no info for empty slot")

func test_provider_interface_enforced() -> void:
	var bad := Node.new()
	SaveManager.register_provider("bad", bad)
	ok(not SaveManager.provider_keys().has("bad"), "provider without interface rejected")
	bad.free()
