extends Node
## Data-driven missions. Definitions: resources/missions/*.json (see docs/DATA_SCHEMA.md).
## States: LOCKED -> AVAILABLE -> ACTIVE -> COMPLETE. Objectives complete from story events
## (location_entered, interacted, item_added, fragment_collected, dialogue_finished, puzzle_solved,
## flag_set) or from a Condition. All rewards are Effects, so no mission needs custom code.

const SAVE_KEY := "missions"
const LOCKED := "LOCKED"
const AVAILABLE := "AVAILABLE"
const ACTIVE := "ACTIVE"
const COMPLETE := "COMPLETE"

var _states: Dictionary = {}       # mission_id -> state
var _done: Dictionary = {}         # mission_id -> Array of completed objective ids
var _refreshing: bool = false

func _ready() -> void:
	SaveManager.register_provider(SAVE_KEY, self)
	EventBus.location_entered.connect(func(id): on_event("location_entered", id))
	EventBus.interacted.connect(func(id): on_event("interacted", id))
	EventBus.item_added.connect(func(id): on_event("item_added", id))
	EventBus.fragment_collected.connect(func(id): on_event("fragment_collected", id))
	EventBus.dialogue_finished.connect(func(id): on_event("dialogue_finished", id))
	EventBus.puzzle_solved.connect(func(id): on_event("puzzle_solved", id))
	EventBus.flag_changed.connect(func(f, v): if v: on_event("flag_set", f))
	reset_data()

func _ensure_states() -> void:
	for id: String in DataRegistry.ids("missions"):
		if not _states.has(id):
			_states[id] = LOCKED
			_done[id] = []

func get_state(id: String) -> String:
	return str(_states.get(id, LOCKED))

func is_complete(id: String) -> bool:
	return get_state(id) == COMPLETE

func active_ids() -> Array:
	var out: Array = []
	for id: String in _states:
		if _states[id] == ACTIVE:
			out.append(id)
	out.sort()
	return out

func start_mission(id: String) -> void:
	if not DataRegistry.has_def("missions", id):
		Log.error("Mission", "Unknown mission '%s'" % id)
		return
	if get_state(id) == ACTIVE or get_state(id) == COMPLETE:
		return
	_set_state(id, ACTIVE)
	Effects.run(DataRegistry.get_def("missions", id).get("on_start", []))
	_check_objectives(id, "", "")

func complete_objective(mission_id: String, objective_id: String) -> void:
	if get_state(mission_id) != ACTIVE:
		return
	if objective_id in _done[mission_id]:
		return
	_done[mission_id].append(objective_id)
	EventBus.objective_completed.emit(mission_id, objective_id)
	_try_complete(mission_id)

func objectives_done(id: String) -> Array:
	return _done.get(id, []).duplicate()

func on_event(event: String, arg: String) -> void:
	for id in active_ids():
		_check_objectives(id, event, arg)
	refresh()

func _check_objectives(id: String, event: String, arg: String) -> void:
	if get_state(id) != ACTIVE:
		return
	for obj: Dictionary in DataRegistry.get_def("missions", id)["objectives"]:
		var oid: String = obj["id"]
		if oid in _done[id]:
			continue
		var cw: Dictionary = obj.get("complete_when", {})
		var hit := false
		if cw.has("event"):
			hit = (cw["event"] == event and (not cw.has("arg") or cw["arg"] == arg))
		if cw.has("condition") and Condition.check(cw["condition"]):
			hit = true
		if hit:
			_done[id].append(oid)
			EventBus.objective_completed.emit(id, oid)
	_try_complete(id)

func _try_complete(id: String) -> void:
	if get_state(id) != ACTIVE:
		return
	for obj: Dictionary in DataRegistry.get_def("missions", id)["objectives"]:
		if not obj.get("optional", false) and obj["id"] not in _done[id]:
			return
	_set_state(id, COMPLETE)
	Effects.run(DataRegistry.get_def("missions", id).get("on_complete", []))

## Unlocks missions whose requirements are now met and auto-starts them.
func refresh() -> void:
	if _refreshing:
		return
	_refreshing = true
	var changed := true
	while changed:
		changed = false
		for id: String in DataRegistry.ids("missions"):
			if _states[id] != LOCKED:
				continue
			var def := DataRegistry.get_def("missions", id)
			if Condition.check(def.get("unlock_requires", {})):
				_set_state(id, AVAILABLE)
				changed = true
				if def.get("auto_start", true):
					start_mission(id)
	_refreshing = false

func _set_state(id: String, state: String) -> void:
	_states[id] = state
	EventBus.mission_state_changed.emit(id, state)

## Text for the HUD: the highest-priority active mission (Main before Secondary, then "priority"
## field, then id) and its first unfinished objective.
func current_objective_text() -> String:
	var best_id := ""
	var best_rank := -1
	for id in active_ids():
		var def := DataRegistry.get_def("missions", id)
		if _first_open_objective(id).is_empty():
			continue
		var rank := int(def.get("priority", 0)) * 10 + (5 if def["type"] == "Main" else 0)
		if rank > best_rank:
			best_rank = rank
			best_id = id
	if best_id == "":
		return ""
	var def := DataRegistry.get_def("missions", best_id)
	var obj := _first_open_objective(best_id)
	var args := {}
	for k: String in obj.get("args_keys", {}):
		args[k] = Loc.t(str(obj["args_keys"][k]))
	return "%s: %s" % [Loc.t(def["name_key"]), Loc.t(obj["text_key"], args)]

func _first_open_objective(id: String) -> Dictionary:
	for obj: Dictionary in DataRegistry.get_def("missions", id)["objectives"]:
		if obj["id"] not in _done[id]:
			return obj
	return {}

func save_data() -> Dictionary:
	return {"states": _states.duplicate(), "objectives_done": _done.duplicate(true)}

func load_data(d: Dictionary) -> void:
	_states = {}
	_done = {}
	_ensure_states()
	for k: String in d.get("states", {}):
		if _states.has(k):
			_states[k] = str(d["states"][k])
	for k: String in d.get("objectives_done", {}):
		if _done.has(k):
			_done[k] = d["objectives_done"][k].duplicate()

func reset_data() -> void:
	_states = {}
	_done = {}
	_ensure_states()
