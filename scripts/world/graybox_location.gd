extends LocationRoot
## Generates a playable graybox for any location from its data: floor, bounds, lighting, portals to
## every connected location, memory-fragment pickups, and interactions whose "location" matches.
## Used until a hand-built scene exists (set "scene" in the location JSON to override).

const REGION_COLORS := {"EC": Color(0.32, 0.35, 0.5), "UM": Color(0.3, 0.3, 0.32), "DL": Color(0.45, 0.35, 0.6),
	"MH": Color(0.7, 0.75, 0.78), "BF": Color(0.2, 0.35, 0.25), "SD": Color(0.2, 0.4, 0.45), "CR": Color(0.5, 0.5, 0.55)}

const TYPE_COLORS := {"npc": Color(0.9, 0.6, 0.3), "phone": Color(0.4, 0.9, 0.5), "door": Color(0.6, 0.4, 0.3),
	"note": Color(0.95, 0.95, 0.7), "document": Color(0.95, 0.95, 0.7), "computer": Color(0.3, 0.8, 0.9),
	"puzzle": Color(0.8, 0.4, 0.9), "mechanism": Color(0.9, 0.3, 0.3), "memory": Color(0.5, 0.9, 1.0), "pickup": Color(0.9, 0.9, 0.3)}

func setup_location(location_def: Dictionary) -> void:
	super.setup_location(location_def)
	var type := str(def.get("type", "exterior"))
	var size := _size_for(type)
	_build_floor_and_bounds(size, type)
	_build_environment()
	_build_title()
	_place_spawns(size)
	_build_portals(size)
	_build_fragments()
	_build_interactions()

func _size_for(type: String) -> Vector2:
	match type:
		"interior": return Vector2(26, 26)
		"tunnel": return Vector2(14, 56)
		"platform": return Vector2(20, 50)
		"street": return Vector2(22, 70)
	return Vector2(56, 56)

func _material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m

func _body(size: Vector3, pos: Vector3, mat: StandardMaterial3D = null, visible_mesh: bool = true) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = 1
	b.position = pos
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	b.add_child(cs)
	if visible_mesh:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = size
		mi.mesh = bm
		mi.material_override = mat
		b.add_child(mi)
	add_child(b)
	return b

func _build_floor_and_bounds(size: Vector2, type: String) -> void:
	var color: Color = REGION_COLORS.get(str(def.get("region", "EC")), Color(0.4, 0.4, 0.4))
	_body(Vector3(size.x, 1.0, size.y), Vector3(0, -0.5, 0), _material(color))
	var walls_visible := type == "interior" or type == "tunnel" or type == "platform"
	var wm := _material(color.darkened(0.25))
	var h := 5.0
	_body(Vector3(size.x, h, 1), Vector3(0, h / 2, -size.y / 2), wm, walls_visible)
	_body(Vector3(size.x, h, 1), Vector3(0, h / 2, size.y / 2), wm, walls_visible)
	_body(Vector3(1, h, size.y), Vector3(-size.x / 2, h / 2, 0), wm, walls_visible)
	_body(Vector3(1, h, size.y), Vector3(size.x / 2, h / 2, 0), wm, walls_visible)

func _build_environment() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 0.9
	add_child(sun)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.09, 0.1, 0.18)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.55, 0.75)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _build_title() -> void:
	var l := Label3D.new()
	l.text = Loc.t(str(def.get("name_key", "")))
	l.position = Vector3(0, 4.2, -_size_for(str(def.get("type", ""))).y / 2 + 2)
	l.pixel_size = 0.012
	l.modulate = Color(1, 1, 1, 0.9)
	add_child(l)

func _place_spawns(size: Vector2) -> void:
	var m := Marker3D.new()
	m.name = "default"
	m.add_to_group("spawn")
	m.position = Vector3(0, 0.1, size.y * 0.22)
	add_child(m)

func _ring_position(index: int, count: int, size: Vector2) -> Vector3:
	var ang := TAU * float(index) / maxf(1.0, float(count)) + PI / 2.0
	var rx := size.x * 0.5 - 3.0
	var rz := size.y * 0.5 - 3.0
	return Vector3(cos(ang) * rx, 0.0, -sin(ang) * rz)

func _build_portals(size: Vector2) -> void:
	var conns: Array = def.get("connections", [])
	for i in conns.size():
		var c: Dictionary = conns[i]
		var pos := _ring_position(i, conns.size(), size)
		var p := LocationPortal.new()
		p.name = "Portal_" + str(c["to"])
		p.target_location = str(c["to"])
		p.from_location = location_id
		p.route = str(c.get("route", "main"))
		p.gate_chapter = int(c.get("gate_chapter", 1))
		var target_def := SceneManager.get_location_def(p.target_location)
		p.label_text = Loc.t(str(target_def.get("name_key", p.target_location)))
		p.position = pos
		p.look_at_from_position(pos, Vector3.ZERO, Vector3.UP)
		add_child(p)
		var sp := Marker3D.new()
		sp.name = "from_" + p.target_location
		sp.add_to_group("spawn")
		sp.position = pos.move_toward(Vector3.ZERO, 3.5)
		add_child(sp)

func _fixed_pos(index: int, radius: float) -> Vector3:
	var ang := index * 1.1 + 0.7
	return Vector3(cos(ang) * radius, 0.5, sin(ang) * radius)

func _build_fragments() -> void:
	var i := 0
	for f: Dictionary in DataRegistry.all_defs("fragments"):
		if f["location"] != location_id:
			continue
		var it := Interactable.new()
		it.name = "Fragment_" + str(f["id"])
		var d := {"id": "INT_FRAG_" + str(f["id"]), "type": "memory", "fragment_id": f["id"],
			"hide_when": {"has_fragment": f["id"]}}
		var mi := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.22
		sph.height = 0.44
		mi.mesh = sph
		var m := _material(Color(0.5, 0.9, 1.0) if f["kind"] != "Deep" else Color(1.0, 0.8, 0.3))
		m.emission_enabled = true
		m.emission = m.albedo_color
		m.emission_energy_multiplier = 0.8
		mi.material_override = m
		it.add_child(mi)
		it.position = _fixed_pos(i, 5.5)
		it.configure(d)
		if f["kind"] != "Core":
			it.add_to_group("memory_sight_target")   # optional memories are revealed by Memory Sight
			it.visible = false
		add_child(it)
		i += 1

func _build_interactions() -> void:
	var i := 0
	for d: Dictionary in DataRegistry.all_defs("interactions"):
		if d.get("location", "") != location_id:
			continue
		var it := Interactable.new()
		it.name = "Int_" + str(d["id"])
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.7, 1.3, 0.7)
		mi.mesh = bm
		mi.position.y = 0.65
		mi.material_override = _material(TYPE_COLORS.get(str(d["type"]), Color(0.8, 0.8, 0.4)))
		it.add_child(mi)
		var tag := Label3D.new()
		tag.text = str(d["type"])
		tag.position = Vector3(0, 1.7, 0)
		tag.pixel_size = 0.008
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		it.add_child(tag)
		var pos_arr: Array = d.get("position", [])
		it.position = Vector3(pos_arr[0], pos_arr[1], pos_arr[2]) if pos_arr.size() == 3 else _fixed_pos(i + 7, 3.5)
		it.configure(d)
		add_child(it)
		i += 1
