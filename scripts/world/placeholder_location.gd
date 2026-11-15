extends LocationRoot
## Stand-in for locations that have no scene yet (LocationDef.status == PLANNED).
## Shows the location name and builds a door for every open route, so the whole
## world graph can be walked and every mission tested before any art exists.

const DOOR_RADIUS := 9.0

@onready var _label: Label3D = $Title

func setup(id: String, spawn: String) -> void:
	super.setup(id, spawn)
	var def := DataRegistry.get_location(id)
	_label.text = "%s\n(%s)" % [Localization.t(def.name_key), id] if def != null else id
	if def != null:
		_build_doors(def)

func _build_doors(def: LocationDef) -> void:
	var open: Array[LocationConnection] = []
	for c in def.connections:
		var hidden_ok := c.route_type != "hidden" or GameState.has_ability("ABIL_MEMORY_SIGHT")
		if c.gate_chapter <= GameState.chapter and hidden_ok:
			open.append(c)
	for i in open.size():
		var c := open[i]
		var angle := TAU * float(i) / maxf(open.size(), 1.0)
		var door := Interactable.new()
		door.interactable_id = "INT_DOOR_%s_%d" % [def.id.trim_prefix("LOC_"), i]
		door.prompt_key = "PROMPT_ENTER"
		door.interact_priority = Interactable.Priority.STORY
		door.travel_to_location = c.to_location
		door.travel_spawn = c.spawn_id
		door.position = Vector3(cos(angle), 0.0, sin(angle)) * DOOR_RADIUS + Vector3(0, 1.0, 0)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(2.4, 2.0, 2.4)
		shape.shape = box
		door.add_child(shape)
		var mesh := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.6, 2.0, 0.3)
		mesh.mesh = bm
		door.add_child(mesh)
		var target := DataRegistry.get_location(c.to_location)
		var text := Label3D.new()
		text.text = "%s\n[%s]" % [Localization.t(target.name_key) if target != null else c.to_location, c.route_type]
		text.position = Vector3(0, 1.5, 0)
		text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		text.font_size = 36
		door.add_child(text)
		add_child(door)
