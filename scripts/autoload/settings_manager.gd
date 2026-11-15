extends Node
## Player settings stored in user://settings.cfg (ConfigFile). Every value has a
## default and a valid range, so a hand-edited file can never break the game.

const PATH := "user://settings.cfg"

## section/key -> [default, min, max] for numbers, or [default, [allowed values]].
const SCHEMA := {
	"audio": {
		"master": [1.0, 0.0, 1.0], "music": [0.8, 0.0, 1.0], "sfx": [0.9, 0.0, 1.0],
		"ambience": [0.8, 0.0, 1.0], "voice": [1.0, 0.0, 1.0],
	},
	"video": {
		"quality": ["medium", ["low", "medium", "high"]],
		"fov": [65.0, 55.0, 80.0],
		"fps_cap": [60, [30, 60, 120]],
	},
	"controls": {
		"look_sensitivity": [1.0, 0.25, 3.0], "invert_y": [false, [false, true]],
		"auto_interact": [false, [false, true]], "touch_opacity": [0.6, 0.2, 1.0],
		"always_show_touch": [false, [false, true]],
	},
	"accessibility": {
		"subtitles": [true, [false, true]], "subtitle_size": [1.0, 0.8, 1.6],
		"reduce_motion": [false, [false, true]],
	},
	"game": {"language": ["en", ["en"]]},
}

var _cfg := ConfigFile.new()
var path: String = PATH   # tests redirect this

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	_cfg = ConfigFile.new()
	var err := _cfg.load(path)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		GameLog.warn("Settings", "could not read %s (%s); using defaults" % [path, error_string(err)])
		_cfg = ConfigFile.new()
	apply_all()

func save_settings() -> bool:
	_cfg.set_value("meta", "version", GameVersion.SETTINGS_VERSION)
	var err := _cfg.save(path)
	if err != OK:
		GameLog.error("Settings", "could not save %s: %s" % [path, error_string(err)])
	return err == OK

func default_of(section: String, key: String) -> Variant:
	return SCHEMA[section][key][0]

## Always returns a valid value (default if missing or out of range).
func get_value(section: String, key: String) -> Variant:
	if not SCHEMA.has(section) or not SCHEMA[section].has(key):
		GameLog.error("Settings", "unknown setting %s/%s" % [section, key])
		return null
	return _sanitize(section, key, _cfg.get_value(section, key, default_of(section, key)))

func set_value(section: String, key: String, value: Variant) -> void:
	if not SCHEMA.has(section) or not SCHEMA[section].has(key):
		GameLog.error("Settings", "unknown setting %s/%s" % [section, key])
		return
	var clean: Variant = _sanitize(section, key, value)
	_cfg.set_value(section, key, clean)
	_apply(section, key, clean)
	EventBus.settings_changed.emit(section, key, clean)

func reset_to_defaults() -> void:
	_cfg = ConfigFile.new()
	apply_all()

func _sanitize(section: String, key: String, value: Variant) -> Variant:
	var rule: Array = SCHEMA[section][key]
	var default: Variant = rule[0]
	if rule[1] is Array:
		return value if value in rule[1] else default
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		return default
	return clampf(float(value), float(rule[1]), float(rule[2]))

func apply_all() -> void:
	for section in SCHEMA:
		for key in SCHEMA[section]:
			_apply(section, key, get_value(section, key))

func _apply(section: String, key: String, value: Variant) -> void:
	match [section, key]:
		["audio", _]:
			if has_node("/root/AudioManager"):
				get_node("/root/AudioManager").set_bus_volume_linear(key, float(value))
		["video", "quality"]:
			var scale: float = {"low": 0.67, "medium": 0.85, "high": 1.0}[value]
			get_tree().root.scaling_3d_scale = scale
		["video", "fps_cap"]:
			Engine.max_fps = int(value)
		["game", "language"]:
			Localization.set_locale(str(value))
