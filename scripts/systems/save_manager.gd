extends Node
## Versioned, atomic JSON saves. Systems opt in by registering a provider
## (an object with save_data() -> Dictionary, load_data(Dictionary), reset_data()).
## Adding a new saveable system never requires editing this file.

const SCHEMA_VERSION := 2
const SLOT_COUNT := 4                  # slot 0 = autosave, 1..3 = manual
const DIR := "user://saves"
const SLOT_PATH := DIR + "/slot_%d.json"

var _providers: Dictionary = {}        # key -> Object

func register_provider(key: String, provider: Object) -> void:
	for m in ["save_data", "load_data", "reset_data"]:
		if not provider.has_method(m):
			Log.error("Save", "Provider '%s' lacks %s()" % [key, m])
			return
	_providers[key] = provider

func provider_keys() -> Array:
	return _providers.keys()

func reset_all() -> void:
	for p: Object in _providers.values():
		p.reset_data()

func _slot_path(slot: int) -> String:
	return SLOT_PATH % slot

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot)) or FileAccess.file_exists(_slot_path(slot) + ".bak")

func build_snapshot(slot: int) -> Dictionary:
	var systems := {}
	for k: String in _providers:
		systems[k] = _providers[k].save_data()
	return {
		"schema_version": SCHEMA_VERSION,
		"game_version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		"saved_at": int(Time.get_unix_time_from_system()),
		"slot": slot,
		"summary": {"chapter": GameState.chapter, "location": GameState.current_location,
			"playtime_seconds": GameState.playtime_seconds},
		"systems": systems,
	}

func save_game(slot: int = 1) -> bool:
	if slot < 0 or slot >= SLOT_COUNT:
		Log.error("Save", "Invalid slot %d" % slot)
		return false
	DirAccess.make_dir_recursive_absolute(DIR)
	var path := _slot_path(slot)
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		Log.error("Save", "Cannot open %s: %s" % [tmp, error_string(FileAccess.get_open_error())])
		return false
	f.store_string(JSON.stringify(build_snapshot(slot), "\t"))
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path, path + ".bak")
	var err := DirAccess.rename_absolute(tmp, path)
	if err != OK:
		Log.error("Save", "Rename failed: %s" % error_string(err))
		return false
	EventBus.game_saved.emit(slot)
	return true

func autosave() -> bool:
	return save_game(0)

## Loads into all providers. The scene is NOT changed here; SceneManager.continue_game does that.
func load_game(slot: int) -> bool:
	var data := _read_slot(slot)
	if data.is_empty():
		return false
	var version := int(data.get("schema_version", 1))
	if version > SCHEMA_VERSION:
		Log.error("Save", "Save is from a newer game version (schema %d)" % version)
		return false
	data = migrate(data)
	reset_all()
	var systems: Dictionary = data.get("systems", {})
	for k: String in systems:
		if _providers.has(k):
			_providers[k].load_data(systems[k])
		else:
			Log.warn("Save", "No provider for saved system '%s'; ignored" % k)
	EventBus.game_loaded.emit(slot)
	return true

func _read_slot(slot: int) -> Dictionary:
	for path in [_slot_path(slot), _slot_path(slot) + ".bak"]:
		if not FileAccess.file_exists(path):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary and (parsed.has("systems") or parsed.has("state")):
			return parsed
		Log.warn("Save", "Corrupt save %s; trying backup" % path)
	return {}

func slot_info(slot: int) -> Dictionary:
	var d := _read_slot(slot)
	if d.is_empty():
		return {}
	d = migrate(d)
	return {"slot": slot, "saved_at": d.get("saved_at", 0), "summary": d.get("summary", {})}

func delete_slot(slot: int) -> void:
	for p in [_slot_path(slot), _slot_path(slot) + ".bak"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)

## Upgrades older snapshots to SCHEMA_VERSION. One function per version step.
func migrate(data: Dictionary) -> Dictionary:
	var version := int(data.get("schema_version", 1))
	while version < SCHEMA_VERSION:
		match version:
			1: data = _migrate_1_to_2(data)
			_:
				Log.error("Save", "No migration from schema %d" % version)
				return data
		version = int(data.get("schema_version", version + 1))
	return data

func _migrate_1_to_2(old: Dictionary) -> Dictionary:
	# v1: {"version":1,"state":{chapter, flags, clues[], memories[], current_location, visited_locations}}
	var s: Dictionary = old.get("state", {})
	var items := {}
	for c in s.get("clues", []):
		items[str(c)] = 1
	return {
		"schema_version": 2, "game_version": "0.0.1", "saved_at": 0, "slot": old.get("slot", 1),
		"summary": {"chapter": s.get("chapter", 1), "location": s.get("current_location", ""), "playtime_seconds": 0.0},
		"systems": {
			"game_state": {"chapter": s.get("chapter", 1), "flags": s.get("flags", {}),
				"current_location": s.get("current_location", ""), "visited_locations": s.get("visited_locations", [])},
			"inventory": {"items": items},
			"memory": {"collected": s.get("memories", [])},
		},
	}
