class_name MissionFixtures
extends RefCounted
## Test missions for the mission system (Prompt 09). They are registered at runtime, never
## written to resources/, so they cannot change the real chapters. Chapter 6 optional ids.
##   CH6_S90  linear chain start       -> unlocks CH6_S91 on completion
##   CH6_S91  chain follower           -> needs CH6_S90, completes on a flag
##   CH6_S92  failure + recovery       -> fails when flag t92_broken is set
##   CH6_S93  conditional + group      -> a route objective that only applies after a flag
##   CH6_S94  story states + rewards   -> sets states, grants info, an item and a clue

static func _state(id: String, desc: String = "Test state.") -> StoryStateDef:
	var s := StoryStateDef.new()
	s.id = id
	s.description = desc
	return s

static func _obj(id: String, kind: ObjectiveDef.Kind, target: String, count: int = 1) -> ObjectiveDef:
	var o := ObjectiveDef.new()
	o.id = id
	o.objective_kind = kind
	o.target = target
	o.count = count
	o.text_key = "UI_RESUME"
	return o

static func _mission(id: String, objectives: Array) -> MissionDef:
	var m := MissionDef.new()
	m.id = id
	m.mission_type = MissionDef.Type.OPTIONAL
	m.chapter = 6
	m.title_key = "UI_PAUSED"
	m.objectives.assign(objectives)
	return m

## Registers everything; GameState.chapter must be >= 6 for the missions to unlock.
static func register_all() -> void:
	for id in ["t90_done", "t91_done", "t92_broken", "t93_hard_route", "t94_rewarded", "t93_done"]:
		DataRegistry.register_runtime(_state(id))
	var counter := _state("t94_level", "Test counter.")
	counter.value_type = StoryStateDef.ValueType.INT
	counter.max_value = 5
	DataRegistry.register_runtime(counter)
	var s90 := _mission("CH6_S90", [_obj("go", ObjectiveDef.Kind.REACH_LOCATION, "LOC_UM_CONCOURSE"),
		_obj("flag", ObjectiveDef.Kind.FLAG, "t90_done")])
	DataRegistry.register_runtime(s90)
	var s91 := _mission("CH6_S91", [_obj("finish", ObjectiveDef.Kind.FLAG, "t91_done")])
	s91.unlock = ConditionSet.new()
	s91.unlock.missions_complete.assign(["CH6_S90"])
	DataRegistry.register_runtime(s91)
	var s92 := _mission("CH6_S92", [_obj("a", ObjectiveDef.Kind.REACH_LOCATION, "LOC_UM_CONCOURSE"),
		_obj("b", ObjectiveDef.Kind.REACH_LOCATION, "LOC_EC_MAIN_STREET"), _obj("c", ObjectiveDef.Kind.REACH_LOCATION, "LOC_EC_PARK")])
	s92.fail_flags.assign(["t92_broken"])
	s92.respawn_location = "LOC_UM_ECHO_STATION"
	DataRegistry.register_runtime(s92)
	var easy := _obj("easy_route", ObjectiveDef.Kind.ITEM, "ITEM_ARCHIVE_CARD")
	easy.group = "way_in"
	var hard := _obj("hard_route", ObjectiveDef.Kind.FLAG, "t93_hard_route")
	hard.group = "way_in"
	var bonus := _obj("bonus_if_hard", ObjectiveDef.Kind.FLAG, "t93_done")
	bonus.conditions = ConditionSet.new()
	bonus.conditions.flags_all.assign(["t93_hard_route"])
	var s93 := _mission("CH6_S93", [easy, hard, bonus])
	DataRegistry.register_runtime(s93)
	var s94 := _mission("CH6_S94", [_obj("go", ObjectiveDef.Kind.REACH_LOCATION, "LOC_UM_CONCOURSE")])
	s94.complete_states = {"t94_rewarded": true, "t94_level": 3}
	s94.reward_info.assign(["INFO_ARV_KEEPS_RECORDS"])
	s94.reward_items.assign(["ITEM_ARCHIVE_CARD"])
	s94.reward_clues.assign(["CLUE_T94_REWARD"])
	DataRegistry.register_runtime(s94)
