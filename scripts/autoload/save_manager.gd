extends Node
## Versioned, checksummed, crash-safe local saves. 1 auto slot (0) + 3 manual slots (1..3).
## File layout and migration rules: docs/DATA_SCHEMA.md.

const AUTO_SLOT := 0
const MANUAL_SLOTS := [1, 2, 3]
const AUTOSAVE_INTERVAL := 180.0
const SAVE_DIR := "user://saves"

var last_error: String = ""
var save_dir: String = SAVE_DIR   # tests point this at a temporary folder

var _timer: Timer

func _ready() -> void:
	EventBus.autosave_requested.connect(autosave)
	_timer = Timer.new()
	_timer.wait_time = AUTOSAVE_INTERVAL
	_timer.timeout.connect(func(): autosave("timer"))
	add_child(_timer)
	_timer.start()

func slot_path(slot: int) -> String:
	return "%s/save_slot_%d.json" % [save_dir, slot]

func is_valid_slot(slot: int) -> bool:
	return slot == AUTO_SLOT or slot in MANUAL_SLOTS

## Autosave is skipped while GameState.autosave_blocks > 0 (unsafe moments).
func autosave(reason: String = "") -> bool:
	if GameState.autosave_blocks > 0:
		return false
	return save_game(AUTO_SLOT)

func save_game(slot: int = AUTO_SLOT) -> bool:
	last_error = ""
	if not is_valid_slot(slot):
		return _fail_save(slot, "invalid slot %d" % slot)
	DirAccess.make_dir_recursive_absolute(save_dir)
	var state_json := JSON.stringify(GameState.to_dict(), "", true)
	var envelope := {
		"version": GameVersion.SAVE_VERSION,
		"game_version": GameVersion.GAME_VERSION,
		"saved_at": int(Time.get_unix_time_from_system()),
		"meta": {
			"chapter": GameState.chapter, "location": GameState.current_location,
			"playtime": int(GameState.playtime_seconds),
		},
		"checksum": state_json.sha256_text(),
		"state_json": state_json,
	}
	var path := slot_path(slot)
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return _fail_save(slot, "cannot write %s: %s" % [tmp, error_string(FileAccess.get_open_error())])
	f.store_string(JSON.stringify(envelope))
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path, path + ".bak")
		DirAccess.remove_absolute(path)
	var err := DirAccess.rename_absolute(tmp, path)
	if err != OK:
		return _fail_save(slot, "rename failed: %s" % error_string(err))
	EventBus.save_finished.emit(slot, true)
	return true

func _fail_save(slot: int, reason: String) -> bool:
	last_error = reason
	GameLog.error("Save", reason)
	EventBus.save_finished.emit(slot, false)
	return false

## Loads a slot into GameState. Falls back to the .bak copy when the main file is
## missing, corrupt or fails its checksum. Never partially applies a bad save.
func load_game(slot: int = AUTO_SLOT) -> bool:
	last_error = ""
	if not is_valid_slot(slot):
		last_error = "invalid slot %d" % slot
		return false
	var path := slot_path(slot)
	var result := _read_state(path)
	if not result.ok and FileAccess.file_exists(path + ".bak"):
		GameLog.warn("Save", "%s unreadable (%s); trying backup" % [path, result.error])
		result = _read_state(path + ".bak")
	if not result.ok:
		last_error = result.error
		EventBus.load_finished.emit(slot, false)
		return false
	GameState.from_dict(result.state)
	EventBus.load_finished.emit(slot, true)
	return true

## Returns {"ok": bool, "error": String, "state": Dictionary, "meta": Dictionary}.
func _read_state(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "no save file"}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "error": "corrupt save (not JSON)"}
	var version := int(parsed.get("version", 0))
	if version > GameVersion.SAVE_VERSION:
		return {"ok": false, "error": "save is from a newer game version (%d)" % version}
	if version < GameVersion.MIN_SUPPORTED_SAVE_VERSION:
		return {"ok": false, "error": "save version %d is no longer supported" % version}
	var state: Variant
	if parsed.has("state_json"):                       # v2 format
		var text: String = parsed["state_json"]
		if str(parsed.get("checksum", "")) != text.sha256_text():
			return {"ok": false, "error": "checksum mismatch (save was modified or damaged)"}
		state = JSON.parse_string(text)
	else:                                              # v1 legacy: {"version":1,"state":{...}}
		state = parsed.get("state")
	if typeof(state) != TYPE_DICTIONARY:
		return {"ok": false, "error": "corrupt save (no state)"}
	return {"ok": true, "error": "", "state": _migrate(state, version),
		"meta": parsed.get("meta", {})}

## Upgrades a state dictionary step by step until it matches SAVE_VERSION.
func _migrate(state: Dictionary, from_version: int) -> Dictionary:
	var v := from_version
	while v < GameVersion.SAVE_VERSION:
		match v:
			1: # v1 -> v2: missions, inventory, abilities, puzzles, relationships were added.
				for key in ["mission_states", "mission_progress", "inventory", "puzzles", "relationships"]:
					state.get_or_add(key, {})
				for key in ["abilities", "choices", "deductions"]:
					state.get_or_add(key, [])
				state.get_or_add("last_spawn_id", "default")
				state.get_or_add("playtime_seconds", 0.0)
		v += 1
	return state

## Slot summaries for the load screen.
func list_slots() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for slot in [AUTO_SLOT] + MANUAL_SLOTS:
		var info := {"slot": slot, "exists": false}
		var path := slot_path(slot)
		if FileAccess.file_exists(path):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			if typeof(parsed) == TYPE_DICTIONARY:
				var meta: Dictionary = parsed.get("meta", {})
				info = {"slot": slot, "exists": true, "saved_at": int(parsed.get("saved_at", 0)),
					"version": int(parsed.get("version", 0)), "chapter": int(meta.get("chapter", 1)),
					"location": str(meta.get("location", "")), "playtime": int(meta.get("playtime", 0))}
		out.append(info)
	return out

func delete_slot(slot: int) -> void:
	if not is_valid_slot(slot):
		return
	for p in [slot_path(slot), slot_path(slot) + ".bak", slot_path(slot) + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
