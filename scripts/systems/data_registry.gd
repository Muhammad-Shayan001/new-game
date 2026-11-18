extends Node
## Loads every data definition from res://resources/<kind>/ at startup and validates it.
## All content (missions, dialogue, items, abilities, locations, puzzles, fragments, characters)
## is plain JSON, so new content needs no code changes. See docs/DATA_SCHEMA.md.

const KINDS: PackedStringArray = ["characters", "locations", "missions", "dialogue", "items",
	"abilities", "puzzles", "fragments", "interactions"]

## Required fields per kind: field -> type name ("string","number","array","dict","bool")
const SCHEMAS := {
	"characters": {"id": "string", "name_key": "string"},
	"locations": {"id": "string", "name_key": "string", "region": "string", "chapter": "number", "connections": "array"},
	"missions": {"id": "string", "name_key": "string", "chapter": "number", "type": "string", "objectives": "array"},
	"dialogue": {"id": "string", "start": "string", "nodes": "dict"},
	"items": {"id": "string", "name_key": "string", "kind": "string"},
	"abilities": {"id": "string", "name_key": "string", "slot": "number", "duration": "number", "cooldown": "number", "script": "string"},
	"puzzles": {"id": "string", "type": "string", "solution": "array"},
	"interactions": {"id": "string", "type": "string"},
	"fragments": {"id": "string", "name_key": "string", "location": "string", "kind": "string", "chapter": "number"},
}

var _defs: Dictionary = {}     # kind -> {id -> Dictionary}
var errors: PackedStringArray = PackedStringArray()

func _ready() -> void:
	reload()

func reload() -> void:
	_defs.clear()
	errors = PackedStringArray()
	for kind in KINDS:
		_defs[kind] = {}
		for path in JsonLoader.list_files("res://resources/%s" % kind):
			_load_file(kind, path)
		if OS.is_debug_build():     # developer-only content (test arenas) never ships in release exports
			for path in JsonLoader.list_files("res://resources/dev/%s" % kind):
				_load_file(kind, path)

func _load_file(kind: String, path: String) -> void:
	var data: Variant = JsonLoader.load_variant(path)
	if data == null:
		errors.append("%s: unreadable JSON" % path)
		return
	var entries: Array = []
	if data is Dictionary and data.has("entries"):
		entries = data["entries"]
	elif data is Dictionary:
		entries = [data]
	else:
		errors.append("%s: top level must be an object" % path)
		return
	for e in entries:
		if not e is Dictionary:
			errors.append("%s: entry is not an object" % path)
			continue
		var problems := validate_def(kind, e)
		if not problems.is_empty():
			for p in problems:
				errors.append("%s [%s]: %s" % [path, str(e.get("id", "?")), p])
			continue
		var id: String = e["id"]
		if _defs[kind].has(id):
			errors.append("%s: duplicate %s id %s" % [path, kind, id])
			continue
		_defs[kind][id] = e

static func validate_def(kind: String, d: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var schema: Dictionary = SCHEMAS.get(kind, {})
	for field: String in schema:
		if not d.has(field):
			out.append("missing field '%s'" % field)
			continue
		if not _type_ok(d[field], schema[field]):
			out.append("field '%s' should be %s" % [field, schema[field]])
	return out

static func _type_ok(v: Variant, type_name: String) -> bool:
	match type_name:
		"string": return v is String
		"number": return v is int or v is float
		"array": return v is Array
		"dict": return v is Dictionary
		"bool": return v is bool
	return false

## Adds a definition at runtime (DLC, mods, tests). Returns validation errors; empty = accepted.
func register_def(kind: String, d: Dictionary) -> PackedStringArray:
	var problems := validate_def(kind, d)
	if not problems.is_empty():
		return problems
	if _defs.get(kind, {}).has(d["id"]):
		return PackedStringArray(["duplicate %s id %s" % [kind, d["id"]]])
	_defs[kind][d["id"]] = d
	return PackedStringArray()

func unregister_def(kind: String, id: String) -> void:
	_defs.get(kind, {}).erase(id)

func get_def(kind: String, id: String) -> Dictionary:
	return _defs.get(kind, {}).get(id, {})

func has_def(kind: String, id: String) -> bool:
	return _defs.get(kind, {}).has(id)

func all_defs(kind: String) -> Array:
	return _defs.get(kind, {}).values()

func ids(kind: String) -> Array:
	return _defs.get(kind, {}).keys()

func count(kind: String) -> int:
	return _defs.get(kind, {}).size()
