extends Node
## Time Echo. Two uses of the same ability:
##  1. Playback at an EchoSite: a short replay of a past event (TimeEchoDef): figures,
##     camera, audio cues, captions, clue moments. Can be skipped with Interact.
##  2. Recording in a record zone: record up to 10 s of the player's walk, use again to stop;
##     a ghost copy replays it and stays at the end (holds pressure plates).
## Chapter 5 upgrade: flag time_echo_upgraded allows 2 ghosts.

const RECORD_STEP := 0.1
const MAX_RECORD_SECONDS := 10.0
const SKIP_DELAY := 0.5

var recording := false
var playing_echo: TimeEchoDef = null
var player_echoes: Array[EchoGhost] = []

var _site: EchoSite = null
var _t := 0.0
var _fired_audio: Dictionary = {}
var _fired_captions: Dictionary = {}
var _fired_clues: Dictionary = {}
var _ghosts: Array[EchoGhost] = []
var _camera_marker: Node3D = null
var _origin := Transform3D.IDENTITY
var _rec: Array = []
var _rec_time := 0.0
var _rec_step := 0.0

func _ready() -> void:
	EventBus.scene_transition_started.connect(func(_a, _b): reset_runtime())

func reset_runtime() -> void:
	if playing_echo != null:
		_end_playback(false)
	if recording:
		recording = false
		EventBus.echo_recording_changed.emit(false)
	_rec.clear()
	for g in player_echoes:
		if is_instance_valid(g):
			g.queue_free()
	player_echoes.clear()
	_site = null

func max_echoes() -> int:
	return 2 if bool(GameState.get_flag("time_echo_upgraded", false)) else 1

# --- sites -------------------------------------------------------------------
func set_site(site: EchoSite) -> void:
	_site = site
	EventBus.echo_site_changed.emit(site.echo_id, true)

func clear_site(site: EchoSite) -> void:
	if _site == site:
		_site = null
		EventBus.echo_site_changed.emit("", false)

func current_site() -> EchoSite:
	return _site if is_instance_valid(_site) else null

func is_busy() -> bool:
	return playing_echo != null

func _echo_playable(echo_id: String) -> bool:
	var def := DataRegistry.get_echo(echo_id)
	if def == null or not ConditionSet.check(def.conditions):
		return false
	return def.replayable or echo_id not in GameState.echoes_seen

## True when the ability can do something right now (used by the ability behavior).
func can_use() -> bool:
	if playing_echo != null:
		return false
	if recording:
		return true
	var site := current_site()
	if site == null:
		return false
	return (site.echo_id != "" and _echo_playable(site.echo_id)) or site.allow_recording

func use() -> bool:
	if recording:
		return stop_recording()
	var site := current_site()
	if site == null:
		return false
	if site.echo_id != "" and _echo_playable(site.echo_id):
		return play_echo(site.echo_id)
	if site.allow_recording:
		return start_recording()
	return false

# --- playback -------------------------------------------------------------------
func play_echo(echo_id: String) -> bool:
	var def := DataRegistry.get_echo(echo_id)
	if def == null:
		GameLog.error("TimeEcho", "unknown echo '%s'" % echo_id)
		return false
	if playing_echo != null or not _echo_playable(echo_id):
		return false
	playing_echo = def
	_t = 0.0
	_fired_audio.clear()
	_fired_captions.clear()
	_fired_clues.clear()
	var root := SceneRouter.current_root as Node3D
	_origin = root.global_transform if root != null else Transform3D.IDENTITY
	var parent: Node = root if root != null else self
	for track in def.tracks:
		var ghost := EchoGhost.new()
		parent.add_child(ghost)
		ghost.setup(track.color, false, Localization.t(track.label_key) if track.label_key != "" else "")
		_ghosts.append(ghost)
	var rig := get_tree().get_first_node_in_group("camera_rig") as CameraRig
	if rig != null and not def.camera_keys.is_empty():
		_camera_marker = Node3D.new()
		parent.add_child(_camera_marker)
		rig.push_override(_camera_marker, 0.4)
	InputService.push_lock("echo")
	GameState.autosave_blocks += 1
	EventBus.echo_started.emit(echo_id)
	advance(0.0)
	return true

## Advances the active replay / recording by `delta` seconds (tests call this directly).
func advance(delta: float) -> void:
	if recording:
		_advance_recording(delta)
	if playing_echo != null:
		_advance_playback(delta)

func _process(delta: float) -> void:
	advance(delta)
	if playing_echo != null and _t > SKIP_DELAY and Input.is_action_just_pressed(InputActions.INTERACT):
		skip()

## Jumps to the end; clue moments and captions still fire, so skipping never loses content.
func skip() -> void:
	if playing_echo != null:
		_advance_playback(playing_echo.duration - _t + 0.001)

