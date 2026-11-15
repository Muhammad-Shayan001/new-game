extends TestCase
## IDs, conditions, game state and the data registry.

func test_id_rules_accept_and_reject() -> void:
	assert_true(IdRules.is_valid("location", "LOC_UM_ECHO_STATION"))
	assert_false(IdRules.is_valid("location", "LOC_ECHO"))
	assert_true(IdRules.is_valid("mission", "CH1_M01"))
	assert_true(IdRules.is_valid("mission", "CH6_S03"))
	assert_false(IdRules.is_valid("mission", "CH7_M01"))
	assert_true(IdRules.is_valid("fragment", "CH3_F05"))
	assert_true(IdRules.is_valid("character", "ALX"))
	assert_false(IdRules.is_valid("character", "Alex"))
	assert_true(IdRules.is_valid("flag", "ch1_started"))
	assert_false(IdRules.is_valid("flag", "Ch1Started"))
	assert_false(IdRules.is_valid("nonsense", "X"))

func test_registry_loads_world_data() -> void:
	assert_eq(DataRegistry.all("location").size(), 47)
	assert_eq(DataRegistry.all("fragment").size(), 30)
	assert_eq(DataRegistry.all("mission").size(), 31)
	assert_eq(DataRegistry.all("character").size(), 5)
	assert_eq(DataRegistry.all("ability").size(), 4)
	assert_true(DataRegistry.has_def("dialogue", "DLG_CH1_M03_CATALOGUE"))
	assert_eq(DataRegistry.get_location("LOC_UM_ECHO_STATION").status, LocationDef.BuildStatus.GRAYBOX)

func test_registry_content_is_valid() -> void:
	var errors := DataRegistry.validate_all()
	assert_eq(errors.size(), 0, "\n".join(errors))

func test_registry_catches_bad_content() -> void:
	var bad := MissionDef.new()
	bad.id = "CH1_M98"
	bad.title_key = "MISSING_KEY"
	bad.locations.assign(["LOC_XX_NOWHERE"])
	assert_true(DataRegistry.register_runtime(bad))
	assert_false(DataRegistry.register_runtime(bad), "duplicate id refused")
	var errors := DataRegistry.validate_all()
	var text := "\n".join(errors)
	assert_true(text.contains("at least one objective"), text)
	assert_true(text.contains("unknown location 'LOC_XX_NOWHERE'"), text)
	assert_true(text.contains("missing translation for 'MISSING_KEY'"), text)
	DataRegistry.reload()

func test_condition_set() -> void:
	var c := ConditionSet.new()
	assert_true(c.is_met(), "empty set is always met")
	c.flags_all.assign(["a", "b"])
	assert_false(c.is_met())
	GameState.set_flag("a")
	GameState.set_flag("b")
	assert_true(c.is_met())
	c.flags_none.assign(["blocked"])
	GameState.set_flag("blocked")
	assert_false(c.is_met())
	GameState.set_flag("blocked", false)
	c.flags_any.assign(["x", "y"])
	assert_false(c.is_met())
	GameState.set_flag("y")
	assert_true(c.is_met())
	c.min_chapter = 3
	assert_false(c.is_met())
	GameState.set_chapter(3)
	assert_true(c.is_met())
	c.items_all.assign(["ITEM_ARCHIVE_CARD"])
	assert_false(c.is_met())
	InventoryManager.add_item("ITEM_ARCHIVE_CARD")
	assert_true(c.is_met())
	assert_true(ConditionSet.check(null))

func test_game_state_round_trip_keeps_integer_types() -> void:
	GameState.set_flag("deep_fragments", 2)
	GameState.set_chapter(4)
	GameState.inventory["ITEM_LUGGAGE_TAG"] = 3
	GameState.add_relationship("maya_trust", 2)
	var json := JSON.stringify(GameState.to_dict())
	var parsed: Dictionary = JSON.parse_string(json)
	GameState.reset()
	GameState.from_dict(parsed)
	assert_eq(GameState.chapter, 4)
	assert_eq(GameState.get_flag("deep_fragments"), 2)
	assert_eq(typeof(GameState.get_flag("deep_fragments")), TYPE_INT)
	assert_eq(GameState.inventory["ITEM_LUGGAGE_TAG"], 3)
	assert_eq(GameState.get_relationship("maya_trust"), 2)

func test_relationships_are_clamped() -> void:
	GameState.add_relationship("maya_trust", 10)
	assert_eq(GameState.get_relationship("maya_trust"), 3)
	GameState.add_relationship("maya_trust", -20)
	assert_eq(GameState.get_relationship("maya_trust"), -3)

func test_reset_restores_defaults() -> void:
	GameState.set_flag("x")
	GameState.add_clue("CLUE_A")
	GameState.reset()
	assert_false(GameState.get_flag("x"))
	assert_eq(GameState.clues.size(), 0)
	assert_eq(GameState.chapter, 1)
	assert_eq(GameState.current_location, LocationIDs.UM_ECHO_STATION)

func test_translations_resolve() -> void:
	assert_eq(Localization.t("LOC_UM_ECHO_STATION"), "Echo Station")
	assert_eq(Localization.t("UI_RESUME"), "Resume")
	assert_eq(Localization.t("DLG_CH1_M03_CATALOGUE_ARV_006"), "Take this card. Find what was removed.")
	assert_eq(Localization.t("NOT_A_REAL_KEY"), "NOT_A_REAL_KEY")
	assert_true(GameLog.warning_count > 0, "missing key is reported")
