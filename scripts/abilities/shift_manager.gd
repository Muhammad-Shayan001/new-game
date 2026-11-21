extends Node
## Reality Shift: switches marked zones between defined states (ShiftZoneDef).
## - Only at a ShiftAnchor (the ability asks can_shift()).
## - Exclusive zones: only one zone is away from its default state at a time.
## - Persistent zones are saved in GameState.shift_states.
## - Safe transitions: after a change the player is moved out of any newly solid object.

var busy := false

var _anchor: ShiftAnchor = null
var _volatile: Dictionary = {}   # non-persistent zones: zone_id -> state

func reset_runtime() -> void:
	_volatile.clear()
	_anchor = null
	busy = false

func default_state(zone_id: String) -> String:
	var def := DataRegistry.get_shift_zone(zone_id)
	return def.default_state if def != null else ""

func get_state(zone_id: String) -> String:
	var def := DataRegistry.get_shift_zone(zone_id)
	if def == null:
		return ""
	if def.persistent:
		return GameState.shift_states.get(zone_id, def.default_state)
	return _volatile.get(zone_id, def.default_state)

# --- anchors -----------------------------------------------------------------
func set_anchor(anchor: ShiftAnchor) -> void:
	_anchor = anchor
	EventBus.shift_anchor_changed.emit(anchor.zone_id if anchor != null else "", anchor != null)

func clear_anchor(anchor: ShiftAnchor) -> void:
	if _anchor == anchor:
		set_anchor(null)

func current_anchor() -> ShiftAnchor:
	return _anchor if is_instance_valid(_anchor) else null

## True when an anchor is under the player, no shift is in progress, and the shift would
## actually change the zone (a one-way anchor already in its target state does nothing).
func can_shift() -> bool:
	var anchor := current_anchor()
	if anchor == null or busy:
		return false
	return anchor.target_state == "" or get_state(anchor.zone_id) != anchor.target_state

## Called by the Reality Shift ability.
func shift_at_anchor() -> bool:
	var anchor := current_anchor()
	if anchor == null or busy:
		return false
	if anchor.target_state != "":
		return set_state(anchor.zone_id, anchor.target_state)
	return cycle(anchor.zone_id)

func cycle(zone_id: String) -> bool:
	var def := DataRegistry.get_shift_zone(zone_id)
	return def != null and set_state(zone_id, def.next_state(get_state(zone_id)))

func set_state(zone_id: String, state: String) -> bool:
	var def := DataRegistry.get_shift_zone(zone_id)
	if def == null:
		GameLog.error("Shift", "unknown zone '%s'" % zone_id)
		return false
	if state not in def.states:
		GameLog.error("Shift", "%s has no state '%s'" % [zone_id, state])
		return false
	if get_state(zone_id) == state or busy:
		return false
	if def.exclusive and state != def.default_state:
		for other_id in DataRegistry.ids("shift_zone"):
			if other_id != zone_id and get_state(other_id) != default_state(other_id):
				_apply(other_id, default_state(other_id))
	_apply(zone_id, state)
	busy = true
	var timer := get_tree().create_timer(def.transition_time if not _reduce_motion() else 0.05)
	timer.timeout.connect(func(): busy = false)
	_rescue_player()
	return true

func _apply(zone_id: String, state: String) -> void:
	var def := DataRegistry.get_shift_zone(zone_id)
	if def.persistent:
		GameState.shift_states[zone_id] = state
	else:
		_volatile[zone_id] = state
	get_tree().call_group("shiftables", "apply_state", zone_id, state)
	EventBus.shift_state_changed.emit(zone_id, state)

func _reduce_motion() -> bool:
	return bool(SettingsManager.get_value("accessibility", "reduce_motion"))

## Safe transition: if the player ends up inside a newly solid object, move them to the
## nearest safe point (group "shift_safe_points"), else to the location spawn.
func _rescue_player() -> void:
	await get_tree().physics_frame      # deferred collider changes are applied
	await get_tree().physics_frame      # the physics space now matches the new state
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or not player.is_inside_tree():
		return
	var space := player.get_world_3d().direct_space_state
	for node in get_tree().get_nodes_in_group("shiftables"):
		for shape_node in node.solid_shapes():
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = shape_node.shape
			query.transform = shape_node.global_transform
			query.collision_mask = 2
			query.collide_with_bodies = true
			if not space.intersect_shape(query, 1).is_empty():
				player.place_at(_safe_transform(player))
				GameLog.info("Shift", "player moved out of a newly solid object")
				return

func _safe_transform(player: Player) -> Transform3D:
	var best: Node3D = null
	for n in get_tree().get_nodes_in_group("shift_safe_points"):
		if best == null or n.global_position.distance_to(player.global_position) < best.global_position.distance_to(player.global_position):
			best = n
	if best != null:
		return best.global_transform
	var root := SceneRouter.current_root as LocationRoot
	return root.get_spawn_transform(GameState.last_spawn_id) if root != null else Transform3D.IDENTITY
