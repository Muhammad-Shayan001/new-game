class_name JsonLoader
extends RefCounted
## Safe JSON file access. Never throws; returns empty containers on failure and logs the reason.

static func load_variant(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		Log.error("JsonLoader", "File not found: %s" % path)
		return null
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		Log.error("JsonLoader", "%s line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data

static func load_dict(path: String) -> Dictionary:
	var v: Variant = load_variant(path)
	return v if v is Dictionary else {}

## Recursively lists files with the given extension under dir (sorted, deterministic).
static func list_files(dir_path: String, ext: String = "json") -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	var names := Array(dir.get_files())
	names.sort()
	for f: String in names:
		if f.get_extension() == ext:
			out.append(dir_path.path_join(f))
	var subs := Array(dir.get_directories())
	subs.sort()
	for d: String in subs:
		out.append_array(list_files(dir_path.path_join(d), ext))
	return out
