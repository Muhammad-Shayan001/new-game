extends Node3D
## Builds a capsule + "nose" placeholder body so the facing direction is visible before art exists.
## Replace by deleting the generated 'Body' and adding an imported character model under this node.

func _ready() -> void:
	if has_node("Body") or get_child_count() > 0:
		return
	var body := MeshInstance3D.new()
	body.name = "Body"
	var cap := CapsuleMesh.new()
	cap.radius = 0.3
	cap.height = 1.7
	body.mesh = cap
	body.position.y = 0.85
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.55, 0.75)
	body.material_override = mat
	add_child(body)
	var nose := MeshInstance3D.new()
	nose.name = "Nose"
	var box := BoxMesh.new()
	box.size = Vector3(0.14, 0.14, 0.3)
	nose.mesh = box
	nose.position = Vector3(0, 1.35, -0.32)
	var nmat := StandardMaterial3D.new()
	nmat.albedo_color = Color(1.0, 0.85, 0.3)
	nose.material_override = nmat
	body.add_child(nose)
	nose.position = Vector3(0, 0.5, -0.32)
