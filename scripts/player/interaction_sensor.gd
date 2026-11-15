class_name InteractionSensor
extends Area3D
## Child of the player. Finds the best Interactable in range (2 m, 70 degree facing
## cone), shows its prompt, and runs hold-to-interact. Priority: story > clue > pickup > ambient.

const RANGE := 2.0
const HALF_CONE_DEGREES := 35.0

var _candidates: Array[Interactable] = []
var _target: Interactable = null
var _held := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = RANGE
	shape.shape = sphere
	add_child(shape)

func _on_area_entered(area: Area3D) -> void:
	if area is Interactable and area not in _candidates:
		_candidates.append(area)

func _on_area_exited(area: Area3D) -> void:
	_candidates.erase(area)
	if area == _target:
		_set_target(null)

func current_target() -> Interactable:
	return _target

func _physics_process(delta: float) -> void:
	if InputService.is_locked():
		_set_target(null)
		return
	_set_target(_pick_best())
	if _target == null:
		return
	var auto := bool(SettingsManager.get_value("controls", "auto_interact")) \
		and _target.interact_priority <= Interactable.Priority.PICKUP and _target.hold_time <= 0.0
	if Input.is_action_pressed(InputActions.INTERACT) or auto:
		_held += delta
		if _target.hold_time > 0.0:
			EventBus.interaction_hold_progress.emit(clampf(_held / _target.hold_time, 0.0, 1.0))
		if _held >= _target.hold_time:
			var t := _target
			_held = -INF   # require a new press before the next interaction
			t.interact()
	elif _held != 0.0:
		_held = 0.0
		EventBus.interaction_hold_progress.emit(0.0)

func _pick_best() -> Interactable:
	var forward := -global_transform.basis.z
	var best: Interactable = null
	var best_distance := INF
	for c in _candidates:
		if not is_instance_valid(c) or not c.can_interact():
			continue
		var to_target := c.global_position - global_position
		to_target.y = 0.0
		var distance := to_target.length()
		if distance > 0.1 and rad_to_deg(forward.angle_to(to_target.normalized())) > HALF_CONE_DEGREES:
			continue
		if best == null or c.interact_priority > best.interact_priority \
				or (c.interact_priority == best.interact_priority and distance < best_distance):
			best = c
			best_distance = distance
	return best

func _set_target(t: Interactable) -> void:
	if t == _target:
		return
	_target = t
	_held = 0.0
	EventBus.interaction_prompt_changed.emit(t != null, t.prompt_key if t != null else "")
	EventBus.interaction_hold_progress.emit(0.0)
