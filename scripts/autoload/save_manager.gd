extends Node
## Local JSON save system with versioning and a backup copy.

const SAVE_VERSION := 1
const SAVE_PATH := "user://save_slot_%d.json"

func save_game(slot: int = 0) -> bool:
	var data := {"version": SAVE_VERSION, "state": GameState.to_dict()}
	var path := SAVE_PATH % slot
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path, path + ".bak")
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Save failed: %s" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(JSON.stringify(data))
	return true

func load_game(slot: int = 0) -> bool:
	var path := SAVE_PATH % slot
	if not FileAccess.file_exists(path):
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("state"):
		push_error("Corrupt save: %s" % path)
		return false
	GameState.from_dict(parsed["state"])
	return true
