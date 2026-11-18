extends Node
## Unlocking, activation, duration and cooldown for abilities. Definitions: resources/abilities/*.json.
## Behaviour lives in AbilityBase subclasses referenced by def.script.

const SAVE_KEY := "abilities"
var _unlocked: Array = []
var _cooldowns: Dictionary = {}      # id -> remaining seconds
var _impl: Dictionary = {}           # id -> AbilityBase
var active_id: String = ""
var _active_left: float = 0.0

func _ready() -> void:
	SaveManager.register_provider(SAVE_KEY, self)

func _process(delta: float) -> void:
	_poll_input()
	# cooldowns tick first so an ability that ends this frame starts its full cooldown
	for id: String in _cooldowns.keys():
		_cooldowns[id] = maxf(0.0, _cooldowns[id] - delta)
		if _cooldowns[id] == 0.0:
			_cooldowns.erase(id)
			EventBus.ability_cooldown_changed.emit(id, 0.0)
	if active_id != "":
		_impl[active_id].on_tick(delta)
		_active_left -= delta
		if _active_left <= 0.0:
			end_active()

## Polled (not event based) so touch buttons, which use Input.action_press, behave like keys.
func _poll_input() -> void:
	if InputRouter.is_locked():
		return
	for slot in range(1, 5):
		if InputRouter.just_pressed("ability_%d" % slot):
			var id := id_for_slot(slot)
			if id != "":
				request_activate(id)
	if InputRouter.just_pressed("context_ability"):
		var cid := context_ability_id()
		if cid != "":
			request_activate(cid)

func unlock(id: String) -> void:
	if not DataRegistry.has_def("abilities", id):
		Log.error("Ability", "Unknown ability '%s'" % id)
		return
	if id in _unlocked:
		return
	_unlocked.append(id)
	EventBus.ability_unlocked.emit(id)

func is_unlocked(id: String) -> bool:
	return id in _unlocked

func unlocked_ids() -> Array:
	return _unlocked.duplicate()

func id_for_slot(slot: int) -> String:
	for def: Dictionary in DataRegistry.all_defs("abilities"):
		if int(def["slot"]) == slot:
			return def["id"]
	return ""

func cooldown_left(id: String) -> float:
	return float(_cooldowns.get(id, 0.0))

func can_activate(id: String) -> bool:
	return is_unlocked(id) and active_id == "" and cooldown_left(id) <= 0.0

func request_activate(id: String) -> bool:
	if not can_activate(id):
		return false
	var def := DataRegistry.get_def("abilities", id)
	if not _impl.has(id):
		var script: Script = load(str(def["script"])) as Script
		if script == null:
			Log.error("Ability", "Cannot load script %s" % def["script"])
			return false
		var inst: AbilityBase = script.new()
		inst.setup(def, get_tree())
		_impl[id] = inst
	active_id = id
	_active_left = float(def["duration"])
	_impl[id].on_activate()
	EventBus.ability_activated.emit(id)
	return true

func end_active() -> void:
	if active_id == "":
		return
	var id := active_id
	active_id = ""
	_impl[id].on_end()
	_cooldowns[id] = float(DataRegistry.get_def("abilities", id)["cooldown"])
	EventBus.ability_ended.emit(id)
	EventBus.ability_cooldown_changed.emit(id, _cooldowns[id])

## Picks the ability that matches what is nearby (reveal targets, shiftables, echo targets),
## falling back to the lowest-slot unlocked ability. Drives the contextual ability button.
func context_ability_id() -> String:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var best := ""
	var best_d := INF
	for id: String in _unlocked:
		var group: String = str(DataRegistry.get_def("abilities", id).get("context_group", ""))
		if group == "" or player == null:
			continue
		for n in get_tree().get_nodes_in_group(group):
			if n is Node3D:
				var d := player.global_position.distance_to((n as Node3D).global_position)
				if d < best_d and d < 14.0:
					best_d = d
					best = id
	if best != "":
		return best
	var lowest := 99
	for id: String in _unlocked:
		var slot := int(DataRegistry.get_def("abilities", id).get("slot", 99))
		if slot < lowest:
			lowest = slot
			best = id
	return best

func save_data() -> Dictionary:
	return {"unlocked": _unlocked.duplicate()}

func load_data(d: Dictionary) -> void:
	reset_data()
	_unlocked = d.get("unlocked", []).duplicate()

func reset_data() -> void:
	if active_id != "":
		end_active()
	_unlocked = []
	_cooldowns = {}
