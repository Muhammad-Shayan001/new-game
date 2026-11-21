extends Node
## Tracks objective progress for every ACTIVE mission. Gameplay events (EventBus and
## GameState signals) increment counters; MissionManager decides what completion means.
## Supports counted, optional, conditional and alternative-route (group) objectives.

const K := ObjectiveDef.Kind

func _ready() -> void:
	EventBus.scene_transition_finished.connect(func(loc): handle(K.REACH_LOCATION, loc))
	EventBus.interaction_completed.connect(func(id): handle(K.INTERACT, id))
	EventBus.fragment_collected.connect(func(id): handle(K.FRAGMENT, id))
	EventBus.item_added.connect(func(id, n): handle(K.ITEM, id, n))
	EventBus.clue_added.connect(func(id): handle(K.CLUE, id))
	EventBus.puzzle_solved.connect(func(id): handle(K.PUZZLE, id))
	EventBus.dialogue_finished.connect(func(id): handle(K.DIALOGUE, id))
	EventBus.trace_discovered.connect(func(id): handle(K.TRACE, id))
	EventBus.echo_finished.connect(func(id): handle(K.ECHO, id))
	EventBus.info_revealed.connect(func(id): handle(K.INFO, id))
	EventBus.shift_state_changed.connect(func(zone, state): handle(K.SHIFT, zone, 1, state))
	GameState.flag_changed.connect(func(flag, value): if value: handle(K.FLAG, flag))

func progress_of(mission_id: String, objective_id: String) -> int:
	return GameState.mission_progress.get(mission_id, {}).get(objective_id, 0)

func is_done(mission_id: String, o: ObjectiveDef) -> bool:
	return progress_of(mission_id, o.id) >= o.count

## Conditional objectives only matter while their conditions are met.
func is_active(o: ObjectiveDef) -> bool:
	return ConditionSet.check(o.conditions)

## Objectives to show in the HUD (conditions met).
func visible_objectives(def: MissionDef) -> Array[ObjectiveDef]:
	var out: Array[ObjectiveDef] = []
	for o in def.objectives:
		if is_active(o):
			out.append(o)
	return out

## All required work is done: every required objective, and one objective per route group.
func required_done(def: MissionDef) -> bool:
	var groups := {}
	var required := 0
	for o in def.objectives:
		if o.optional or not is_active(o):
			continue
		required += 1
		if o.group == "":
			if not is_done(def.id, o):
				return false
		else:
			groups[o.group] = groups.get(o.group, false) or is_done(def.id, o)
	for g in groups:
		if not groups[g]:
			return false
	return required > 0

func done_count(def: MissionDef) -> int:
	var n := 0
	for o in def.objectives:
		if is_done(def.id, o):
			n += 1
	return n

## Called when a mission becomes ACTIVE.
func begin(def: MissionDef) -> void:
	GameState.mission_progress[def.id] = {}
	GameState.mission_checkpoints.erase(def.id)
	for o in def.objectives:
		if _already_true(o):
			_set_progress(def.id, o, o.count)

## Clears progress (checkpoint recovery restarts a mission from its first objective).
func reset(def: MissionDef) -> void:
	GameState.mission_progress[def.id] = {}
	begin(def)

func _already_true(o: ObjectiveDef) -> bool:
	match o.objective_kind:
		K.REACH_LOCATION: return GameState.current_location == o.target
		K.FLAG: return bool(GameState.get_flag(o.target, false))
		K.FRAGMENT: return GameState.has_memory(o.target)
		K.CLUE: return GameState.has_clue(o.target)
		K.ITEM: return GameState.has_item(o.target)
		K.PUZZLE: return PuzzleManager.is_solved(o.target)
		K.DIALOGUE: return bool(GameState.get_flag("dlg_done_" + o.target.to_lower(), false))
		K.TRACE: return o.target in GameState.discovered_traces
		K.ECHO: return o.target in GameState.echoes_seen
		K.INFO: return o.target in GameState.info
		K.SHIFT: return ShiftManager.get_state(o.target) == o.value
	return false

func handle(kind: ObjectiveDef.Kind, target: String, amount: int = 1, value: String = "") -> void:
	for mission_id in GameState.mission_states.keys():
		if GameState.mission_states[mission_id] != MissionDef.State.ACTIVE:
			continue
		var def := DataRegistry.get_mission(mission_id)
		if def == null:
			continue
		var changed := false
		for o in def.objectives:
			if o.objective_kind != kind or o.target != target:
				continue
			if kind == K.SHIFT and o.value != "" and o.value != value:
				continue
			var current := progress_of(mission_id, o.id)
			if current < o.count:
				_set_progress(mission_id, o, current + amount)
				changed = true
		if changed:
			EventBus.mission_objectives_changed.emit(mission_id)

func _set_progress(mission_id: String, o: ObjectiveDef, value: int) -> void:
	var prog: Dictionary = GameState.mission_progress.get_or_add(mission_id, {})
	var before: int = prog.get(o.id, 0)
	prog[o.id] = mini(value, o.count)
	EventBus.mission_objective_progress.emit(mission_id, o.id, prog[o.id], o.count)
	if before < o.count and prog[o.id] >= o.count:
		_checkpoint(mission_id)

## Checkpoint = where the player was when an objective was completed.
func _checkpoint(mission_id: String) -> void:
	var def := DataRegistry.get_mission(mission_id)
	GameState.mission_checkpoints[mission_id] = {
		"location": GameState.current_location, "spawn": GameState.last_spawn_id,
		"objectives_done": done_count(def) if def != null else 0,
	}
