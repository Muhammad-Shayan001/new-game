class_name LocationPortal
extends Area3D
## Walk-through connection to another location. Gated by chapter; hidden routes are only visible
## (and usable) while Memory Sight reveals them.

@export var target_location: String = ""
@export var from_location: String = ""
@export var route: String = "main"             # main | optional | hidden | transition
@export var gate_chapter: int = 1
@export var label_text: String = ""

var _label: Label3D
var _mesh: MeshInstance3D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	monitoring = true
	body_entered.connect(_on_body)
	if not has_node("Shape"):
		var cs := CollisionShape3D.new()
		cs.name = "Shape"
		var box := BoxShape3D.new()
		box.size = Vector3(2.4, 3.0, 1.2)
		cs.shape = box
		cs.position.y = 1.5
		add_child(cs)
	_mesh = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.0, 2.8, 0.2)
	_mesh.mesh = bm
	_mesh.position.y = 1.4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _route_color()
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.4
	_mesh.material_override = mat
	add_child(_mesh)
	_label = Label3D.new()
	_label.text = label_text
	_label.position.y = 3.3
	_label.pixel_size = 0.01
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	add_child(_label)
	if route == "hidden":
		add_to_group("memory_sight_target")
		set_revealed(false)

func _route_color() -> Color:
	match route:
		"hidden": return Color(0.7, 0.4, 1.0)
		"optional": return Color(0.4, 0.8, 0.6)
		"transition": return Color(1.0, 0.7, 0.2)
	return Color(0.4, 0.7, 1.0)

func set_revealed(on: bool) -> void:
	visible = on
	monitoring = on

func is_open() -> bool:
	return GameState.chapter >= gate_chapter

func _on_body(body: Node) -> void:
	if not body is PlayerController or target_location == "" or not visible:
		return
	if not is_open():
		EventBus.toast_requested.emit(Loc.t("ui.path_closed"))
		return
	SceneManager.go_to_location(target_location, "from_" + from_location)
