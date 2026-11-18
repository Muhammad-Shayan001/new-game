extends AbilityBase
## Memory Sight: reveals every node in group "memory_sight_target" (hidden writing, ladders, portals).

func on_activate() -> void:
	for n in tree.get_nodes_in_group("memory_sight_target"):
		if n.has_method("set_revealed"):
			n.set_revealed(true)
		elif "visible" in n:
			n.visible = true

func on_end() -> void:
	for n in tree.get_nodes_in_group("memory_sight_target"):
		if n.has_method("set_revealed"):
			n.set_revealed(false)
		elif "visible" in n:
			n.visible = false
