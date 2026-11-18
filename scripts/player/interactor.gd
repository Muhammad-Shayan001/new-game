class_name Interactor
extends Area3D
## Finds the best Interactable near the player (distance + facing), publishes the prompt, and
## triggers it on the 'interact' action. Supports tap and hold interactions.

@export var range_radius: float = 2.2
@export var cone_half_angle_deg: float = 70.0      ## widened to 180 by the 'interaction_assist' setting

var target: Interactable
var player: PlayerController
var _candidates: Array[Interactable] = []
var _hold: float = 0.0
var _hold_done: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	player = get_parent() as PlayerController
	var shape := get_node_or_null("Shape") as CollisionShape3D
	if shape == null:
		shape = CollisionShape3D.new()
		shape.name = "Shape"
		add_child(shape)
	var sphere := SphereShape3D.new()
	sphere.radius = range_radius
	shape.shape = sphere
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(a: Area3D) -> void:
	if a is Interactable and a not in _candidates:
		_candidates.append(a)

func _on_area_exited(a: Area3D) -> void:
	_candidates.erase(a)
	if a == target:
		_set_target(null)

func _physics_process(delta: float) -> void:
	_candidates = _candidates.filter(func(c): return is_instance_valid(c))
	_set_target(_pick_best())
	_handle_input(delta)

## Score = distance penalised by facing angle. Returns null if nothing is usable.
func _pick_best() -> Interactable:
	if InputRouter.is_locked() or player == null:
		return null
	var half := 180.0 if bool(Settings.value("interaction_assist")) else cone_half_angle_deg
	var facing := player.facing_direction()
	var best: Interactable = null
	var best_score := INF
	for c in _candidates:
		if not c.is_available():
			continue
		var to := c.global_position - player.global_position
		to.y = 0.0
		var dist := to.length()
		if dist > range_radius + 0.5:
			continue
		var angle := 0.0 if dist < 0.6 else rad_to_deg(facing.angle_to(to.normalized()))
		if angle > half:
			continue
		var score := dist + angle / 90.0
		if score < best_score:
			best_score = score
			best = c
	return best

func _set_target(t: Interactable) -> void:
	if t == target:
		return
	if target and is_instance_valid(target):
		target.set_focused(false)
	target = t
	_hold = 0.0
	_hold_done = false
	if target:
		target.set_focused(true)
		EventBus.interaction_prompt_changed.emit(target.prompt_text())
	else:
		EventBus.interaction_prompt_changed.emit("")
		EventBus.interaction_hold_progress.emit(0.0)

func _handle_input(delta: float) -> void:
	if target == null:
		return
	var need := target.hold_time()
	if need <= 0.0:
		if InputRouter.just_pressed("interact"):
			_use()
		return
	if InputRouter.is_pressed("interact") and not _hold_done:
		_hold += delta
		EventBus.interaction_hold_progress.emit(clampf(_hold / need, 0.0, 1.0))
		if _hold >= need:
			_hold_done = true
			_use()
	elif not InputRouter.is_pressed("interact"):
		_hold = 0.0
		_hold_done = false
		EventBus.interaction_hold_progress.emit(0.0)

func _use() -> void:
	var t := target
	if t and t.interact(player):
		var anim := player.get_node_or_null("Animator") as PlayerAnimator
		if anim:
			anim.play_action()
