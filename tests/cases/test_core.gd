extends "res://tests/test_case.gd"

func test_condition_logic() -> void:
	GameState.set_flag("a", true)
	ok(Condition.check({}), "empty passes")
	ok(Condition.check(null), "null passes")
	ok(Condition.check({"flag": "a"}), "flag")
	ok(not Condition.check({"flag": "b"}), "missing flag fails")
	ok(Condition.check({"not": {"flag": "b"}}), "not")
	ok(Condition.check({"any": [{"flag": "b"}, {"flag": "a"}]}), "any")
	ok(not Condition.check({"all": [{"flag": "a"}, {"flag": "b"}]}), "all")
	GameState.adjust_relationship("maya_trust", 2)
	ok(Condition.check({"rel_gte": ["maya_trust", 2]}), "rel_gte")
	ok(not Condition.check({"rel_lte": ["maya_trust", 1]}), "rel_lte")
	ok(Condition.check({"chapter_gte": 1}) and not Condition.check({"chapter_gte": 2}), "chapter_gte")
	ok(not Condition.check({"totally_unknown": 1}), "unknown key fails closed")

func test_effects_run_and_unknown_ops_are_safe() -> void:
	Effects.run([{"do": "set_flag", "flag": "x"}, {"do": "adjust_rel", "key": "k", "delta": 5},
		{"do": "add_item", "id": "ITEM_ARCHIVE_CARD"}, {"do": "collect_fragment", "id": "CH1_F01"},
		{"do": "unlock_ability", "id": "ABL_MEMORY_SIGHT"}, {"do": "no_such_op"}])
	ok(GameState.get_flag("x"), "flag set")
	eq(GameState.get_relationship("k"), 3, "relationship clamps at +3")
	ok(InventoryManager.has_item("ITEM_ARCHIVE_CARD"), "item added")
	ok(MemoryManager.has_fragment("CH1_F01"), "fragment collected")
	ok(AbilityManager.is_unlocked("ABL_MEMORY_SIGHT"), "ability unlocked")

func test_inventory_rules() -> void:
	ok(InventoryManager.add_item("ITEM_TUNING_FORK"), "add")
	ok(not InventoryManager.add_item("ITEM_TUNING_FORK"), "non-stackable cannot duplicate")
	ok(not InventoryManager.add_item("ITEM_DOES_NOT_EXIST"), "unknown item rejected")
	ok(InventoryManager.remove_item("ITEM_TUNING_FORK"), "remove")
	ok(not InventoryManager.has_item("ITEM_TUNING_FORK"), "gone")

func test_memory_fragments() -> void:
	ok(MemoryManager.collect("CH2_F05"), "deep fragment")
	ok(not MemoryManager.collect("CH2_F05"), "no double collect")
	eq(MemoryManager.deep_count(), 1, "deep count")
	eq(MemoryManager.collected_in_chapter(2), 1, "chapter count")
	ok(not MemoryManager.collect("NOPE"), "unknown rejected")

func test_puzzles() -> void:
	ok(not PuzzleManager.submit("PZL_EC_01", ["house", "lake", "wave"]), "wrong order fails")
	ok(not PuzzleManager.is_solved("PZL_EC_01"))
	var key := PuzzleManager.hint("PZL_EC_01")
	ok(key != "", "hint tier 1")
	PuzzleManager.hint("PZL_EC_01")
	PuzzleManager.hint("PZL_EC_01")
	eq(PuzzleManager.hint("PZL_EC_01"), "", "no hint beyond tier 3")
	ok(PuzzleManager.submit("PZL_EC_01", ["wave", "house", "lake"]), "correct order")
	ok(InventoryManager.has_item("ITEM_CHILD_DRAWING"), "solve reward applied from data")
	ok(GameState.get_flag("found_child_drawing"), "solve flag")

func test_hint_tier_setting_respected() -> void:
	Settings.set_value("hint_tier_max", 1, false)
	ok(PuzzleManager.hint("PZL_EC_01") != "", "first hint")
	eq(PuzzleManager.hint("PZL_EC_01"), "", "capped by setting")

func test_abilities_activation_and_cooldown() -> void:
	ok(not AbilityManager.request_activate("ABL_TIME_ECHO"), "locked ability cannot activate")
	ok(AbilityManager.is_unlocked("ABL_MEMORY_SIGHT"), "CH1_M01 on_start unlocks Memory Sight")
	ok(AbilityManager.request_activate("ABL_MEMORY_SIGHT"), "activates")
	ok(not AbilityManager.request_activate("ABL_MEMORY_SIGHT"), "cannot stack")
	AbilityManager._process(9.0)    # duration 8s elapses
	eq(AbilityManager.active_id, "", "ended after duration")
	ok(AbilityManager.cooldown_left("ABL_MEMORY_SIGHT") > 0.0, "cooldown running")
	ok(not AbilityManager.can_activate("ABL_MEMORY_SIGHT"), "blocked during cooldown")
	AbilityManager._process(7.0)
	ok(AbilityManager.can_activate("ABL_MEMORY_SIGHT"), "available again")

func test_memory_sight_reveals_hidden_targets() -> void:
	var n := Node3D.new()
	n.visible = false
	n.add_to_group("memory_sight_target")
	tree.root.add_child(n)
	AbilityManager.unlock("ABL_MEMORY_SIGHT")
	AbilityManager.request_activate("ABL_MEMORY_SIGHT")
	ok(n.visible, "revealed while active")
	AbilityManager.end_active()
	ok(not n.visible, "hidden again after")
	n.queue_free()

func test_localization() -> void:
	eq(Loc.t("ui.new_game"), "New Game", "english")
	eq(Loc.t("obj.reach", {"place": "X"}), "Go to X", "placeholders")
	Loc.set_language("ur")
	ok(Loc.t("ui.new_game") != "New Game", "urdu translation")
	eq(Loc.t("ui.puzzle"), "Puzzle", "falls back to English for untranslated keys")
	ok(Loc.is_rtl(), "urdu is RTL")
	Loc.set_language("en")
	eq(Loc.t("no.such.key"), "no.such.key", "missing key returns key")

func test_settings_persist_and_validate() -> void:
	Settings.set_value("camera_sensitivity", 1.7)
	eq(Settings.value("camera_sensitivity"), 1.7, "set")
	Settings.load_settings()
	eq(Settings.value("camera_sensitivity"), 1.7, "survives reload from disk")
	Settings.set_value("not_a_setting", 1)
	ok(Settings.value("not_a_setting") == null, "unknown keys rejected")

func test_network_manager_offline_and_host() -> void:
	ok(Net.is_authority(), "single player is authoritative")
	ok(not Net.is_online(), "offline by default")
	ok(Net.host(17777), "can host")
	eq(Net.state, "hosting", "hosting state")
	ok(Net.is_authority(), "host is authority")
	ok(not Net.host(17777), "cannot host twice")
	Net.leave()
	eq(Net.state, "offline", "left")
