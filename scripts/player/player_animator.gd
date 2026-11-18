class_name PlayerAnimator
extends Node
## Animation integration. Builds an AnimationTree (BlendSpace1D locomotion + one-shot action) driven by
## the controller's speed. Animation NAMES are the contract: "idle", "walk", "run", "sprint", "interact".
## Until real clips exist, procedural placeholder clips are generated for the 'Body' node.
## To use real animations: add an AnimationLibrary with these names to the AnimationPlayer; the
## placeholder generator skips any name that already exists.

signal footstep(speed: float)

const BLEND_POINTS := {"idle": 0.0, "walk": 1.0, "run": 2.0, "sprint": 3.0}
const STRIDE := 1.35            # metres per footstep

@export var player_path: NodePath = ^".."
@export var animation_player_path: NodePath = ^"../AnimationPlayer"
@export var animation_tree_path: NodePath = ^"../AnimationTree"

var player: PlayerController
var anim_player: AnimationPlayer
var anim_tree: AnimationTree
var blend_position: float = 0.0
var _step_phase: float = 0.0

func _ready() -> void:
	player = get_node_or_null(player_path) as PlayerController
	anim_player = get_node_or_null(animation_player_path) as AnimationPlayer
	anim_tree = get_node_or_null(animation_tree_path) as AnimationTree
	if player == null or anim_player == null or anim_tree == null:
		Log.warn("Animator", "Missing player/AnimationPlayer/AnimationTree; animation disabled")
		set_physics_process(false)
		return
	_ensure_clips()
	_build_tree()

## Maps ground speed (m/s) to the BlendSpace1D position. Public + pure for testing.
func blend_for_speed(speed: float, p: PlayerController) -> float:
	if speed <= 0.05:
		return 0.0
	if speed <= p.walk_speed:
		return remap(speed, 0.05, p.walk_speed, 0.0, 1.0)
	if speed <= p.run_speed:
		return remap(speed, p.walk_speed, p.run_speed, 1.0, 2.0)
	return remap(minf(speed, p.sprint_speed), p.run_speed, p.sprint_speed, 2.0, 3.0)

func _physics_process(delta: float) -> void:
	var speed := player.horizontal_speed()
	var target := blend_for_speed(speed, player)
	var reduce := bool(Settings.value("reduced_motion"))
	blend_position = target if reduce else lerpf(blend_position, target, 1.0 - exp(-12.0 * delta))
	anim_tree.set("parameters/locomotion/blend_position", blend_position)
	if speed > 0.3:
		_step_phase += speed * delta / STRIDE
		if _step_phase >= 1.0:
			_step_phase -= 1.0
			footstep.emit(speed)
			Audio.play_sfx("SFX_FOOTSTEP")
	else:
		_step_phase = 0.0

## One-shot gesture (e.g. interaction). Safe to call at any time.
func play_action() -> void:
	if anim_tree:
		anim_tree.set("parameters/action/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

# ---------------------------------------------------------------- setup
func _ensure_clips() -> void:
	var lib: AnimationLibrary
	if anim_player.has_animation_library(""):
		lib = anim_player.get_animation_library("")
	else:
		lib = AnimationLibrary.new()
		anim_player.add_animation_library("", lib)
	var root := anim_player.get_node_or_null(anim_player.root_node)
	var body_path := "Visual/Body"
	if root == null or root.get_node_or_null(body_path) == null:
		body_path = ""
	# bob amplitude, bob cycles per clip, forward lean (rad), loop length
	var specs := {
		"idle": [0.012, 1.0, 0.0, 2.4], "walk": [0.035, 2.0, 0.06, 1.2],
		"run": [0.06, 2.0, 0.16, 0.8], "sprint": [0.08, 2.0, 0.26, 0.6],
	}
	for clip: String in specs:
		if lib.has_animation(clip):
			continue
		lib.add_animation(clip, _make_loop(body_path, specs[clip]))
	if not lib.has_animation("interact"):
		lib.add_animation("interact", _make_gesture(body_path))

func _make_loop(body_path: String, s: Array) -> Animation:
	var a := Animation.new()
	a.length = s[3]
	a.loop_mode = Animation.LOOP_LINEAR
	if body_path == "":
		return a
	var t := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, NodePath(body_path + ":position:y"))
	var steps := 8
	for i in range(steps + 1):
		var ph := float(i) / steps
		a.track_insert_key(t, ph * s[3], 0.85 + absf(sin(ph * PI * s[1])) * s[0])
	var lean := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(lean, NodePath(body_path + ":rotation:x"))
	a.track_insert_key(lean, 0.0, -s[2])
	a.track_insert_key(lean, s[3], -s[2])
	return a

func _make_gesture(body_path: String) -> Animation:
	var a := Animation.new()
	a.length = 0.45
	a.loop_mode = Animation.LOOP_NONE
	if body_path == "":
		return a
	var t := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, NodePath(body_path + ":rotation:x"))
	a.track_insert_key(t, 0.0, 0.0)
	a.track_insert_key(t, 0.18, -0.35)
	a.track_insert_key(t, 0.45, 0.0)
	return a

func _build_tree() -> void:
	var space := AnimationNodeBlendSpace1D.new()
	space.min_space = 0.0
	space.max_space = 3.0
	for clip: String in BLEND_POINTS:
		var n := AnimationNodeAnimation.new()
		n.animation = clip
		space.add_blend_point(n, BLEND_POINTS[clip])
	var gesture := AnimationNodeAnimation.new()
	gesture.animation = "interact"
	var bt := AnimationNodeBlendTree.new()
	bt.add_node("locomotion", space)
	bt.add_node("gesture", gesture)
	bt.add_node("action", AnimationNodeOneShot.new())
	bt.connect_node("action", 0, "locomotion")
	bt.connect_node("action", 1, "gesture")
	bt.connect_node("output", 0, "action")
	anim_tree.tree_root = bt
	anim_tree.anim_player = anim_tree.get_path_to(anim_player)
	anim_tree.active = true
