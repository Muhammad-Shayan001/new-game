extends Node
## Audio buses, music crossfades, pooled one-shots, dialogue ducking.
## Gameplay requests CUE IDs (AudioCueDef); it never loads audio files itself.

const BUS_NAMES := {"master": "Master", "music": "Music", "sfx": "SFX", "ambience": "Ambience", "voice": "Voice"}
const SFX_POOL_SIZE := 8
const DUCK_DB := -8.0

var _music: Array[AudioStreamPlayer] = []
var _music_index := 0
var _current_music := ""
var _sfx_pool: Array[AudioStreamPlayer] = []
var _music_volume_db := 0.0
var _warned: Dictionary = {}

func _ready() -> void:
	_ensure_buses()
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Music"
		add_child(p)
		_music.append(p)
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)
	for key in BUS_NAMES:
		set_bus_volume_linear(key, 1.0)
	EventBus.dialogue_started.connect(func(_id): _duck(true))
	EventBus.dialogue_finished.connect(func(_id): _duck(false))

func _ensure_buses() -> void:
	for key in ["music", "sfx", "ambience", "voice"]:
		if AudioServer.get_bus_index(BUS_NAMES[key]) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, BUS_NAMES[key])
			AudioServer.set_bus_send(idx, "Master")

## Called by SettingsManager. `key` is "master", "music", "sfx", "ambience" or "voice".
func set_bus_volume_linear(key: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(BUS_NAMES.get(key, ""))
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, value <= 0.0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.0001)))

func play_cue(cue_id: String, pitch: float = 1.0) -> void:
	var def := DataRegistry.get_audio(cue_id)
	if def == null:
		_warn_once(cue_id, "unknown audio cue '%s'" % cue_id)
		return
	if def.stream == null:
		_warn_once(cue_id, "audio cue '%s' has no stream yet (placeholder)" % cue_id)
		return
	if def.category == AudioCueDef.Category.MUSIC:
		play_music(cue_id)
		return
	for p in _sfx_pool:
		if not p.playing:
			p.stream = def.stream
			p.bus = {AudioCueDef.Category.SFX: "SFX", AudioCueDef.Category.AMBIENCE: "Ambience",
				AudioCueDef.Category.VOICE: "Voice"}[def.category]
			p.volume_db = def.volume_db
			p.pitch_scale = randf_range(def.pitch_min, def.pitch_max) * pitch
			p.play()
			return
	_warn_once("pool", "SFX pool exhausted; sound dropped")

func play_music(cue_id: String, fade: float = 1.5) -> void:
	if cue_id == _current_music:
		return
	var def := DataRegistry.get_audio(cue_id)
	if def == null or def.stream == null:
		_warn_once(cue_id, "music cue '%s' unavailable" % cue_id)
		return
	var old := _music[_music_index]
	_music_index = 1 - _music_index
	var fresh := _music[_music_index]
	fresh.stream = def.stream
	fresh.volume_db = -60.0
	fresh.play()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(fresh, "volume_db", def.volume_db, fade)
	tween.tween_property(old, "volume_db", -60.0, fade)
	tween.chain().tween_callback(old.stop)
	_current_music = cue_id

func stop_music(fade: float = 1.5) -> void:
	var p := _music[_music_index]
	var tween := create_tween()
	tween.tween_property(p, "volume_db", -60.0, fade)
	tween.tween_callback(p.stop)
	_current_music = ""

func _duck(on: bool) -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx == -1:
		return
	var tween := create_tween()
	tween.tween_method(func(v): AudioServer.set_bus_volume_db(idx, v),
		AudioServer.get_bus_volume_db(idx), (DUCK_DB if on else 0.0) + _bus_base_db("music"), 0.4)

func _bus_base_db(key: String) -> float:
	return linear_to_db(maxf(float(SettingsManager.get_value("audio", key)), 0.0001))

func _warn_once(key: String, message: String) -> void:
	if not _warned.has(key):
		_warned[key] = true
		GameLog.warn("Audio", message)
