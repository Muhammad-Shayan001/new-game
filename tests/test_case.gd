extends RefCounted
## Base class for test cases: assertions plus helpers for resetting global state and stepping frames.

var tree: SceneTree
var current: String = ""
var passes: int = 0
var fails: PackedStringArray = PackedStringArray()

func ok(cond: bool, msg: String = "") -> void:
	if cond:
		passes += 1
	else:
		fails.append("%s: FAILED %s" % [current, msg])

func eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual == expected:
		passes += 1
	else:
		fails.append("%s: FAILED %s (expected %s, got %s)" % [current, msg, str(expected), str(actual)])

func near(actual: float, expected: float, tol: float, msg: String = "") -> void:
	ok(absf(actual - expected) <= tol, "%s (expected %s +/- %s, got %s)" % [msg, str(expected), str(tol), str(actual)])

func before_each() -> void:
	tree.paused = false
	SceneManager.busy = false
	SaveManager.reset_all()
	InputRouter.clear_locks()
	InputRouter.set_virtual_move(Vector2.ZERO)
	InputRouter.last_device = "kbm"
	InputRouter._latched.clear()
	DialogueManager.abort()
	Settings.reset_to_defaults()
	for a in ["interact", "sprint", "context_ability"]:
		Input.action_release(a)
	MissionManager.refresh()

func after_each() -> void:
	tree.paused = false
	InputRouter.clear_locks()
	InputRouter.set_virtual_move(Vector2.ZERO)
	for a in ["interact", "sprint", "context_ability"]:
		Input.action_release(a)
	Input.flush_buffered_events()

func frames(n: int) -> void:
	for i in n:
		await tree.process_frame

func physics(n: int) -> void:
	for i in n:
		await tree.physics_frame

## Instantiates GameRoot, registers it, and enters the given location. Returns the GameRoot node.
func start_game_at(loc_id: String) -> Node:
	var root: Node = load("res://scenes/game_root.tscn").instantiate()
	tree.root.add_child(root)
	await frames(2)
	await SceneManager.go_to_location(loc_id)
	await frames(2)
	return root

func wait_transition_done(max_frames: int = 600) -> void:
	var n := 0
	while SceneManager.busy and n < max_frames:
		await tree.process_frame
		n += 1

func end_game(root: Node) -> void:
	await wait_transition_done()
	SceneManager.unregister_game_root()
	root.queue_free()
	await frames(2)

# ------------------------------------------------------------------ gameplay helpers
func player() -> PlayerController:
	return SceneManager.player

func rig() -> CameraRig:
	return SceneManager.player.camera_rig as CameraRig

func find_interactable(id: String) -> Interactable:
	for c in SceneManager.current_location_node.get_children():
		if c is Interactable and c.interaction_id == id:
			return c
	return null

## Teleports the player 1.2 m south of the node, facing north (-Z), and lets overlaps register.
func place_near(it: Interactable, facing_yaw: float = 0.0) -> void:
	var p := player()
	p.teleport(Transform3D(Basis.IDENTITY, it.global_position + Vector3(0, 0.1, 1.2)))
	p.visual.rotation.y = facing_yaw
	await physics(4)

func press(action: String, hold_frames: int = 2) -> void:
	Input.action_press(action)
	await physics(hold_frames)
	Input.action_release(action)
	await physics(1)

## Steers like a joystick would: converts the world direction into camera-relative stick input.
## Returns true when within tolerance of the target, false on timeout.
func walk_to(target: Vector3, tolerance: float = 1.1, max_frames: int = 900) -> bool:
	var p := player()
	for i in max_frames:
		var to := target - p.global_position
		to.y = 0.0
		if to.length() <= tolerance:
			InputRouter.set_virtual_move(Vector2.ZERO)
			return true
		var local := Basis(Vector3.UP, -rig().get_yaw()) * to.normalized()
		InputRouter.set_virtual_move(Vector2(local.x, local.z))
		await tree.physics_frame
	InputRouter.set_virtual_move(Vector2.ZERO)
	return false
