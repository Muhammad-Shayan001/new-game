extends Node
## Audio buses, music crossfade, SFX and ambience. Sounds are registered by ID in
## res://resources/audio/audio_registry.json: {"sounds": {"SFX_X": {"path": "...", "bus": "SFX"}}}.
## Missing files are skipped with one warning so content can be referenced before assets exist.

const BUSES: PackedStringArray = ["Music", "SFX", "Voice", "Ambient"]
const REGISTRY := "res://resources/audio/audio_registry.json"

var _sounds: Dictionary = {}
var _music: AudioStreamPlayer
var _ambient: AudioStreamPlayer
var _warned: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for b in BUSES:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, b)
			AudioServer.set_bus_send(idx, "Master")
	_music = _make_player("Music")
	_ambient = _make_player("Ambient")
	if FileAccess.file_exists(REGISTRY):
		_sounds = JsonLoader.load_dict(REGISTRY).get("sounds", {})
	EventBus.settings_changed.connect(func(k, _v): if k.ends_with("_volume"): apply_volumes())
	apply_volumes()

func _make_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p

func apply_volumes() -> void:
	_set_bus("Master", float(Settings.value("master_volume")))
	_set_bus("Music", float(Settings.value("music_volume")))
	_set_bus("SFX", float(Settings.value("sfx_volume")))
	_set_bus("Voice", float(Settings.value("voice_volume")))
	_set_bus("Ambient", float(Settings.value("ambient_volume")))

func _set_bus(bus: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0, 1.0)))
		AudioServer.set_bus_mute(idx, linear <= 0.001)

func _stream_for(id: String) -> AudioStream:
	var entry: Dictionary = _sounds.get(id, {})
	var path: String = entry.get("path", "")
	if path == "" or not ResourceLoader.exists(path):
		if not _warned.has(id):
			_warned[id] = true
			Log.info("Audio", "Sound '%s' not available yet" % id)
		return null
	return load(path) as AudioStream

func play_sfx(id: String) -> void:
	var s := _stream_for(id)
	if s == null:
		return
	var p := AudioStreamPlayer.new()
	p.bus = "SFX"
	p.stream = s
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

func play_music(id: String, fade: float = 1.0) -> void:
	var s := _stream_for(id)
	if s == null or (_music.stream == s and _music.playing):
		return
	var tween := create_tween()
	if _music.playing and fade > 0.0:
		tween.tween_property(_music, "volume_db", -40.0, fade)
	tween.tween_callback(func():
		_music.stream = s
		_music.volume_db = 0.0
		_music.play())

func play_ambience(id: String) -> void:
	var s := _stream_for(id)
	if s != null:
		_ambient.stream = s
		_ambient.play()

func stop_music() -> void:
	_music.stop()