func _advance_playback(delta: float) -> void:
	var def := playing_echo
	_t = minf(_t + delta, def.duration)
	for i in def.tracks.size():
		_ghosts[i].global_position = _origin * _sample_position(def.tracks[i], _t)
		_ghosts[i].rotation.y = deg_to_rad(_sample_yaw(def.tracks[i], _t))
	if _camera_marker != null and not def.camera_keys.is_empty():
		_place_camera(def)
	for i in def.audio_events.size():
		if def.audio_events[i].time <= _t and not _fired_audio.has(i):
			_fired_audio[i] = true
			AudioManager.play_cue(def.audio_events[i].cue_id)
	for i in def.captions.size():
		if def.captions[i].time <= _t and not _fired_captions.has(i):
			_fired_captions[i] = true
			EventBus.echo_caption.emit(def.captions[i].speaker_id, def.captions[i].text_key)
	for i in def.clue_moments.size():
		var m := def.clue_moments[i]
		if m.time <= _t and not _fired_clues.has(i):
			_fired_clues[i] = true
			if m.clue_id != "": InventoryManager.add_clue(m.clue_id)
			if m.fragment_id != "": MemoryManager.collect(m.fragment_id)
			if m.info_id != "": ProgressionManager.reveal_info(m.info_id)
	if _t >= def.duration:
		_end_playback(true)

func _end_playback(completed: bool) -> void:
	var def := playing_echo
	if def == null:
		return
	playing_echo = null
	for g in _ghosts:
		if is_instance_valid(g):
			g.queue_free()
	_ghosts.clear()
	var rig := get_tree().get_first_node_in_group("camera_rig") as CameraRig
	if rig != null and _camera_marker != null:
		rig.pop_override(0.4)
	if _camera_marker != null:
		_camera_marker.queue_free()
		_camera_marker = null
	InputService.pop_lock("echo")
	GameState.autosave_blocks = maxi(0, GameState.autosave_blocks - 1)
	if completed:
		if def.id not in GameState.echoes_seen:
			GameState.echoes_seen.append(def.id)
		for f in def.set_flags:
			GameState.set_flag(f, true)
		EventBus.echo_finished.emit(def.id)

func _sample_position(track: EchoTrack, t: float) -> Vector3:
	var keys := track.keys
	if keys.is_empty():
		return Vector3.ZERO
	if t <= keys[0].time:
		return keys[0].position
	for i in range(keys.size() - 1):
		if t <= keys[i + 1].time:
			return keys[i].position.lerp(keys[i + 1].position, inverse_lerp(keys[i].time, keys[i + 1].time, t))
	return keys[keys.size() - 1].position

func _sample_yaw(track: EchoTrack, t: float) -> float:
	var keys := track.keys
	if keys.is_empty():
		return 0.0
	if t <= keys[0].time:
		return keys[0].yaw_degrees
	for i in range(keys.size() - 1):
		if t <= keys[i + 1].time:
			return rad_to_deg(lerp_angle(deg_to_rad(keys[i].yaw_degrees), deg_to_rad(keys[i + 1].yaw_degrees),
				inverse_lerp(keys[i].time, keys[i + 1].time, t)))
	return keys[keys.size() - 1].yaw_degrees

func _place_camera(def: TimeEchoDef) -> void:
	var keys := def.camera_keys
	var a := keys[0]
	var b := keys[0]
	for i in range(keys.size() - 1):
		if _t >= keys[i].time:
			a = keys[i]
			b = keys[i + 1]
	var f := 0.0 if a == b else clampf(inverse_lerp(a.time, b.time, _t), 0.0, 1.0)
	var pos := _origin * a.position.lerp(b.position, f)
	var target := _origin * a.look_at.lerp(b.look_at, f)
	if pos.distance_to(target) > 0.01 and _camera_marker.is_inside_tree():
		_camera_marker.look_at_from_position(pos, target, Vector3.UP)

# --- recording -----------------------------------------------------------------
func start_recording() -> bool:
	if recording or playing_echo != null:
		return false
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return false
	recording = true
	_rec.clear()
	_rec_time = 0.0
	_rec_step = 0.0
	_sample_player(player)
	EventBus.echo_recording_changed.emit(true)
	return true

func _advance_recording(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	_rec_time += delta
	_rec_step += delta
	while _rec_step >= RECORD_STEP:
		_rec_step -= RECORD_STEP
		_sample_player(player)
	if _rec_time >= MAX_RECORD_SECONDS:
		stop_recording()

func _sample_player(player: Node3D) -> void:
	_rec.append({"t": _rec_time, "pos": player.global_position, "yaw": player.rotation.y})

## Ends the recording and spawns a ghost copy that replays it and then stays put.
func stop_recording() -> bool:
	if not recording:
		return false
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null:
		_sample_player(player)
	recording = false
	EventBus.echo_recording_changed.emit(false)
	if _rec.size() < 2:
		return false
	var parent: Node = SceneRouter.current_root if SceneRouter.current_root != null else self
	var ghost := EchoGhost.new()
	parent.add_child(ghost)
	ghost.setup(Color(0.7, 0.85, 1.0, 0.5), true, "")
	ghost.play_path(_rec.duplicate())
	player_echoes.append(ghost)
	while player_echoes.size() > max_echoes():
		var oldest: EchoGhost = player_echoes.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	return true

func clear_player_echoes() -> void:
	for g in player_echoes:
		if is_instance_valid(g):
			g.queue_free()
	player_echoes.clear()
