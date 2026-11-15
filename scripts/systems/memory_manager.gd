extends Node
## Memory Fragments: Core (story), Hidden (optional), Deep (3 total, secret ending).

func collect(fragment_id: String) -> bool:
	var def := DataRegistry.get_fragment(fragment_id)
	if def == null:
		GameLog.error("Memory", "unknown fragment '%s'" % fragment_id)
		return false
	if not GameState.unlock_memory(fragment_id):
		return false
	if def.fragment_kind == FragmentDef.Kind.DEEP:
		GameState.set_flag("deep_fragments", int(GameState.get_flag("deep_fragments", 0)) + 1)
	EventBus.fragment_collected.emit(fragment_id)
	EventBus.toast_requested.emit("TOAST_MEMORY_RECOVERED", "reward")
	if def.flashback_scene != "":
		EventBus.cutscene_requested.emit(def.flashback_scene)
	EventBus.autosave_requested.emit("memory_pickup")
	return true

func collected_count(kind: FragmentDef.Kind) -> int:
	var n := 0
	for f in DataRegistry.all("fragment"):
		if f.fragment_kind == kind and GameState.has_memory(f.id):
			n += 1
	return n

func total_count(kind: FragmentDef.Kind) -> int:
	var n := 0
	for f in DataRegistry.all("fragment"):
		if f.fragment_kind == kind:
			n += 1
	return n
