extends Node
## Localization. String tables live in res://resources/localization/<lang>*.json (flat key -> text).
## Files whose name starts with "<lang>" are merged (e.g. en.json + en_world.json).
## Text may contain {placeholders} replaced from the args dictionary.

const DIR := "res://resources/localization"
const LANGUAGES: PackedStringArray = ["en", "ur"]
const RTL_LANGUAGES: PackedStringArray = ["ur"]

var language: String = "en"
var _tables: Dictionary = {}     # lang -> {key -> text}
var _missing_logged: Dictionary = {}

func _ready() -> void:
	for lang in LANGUAGES:
		_load_language(lang)
	set_language(str(Settings.value("language")))
	EventBus.settings_changed.connect(_on_setting)

func _on_setting(key: String, v: Variant) -> void:
	if key == "language":
		set_language(str(v))

func _load_language(lang: String) -> void:
	var table := {}
	for path in JsonLoader.list_files(DIR):
		if path.get_file().begins_with(lang):
			table.merge(JsonLoader.load_dict(path), true)
	_tables[lang] = table

func set_language(lang: String) -> void:
	language = lang if _tables.has(lang) else "en"

func is_rtl() -> bool:
	return language in RTL_LANGUAGES

func has_key(key: String, lang: String = "en") -> bool:
	return _tables.get(lang, {}).has(key)

func t(key: String, args: Dictionary = {}) -> String:
	var text: String = ""
	if _tables.get(language, {}).has(key):
		text = _tables[language][key]
	elif _tables.get("en", {}).has(key):
		text = _tables["en"][key]
	else:
		if not _missing_logged.has(key):
			_missing_logged[key] = true
			Log.warn("Loc", "Missing localization key '%s'" % key)
		return key
	return text.format(args) if not args.is_empty() else text
