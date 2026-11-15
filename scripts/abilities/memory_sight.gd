class_name MemorySightBehavior
extends AbilityBehavior
## Reveals echoes, hidden writing and clue glow. Any node can opt in by joining
## the group "memory_sight_reveal" and implementing set_revealed(bool).

func activate() -> void:
	get_tree().call_group("memory_sight_reveal", "set_revealed", true)

func deactivate() -> void:
	get_tree().call_group("memory_sight_reveal", "set_revealed", false)
