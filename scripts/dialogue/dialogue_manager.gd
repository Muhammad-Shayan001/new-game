extends Node
## Runs data-driven dialogue graphs (resources/dialogue/*.json). The UI listens to EventBus;
## this class never touches UI nodes.
## Node fields: speaker, text_key, next, effects[], choices[{text_key, requires, effects, next}],
## branch[{if, next}].

var active_id: String = ""
var _def: Dictionary = {}
var _next_id: String = ""
var _choice_map: Array = []       # visible choice index -> original choice dict

func is_active() -> bool:
	return active_id != ""

func start(id: String) -> bool:
	if is_active():
		Log.warn("Dialogue", "Already running '%s'; ignoring '%s'" % [active_id, id])
		return false
	var def := DataRegistry.get_def("dialogue", id)
	if def.is_empty():
		Log.error("Dialogue", "Unknown dialogue '%s'" % id)
		return false
	if def.get("once", false) and GameState.get_flag("seen:" + id):
		return false
	if not Condition.check(def.get("requires", {})):
		return false
	_def = def
	active_id = id
	InputRouter.push_lock("dialogue")
	EventBus.dialogue_started.emit(id)
	_goto(str(def["start"]))
	return true

func advance() -> void:
	if not is_active() or not _choice_map.is_empty():
		return
	_goto(_next_id)

func choose(index: int) -> void:
	if not is_active() or index < 0 or index >= _choice_map.size():
		return
	var c: Dictionary = _choice_map[index]
	_choice_map = []
	Effects.run(c.get("effects", []))
	_goto(str(c.get("next", "")))

func _goto(node_id: String) -> void:
	var guard := 0
	while node_id != "" and guard < 64:
		guard += 1
		var node: Dictionary = _def["nodes"].get(node_id, {})
		if node.is_empty():
			Log.error("Dialogue", "%s: missing node '%s'" % [active_id, node_id])
			break
		Effects.run(node.get("effects", []))
		if node.has("branch"):
			node_id = _resolve_branch(node["branch"])
			continue
		if not node.has("text_key"):
			node_id = str(node.get("next", ""))
			continue
		_show(node_id, node)
		return
	_finish()

func _resolve_branch(branches: Array) -> String:
	for b: Dictionary in branches:
		if Condition.check(b.get("if", {})):
			return str(b.get("next", ""))
	return ""

func _show(node_id: String, node: Dictionary) -> void:
	var speaker := str(node.get("speaker", ""))
	EventBus.dialogue_line_shown.emit(node_id, speaker, Loc.t(str(node["text_key"])))
	_choice_map = []
	if node.has("choices"):
		var shown: Array = []
		for c: Dictionary in node["choices"]:
			if Condition.check(c.get("requires", {})):
				_choice_map.append(c)
				shown.append({"index": shown.size(), "text": Loc.t(str(c["text_key"]))})
		if not shown.is_empty():
			EventBus.dialogue_choices_shown.emit(shown)
			return
	_next_id = str(node.get("next", ""))

func _finish() -> void:
	var id := active_id
	active_id = ""
	_choice_map = []
	GameState.set_flag("seen:" + id, true)
	InputRouter.pop_lock("dialogue")
	EventBus.dialogue_finished.emit(id)

func abort() -> void:
	if is_active():
		_finish()
