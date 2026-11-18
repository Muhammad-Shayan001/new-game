extends AbilityBase
## Echo Voice: wakes every node in group "echo_voice_target" by calling on_echo_voice().

func on_activate() -> void:
	for n in tree.get_nodes_in_group("echo_voice_target"):
		if n.has_method("on_echo_voice"):
			n.on_echo_voice()
