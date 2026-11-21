class_name EchoSite
extends Area3D
## Where Time Echo works. echo_id set = replay of that TimeEchoDef; allow_recording = the
## player may record a ghost copy here (and use the ability again anywhere to stop).

@export var echo_id: String = ""
@export var allow_recording: bool = false
@export var hint_key: String = "HINT_ECHO_SITE"

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(func(body): if body is Player: TimeEchoManager.set_site(self))
	body_exited.connect(func(body): if body is Player: TimeEchoManager.clear_site(self))

func _exit_tree() -> void:
	TimeEchoManager.clear_site(self)
