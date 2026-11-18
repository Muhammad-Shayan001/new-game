extends "res://scripts/world/graybox_location.gd"
## Developer test arena (LOC_DEV_TEST_ARENA): a graybox with every interaction type, a lever-operated
## door, obstacles for collision/camera tests, and an indoor room. Interactions come from
## resources/dev/interactions/*.json (placed by their "position"). Mission: MSN_TEST_ARENA.

func setup_location(location_def: Dictionary) -> void:
	super.setup_location(location_def)
	GameState.set_flag("dev_arena", true)
	_build_arena_extras()

func _box(size: Vector3, pos: Vector3, color: Color) -> StaticBody3D:
	return _body(size, pos, _material(color))

func _build_arena_extras() -> void:
	var wall_col := Color(0.35, 0.35, 0.4)
	# Wall across the arena at z=-10 with a 4m gap closed by a lever-operated door.
	_box(Vector3(24, 4, 1), Vector3(-14, 2, -10), wall_col)
	_box(Vector3(24, 4, 1), Vector3(14, 2, -10), wall_col)
	var door := Mechanism.new()
	door.name = "Door"
	door.watch_flag = "test_door_open"
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4, 4, 1)
	cs.shape = shape
	door.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(4, 4, 1)
	mi.mesh = bm
	mi.material_override = _material(Color(0.6, 0.35, 0.2))
	door.add_child(mi)
	door.position = Vector3(0, 2, -10)
	add_child(door)
	# Pillars and a low wall: collision and camera-obstruction practice.
	for p in [Vector3(-8, 1.5, 2), Vector3(8, 1.5, 4), Vector3(-3, 1.5, -6), Vector3(3, 1.5, -6)]:
		_box(Vector3(1.2, 3, 1.2), p, Color(0.5, 0.42, 0.35))
	_box(Vector3(8, 1.0, 0.6), Vector3(-10, 0.5, -4), Color(0.45, 0.45, 0.5))
	# Indoor room (ceiling + 3 walls) with a CameraZone using the 'indoor' preset.
	var rc := Color(0.5, 0.5, 0.55)
	_box(Vector3(10, 0.4, 12), Vector3(-18, 3.2, 12), rc)               # ceiling
	_box(Vector3(10, 3, 0.4), Vector3(-18, 1.5, 18), rc)                # back wall
	_box(Vector3(0.4, 3, 12), Vector3(-23, 1.5, 12), rc)                # left wall
	_box(Vector3(0.4, 3, 12), Vector3(-13, 1.5, 12), rc)                # right wall
	var zone := CameraZone.new()
	zone.name = "IndoorZone"
	zone.preset = "indoor"
	var zs := CollisionShape3D.new()
	var zb := BoxShape3D.new()
	zb.size = Vector3(10, 3, 12)
	zs.shape = zb
	zone.add_child(zs)
	zone.position = Vector3(-18, 1.5, 12)
	add_child(zone)
