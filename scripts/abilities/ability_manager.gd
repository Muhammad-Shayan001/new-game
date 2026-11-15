extends Node
## Owns ability unlocks, timers and cooldowns. Effects live in AbilityBehavior scripts.
## Limits are timer/cooldown only. Input slots map to actions ability_1..ability_4.

var _behaviors: Dictionary = {}   # ability_id -> AbilityBehavior
var _active: Dictionary = {}      # ability_id -> seconds remaining
var _cooldowns: Dictionary = {}   # ability_id -> seconds remaining

func unlock(ability_id: String) -> bool:
	if DataRegistry.get_ability(ability_id) == null:
		GameLog.error("Ability", "unknown ability '%s'" % ability_id)
		return false
	if GameState.has_ability(ability_id):
		return false
	GameState.abilities.append(ability_id)
	EventBus.ability_unlocked.emit(ability_id)
	EventBus.toast_requested.emit("TOAST_ABILITY_UNLOCKED", "reward")
	return true

## Clears timers and cached behaviors (new game, tests). Active effects are switched off.
func reset_runtime() -> void:
	for id in _active.keys():
		_get_behavior(DataRegistry.get_ability(id)).deactivate()
	_active.clear()
	_cooldowns.clear()
	for b in _behaviors.values():
		b.queue_free()
	_behaviors.clear()

func is_active(ability_id: String) -> bool:
	return _active.has(ability_id)

func cooldown_left(ability_id: String) -> float:
	return _cooldowns.get(ability_id, 0.0)

func activate(ability_id: String) -> bool:
	var def := DataRegistry.get_ability(ability_id)
	if def == null or not GameState.has_ability(ability_id):
		return false
	if InputService.is_locked() or is_active(ability_id) or cooldown_left(ability_id) > 0.0:
		return false
	var behavior := _get_behavior(def)
	if not behavior.can_activate():
		return false
	behavior.activate()
	if def.duration > 0.0:
		_active[ability_id] = def.duration
	else:
		_start_cooldown(def)
	EventBus.ability_activated.emit(ability_id)
	return true

func deactivate(ability_id: String) -> void:
	if not _active.has(ability_id):
		return
	_active.erase(ability_id)
	var def := DataRegistry.get_ability(ability_id)
	_get_behavior(def).deactivate()
	_start_cooldown(def)
	EventBus.ability_ended.emit(ability_id)

func _start_cooldown(def: AbilityDef) -> void:
	if def.cooldown > 0.0:
		_cooldowns[def.id] = def.cooldown

func _get_behavior(def: AbilityDef) -> AbilityBehavior:
	if not _behaviors.has(def.id):
		var b: AbilityBehavior = def.behavior.new()
		b.def = def
		b.name = def.id
		add_child(b)
		_behaviors[def.id] = b
	return _behaviors[def.id]

func _process(delta: float) -> void:
	_poll_input()
	for id in _active.keys():
		_active[id] -= delta
		if _active[id] <= 0.0:
			deactivate(id)
	for id in _cooldowns.keys():
		_cooldowns[id] -= delta
		if _cooldowns[id] <= 0.0:
			_cooldowns.erase(id)

## Polled (not event-driven) so touch buttons, which press actions through
## Input.action_press(), work exactly like keys and gamepad buttons.
func _poll_input() -> void:
	for slot in range(1, 5):
		if Input.is_action_just_pressed(InputActions.ability_action(slot)):
			for def in DataRegistry.all("ability"):
				if def.input_slot == slot and GameState.has_ability(def.id):
					activate(def.id)
