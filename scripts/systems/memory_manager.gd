extends Node
## Memory fragments (30 in the game; kinds: Core, Hidden, Deep). Definitions: resources/fragments/.

const SAVE_KEY := "memory"
var _collected: Array = []

func _ready() -> void:
	SaveManager.register_provider(SAVE_KEY, self)

func collect(id: String) -> bool:
	if not DataRegistry.has_def("fragments", id):
		Log.error("Memory", "Unknown fragment '%s'" % id)
		return false
	if id in _collected:
		return false
	_collected.append(id)
	EventBus.fragment_collected.emit(id)
	var def := DataRegistry.get_def("fragments", id)
	if def.has("on_collect"):
		Effects.run(def["on_collect"])
	return true

func has_fragment(id: String) -> bool:
	return id in _collected

func count() -> int:
	return _collected.size()

func deep_count() -> int:
	var n := 0
	for id: String in _collected:
		if DataRegistry.get_def("fragments", id).get("kind", "") == "Deep":
			n += 1
	return n

func collected_in_chapter(chapter: int) -> int:
	var n := 0
	for id: String in _collected:
		if int(DataRegistry.get_def("fragments", id).get("chapter", 0)) == chapter:
			n += 1
	return n

func save_data() -> Dictionary:
	return {"collected": _collected.duplicate()}

func load_data(d: Dictionary) -> void:
	_collected = d.get("collected", []).duplicate()

func reset_data() -> void:
	_collected = []
