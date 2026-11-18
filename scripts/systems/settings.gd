extends Node
## Player settings, stored separately from save games (user://settings.cfg).

const PATH := "user://settings.cfg"
const DEFAULTS := {
	"master_volume": 1.0, "music_volume": 0.8, "sfx_volume": 1.0, "voice_volume": 1.0, "ambient_volume": 0.8,
	"language": "en", "subtitles": true, "text_scale": 1.0,
	"camera_sensitivity": 1.0, "invert_y": false, "left_handed": false, "reduced_motion": false,
	"quality": 1,                 # 0 low, 1 medium, 2 high
	"touch_controls": "auto",     # auto | on | off
	"sprint_toggle": false, "memory_pulse": true, "hint_tier_max": 3, "interaction_assist": false,
}

var _values: Dictionary = DEFAULTS.duplicate()

func _ready() -> void:
	load_settings()

func value(key: String) -> Variant:
	return _values.get(key, DEFAULTS.get(key))

func set_value(key: String, v: Variant, persist: bool = true) -> void:
	if not DEFAULTS.has(key):
		Log.warn("Settings", "Unknown setting '%s'" % key)
		return
	if _values.get(key) == v:
		return
	_values[key] = v
	EventBus.settings_changed.emit(key, v)
	if persist:
		save_settings()

func reset_to_defaults() -> void:
	for k: String in DEFAULTS:
		set_value(k, DEFAULTS[k], false)
	save_settings()

func save_settings() -> void:
	var cfg := ConfigFile.new()
	for k: String in _values:
		cfg.set_value("settings", k, _values[k])
	var err := cfg.save(PATH)
	if err != OK:
		Log.warn("Settings", "Could not write settings (%s)" % error_string(err))

func load_settings() -> void:
	_values = DEFAULTS.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for k: String in DEFAULTS:
		var v: Variant = cfg.get_value("settings", k, DEFAULTS[k])
		if typeof(v) == typeof(DEFAULTS[k]):
			_values[k] = v
