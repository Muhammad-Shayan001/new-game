extends AbilityBase
## Reality Shift: toggles every node in group "shiftable" between its two states (set_shifted(bool)).
var _shifted: bool = false

func on_activate() -> void:
	_shifted = not _shifted
	for n in tree.get_nodes_in_group("shiftable"):
		if n.has_method("set_shifted"):
			n.set_shifted(_shifted)
