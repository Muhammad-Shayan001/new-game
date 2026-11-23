class_name EchoStation
extends LocationRoot
## Starting scene for Chapter 1: The Waking Ghost.
## Features the stopped platform clock, subway rails, and transition to Concourse.

func setup(id: String, spawn: String) -> void:
	super.setup(id, spawn)
	if not GameState.get_flag("alex_awoke_station", false):
		get_tree().create_timer(0.5).timeout.connect(_on_first_wakeup)

func _on_first_wakeup() -> void:
	if not GameState.get_flag("alex_awoke_station", false):
		DialogueManager.start("DLG_CH1_M01_WAKEUP")
		EventBus.toast_requested.emit("Move: WASD / Stick  •  Look: Mouse / Touch  •  Interact: [E]  •  Phone: [Tab]", "info")
