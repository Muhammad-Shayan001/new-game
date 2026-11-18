extends Node
## Items and clues. Definitions: resources/items/*.json (kind: clue | key | memory | tool).

const SAVE_KEY := "inventory"
var _items: Dictionary = {}   # item_id -> count

func _ready() -> void:
	SaveManager.register_provider(SAVE_KEY, self)

func add_item(id: String, count: int = 1) -> bool:
	if not DataRegistry.has_def("items", id):
		Log.error("Inventory", "Unknown item '%s'" % id)
		return false
	var def := DataRegistry.get_def("items", id)
	var stackable: bool = def.get("stackable", false)
	if not stackable and _items.has(id):
		return false
	_items[id] = int(_items.get(id, 0)) + (count if stackable else 1)
	EventBus.item_added.emit(id)
	return true

func remove_item(id: String, count: int = 1) -> bool:
	if not _items.has(id):
		return false
	_items[id] = int(_items[id]) - count
	if _items[id] <= 0:
		_items.erase(id)
	EventBus.item_removed.emit(id)
	return true

func has_item(id: String) -> bool:
	return _items.has(id)

func count_of(id: String) -> int:
	return int(_items.get(id, 0))

func items_by_kind(kind: String) -> Array:
	var out: Array = []
	for id: String in _items:
		if DataRegistry.get_def("items", id).get("kind", "") == kind:
			out.append(id)
	return out

func save_data() -> Dictionary:
	return {"items": _items.duplicate()}

func load_data(d: Dictionary) -> void:
	_items = {}
	for k: String in d.get("items", {}):
		_items[k] = int(d["items"][k])

func reset_data() -> void:
	_items = {}
