class_name PressurePlate
extends Area3D
## A plate held down by the player, another player, or an Echo ghost.
## A PlateController watches all plates of one puzzle.

signal changed(is_pressed: bool)

@export var puzzle_id: String = ""
@export var label_key: String = ""

var pressed := false
var _occupants: Dictionary = {}

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 | 8      # players (2) and echo ghosts (8)
	if puzzle_id != "":
		add_to_group("plates_" + puzzle_id)
	body_entered.connect(func(b): if b.is_in_group("player"): _enter(b))
	body_exited.connect(func(b): _leave(b))
	area_entered.connect(func(a): if a.is_in_group("echo_ghost_area"): _enter(a))
	area_exited.connect(func(a): _leave(a))

func _enter(who: Node) -> void:
	_occupants[who.get_instance_id()] = true
	_update()

func _leave(who: Node) -> void:
	_occupants.erase(who.get_instance_id())
	_update()

func _update() -> void:
	var now := not _occupants.is_empty()
	if now != pressed:
		pressed = now
		changed.emit(pressed)
		var mesh := get_node_or_null("Mesh") as MeshInstance3D
		if mesh != null and mesh.material_override is StandardMaterial3D:
			(mesh.material_override as StandardMaterial3D).albedo_color = \
				Color(0.95, 0.85, 0.4) if pressed else Color(0.45, 0.45, 0.5)
