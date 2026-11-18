extends AbilityBase
## Time Echo: records the player's position every physics frame, then replays it as a ghost
## ("time_echo_ghost" group) that can hold switches. Recording length = def.duration.
const MAX_SAMPLES := 600
var samples: Array[Vector3] = []

func on_activate() -> void:
	samples.clear()

func on_tick(_delta: float) -> void:
	var player := tree.get_first_node_in_group("player") as Node3D
	if player and samples.size() < MAX_SAMPLES:
		samples.append(player.global_position)

func on_end() -> void:
	if samples.is_empty():
		return
	for g in tree.get_nodes_in_group("time_echo_ghost"):
		g.queue_free()
	var ghost := Node3D.new()
	ghost.name = "TimeEchoGhost"
	ghost.add_to_group("time_echo_ghost")
	var mesh := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.3
	cap.height = 1.7
	mesh.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.9, 1.0, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat
	ghost.add_child(mesh)
	ghost.set_script(preload("res://scripts/abilities/time_echo_ghost.gd"))
	ghost.set("path", samples.duplicate())
	tree.current_scene.add_child(ghost) if tree.current_scene else tree.root.add_child(ghost)
