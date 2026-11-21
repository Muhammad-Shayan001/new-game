class_name EchoKey
extends Resource
## One position sample of an echo track.

@export var time: float = 0.0
@export var position: Vector3 = Vector3.ZERO
@export var yaw_degrees: float = 0.0
## Free text label for the pose or action ("loads reel", "stands"). Shown in debug and captions.
@export var state: String = ""
