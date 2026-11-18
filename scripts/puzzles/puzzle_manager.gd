extends Node
## Puzzle state and validation. Definitions: resources/puzzles/*.json.
## Types: sequence (exact order), set (any order), code (string equality).
## Puzzle scenes only call submit() / hint(); rules and rewards live in data.

const SAVE_KEY := "puzzles"
var _solved: Array = []
var _hints_used: Dictionary = {}     # puzzle_id -> int

func _ready() -> void:
	SaveManager.register_provider(SAVE_KEY, self)

func is_solved(id: String) -> bool:
	return id in _solved

func submit(id: String, answer: Variant) -> bool:
	var def := DataRegistry.get_def("puzzles", id)
	if def.is_empty():
		Log.error("Puzzle", "Unknown puzzle '%s'" % id)
		return false
	if is_solved(id):
		return true
	if _matches(def, answer):
		mark_solved(id)
		return true
	EventBus.puzzle_failed.emit(id)
	return false

func _matches(def: Dictionary, answer: Variant) -> bool:
	var solution: Array = def["solution"]
	match str(def["type"]):
		"sequence":
			return answer is Array and answer == solution
		"set":
			if not answer is Array or answer.size() != solution.size():
				return false
			for s in solution:
				if s not in answer:
					return false
			return true
		"code":
			return _as_code(answer) == _as_code(solution)
	Log.error("Puzzle", "Unknown puzzle type '%s'" % def["type"])
	return false

## Codes may be given as "417", [4, 1, 7] or ["4","1","7"]; all compare equal.
static func _as_code(v: Variant) -> String:
	if v is Array:
		var out := ""
		for x in v:
			out += str(x)
		return out
	return str(v)

func mark_solved(id: String) -> void:
	if is_solved(id):
		return
	_solved.append(id)
	var def := DataRegistry.get_def("puzzles", id)
	if def.has("on_solved"):
		Effects.run(def["on_solved"])
	EventBus.puzzle_solved.emit(id)

## Returns the localization key of the next hint tier, or "" if none is available.
func hint(id: String) -> String:
	var hints: Array = DataRegistry.get_def("puzzles", id).get("hints", [])
	var used := int(_hints_used.get(id, 0))
	var limit := mini(hints.size(), int(Settings.value("hint_tier_max")))
	if used >= limit:
		return ""
	_hints_used[id] = used + 1
	var key: String = hints[used]
	EventBus.puzzle_hint_given.emit(id, key)
	return key

func hints_used(id: String) -> int:
	return int(_hints_used.get(id, 0))

func save_data() -> Dictionary:
	return {"solved": _solved.duplicate(), "hints_used": _hints_used.duplicate()}

func load_data(d: Dictionary) -> void:
	_solved = d.get("solved", []).duplicate()
	_hints_used = {}
	for k: String in d.get("hints_used", {}):
		_hints_used[k] = int(d["hints_used"][k])

func reset_data() -> void:
	_solved = []
	_hints_used = {}
