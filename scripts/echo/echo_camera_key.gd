class_name EchoCameraKey
extends Resource
## Camera framing during an echo. Positions are in the location's local space.

@export var time: float = 0.0
@export var position: Vector3 = Vector3(0, 2, 4)
@export var look_at: Vector3 = Vector3.ZERO
@export var fov: float = 65.0
