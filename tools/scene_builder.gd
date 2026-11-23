class_name SceneBuilder
extends RefCounted
## Builds the three graybox puzzle scenes with real nodes and saves them as .tscn, so the
## files are valid and can be opened and edited in the Godot editor afterwards.
## Run: godot --headless --path . res://tools/content_tool.tscn -- build-scenes
## The generated scenes are normal project files; edit them in the editor from now on.

const SIGIL_CLUE := "CLUE_ANCHOR_SIGIL"
const ZONE := "SHF_CH3_ANCHOR_BRIDGE"

static func build_all() -> int:
	var written := 0
	written += _save_scene(_clock_room(), "res://scenes/world/echo_city/hid_clock_room.tscn")
	written += _save_scene(_anchor_fields(), "res://scenes/world/dreamland/anchor_fields.tscn")
	written += _save_scene(_echo_gallery(), "res://scenes/world/dreamland/echo_gallery.tscn")
	print("build-scenes: %d of 3 scenes written" % written)
	return 0 if written == 3 else 1

# --- helpers -------------------------------------------------------------------
static func _own(node: Node, root: Node) -> void:
	for c in node.get_children():
		c.owner = root
		_own(c, root)

static func _save_scene(root: Node, path: String) -> int:
	_own(root, root)
	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		printerr("could not pack " + path)
		return 0
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var err := ResourceSaver.save(packed, path)
	root.free()
	if err != OK:
		printerr("could not save %s: %s" % [path, error_string(err)])
	return 1 if err == OK else 0

static func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m

static func _box(parent: Node, node_name: String, size: Vector3, pos: Vector3, color: Color, solid: bool = true) -> Node3D:
	var holder: Node3D
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		var shape := CollisionShape3D.new()
		shape.name = "Shape"
		var bs := BoxShape3D.new()
		bs.size = size
		shape.shape = bs
		body.add_child(shape)
		holder = body
	else:
		holder = Node3D.new()
	holder.name = node_name
	holder.position = pos
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = _mat(color)
	holder.add_child(mesh)
	parent.add_child(holder)
	return holder

static func _label(parent: Node, text: String, pos: Vector3, size: int = 34) -> Label3D:
	var l := Label3D.new()
	l.name = "Label%d" % parent.get_child_count()
	l.text = text
	l.position = pos
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = size
	parent.add_child(l)
	return l

static func _cond(values: Dictionary) -> ConditionSet:
	var c := ConditionSet.new()
	for k in values:
		var current: Variant = c.get(k)
		if current is Array:
			current.assign(values[k])
		else:
			c.set(k, values[k])
	return c

static func _room(root: PrototypeLocation, root_name: String, floor_size: Vector3) -> void:
	root.name = root_name
	_box(root, "Floor", floor_size, Vector3(0, -0.5, 0), Color(0.2, 0.2, 0.24))
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-50, 30, 0)
	root.add_child(sun)

static func _spawn(root: Node, pos: Vector3) -> void:
	var s := Marker3D.new()
	var spawn_script := load("res://scripts/world/spawn_point.gd") as Script
	if spawn_script != null:
		s.set_script(spawn_script)
		s.set("spawn_id", "default")
	s.name = "Spawn"
	s.position = pos
	root.add_child(s)

## Adds an Interactable-derived node with a reach shape and a small marker mesh.
static func _use(parent: Node, node: Interactable, node_name: String, id: String, pos: Vector3,
		prompt: String, prio: Interactable.Priority, color: Color = Color(0.85, 0.75, 0.3), reach: Vector3 = Vector3(1.8, 1.8, 1.8)) -> Interactable:
	node.name = node_name
	node.interactable_id = id
	node.position = pos
	node.prompt_key = prompt
	node.interact_priority = prio
	var shape := CollisionShape3D.new()
	shape.name = "Reach"
	var bs := BoxShape3D.new()
	bs.size = reach
	shape.shape = bs
	node.add_child(shape)
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5, 0.5, 0.5)
	mesh.mesh = bm
	mesh.material_override = _mat(color)
	node.add_child(mesh)
	parent.add_child(node)
	return node

static func _zone_area(node: Area3D, node_name: String, pos: Vector3, size: Vector3) -> void:
	node.name = node_name
	node.position = pos
	var shape := CollisionShape3D.new()
	shape.name = "Shape"
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	node.add_child(shape)
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var bm := BoxMesh.new()
	bm.size = Vector3(size.x, 0.05, size.z)
	mesh.mesh = bm
	mesh.position.y = -size.y / 2.0 + 0.05
	mesh.material_override = _mat(Color(0.35, 0.5, 0.75))
	node.add_child(mesh)

# --- Memory Sight: the clock room --------------------------------------------------------------
static func _clock_room() -> Node:
	var root := PrototypeLocation.new()
	_room(root, "HidClockRoom", Vector3(34, 1, 34))
	root.door_row_origin = Vector3(-4, 1, 13)
	_spawn(root, Vector3(0, 0.5, 8))
	var clock := _box(root, "Clock", Vector3(3, 3, 0.4), Vector3(0, 2.5, -12), Color(0.15, 0.15, 0.17))
	_label(clock, "4:17", Vector3(0, 0, 0.4), 72)
	# Observation: writing that only exists while Memory Sight is active.
	var writing := Revealable.new()
	writing.name = "HiddenWriting"
	writing.position = Vector3(-9, 1.8, -6)
	writing.interactable_path = NodePath("Examine")
	writing.stay_visible_once_found = true
	var panel := MeshInstance3D.new()
	panel.name = "Panel"
	var pm := BoxMesh.new()
	pm.size = Vector3(3.2, 1.4, 0.1)
	panel.mesh = pm
	panel.material_override = _mat(Color(0.3, 0.45, 0.6))
	writing.add_child(panel)
	_label(writing, "THE HOUR IS A PROMISE:\n4 . 1 . 7", Vector3(0, 0, 0.2), 40)
	var examine := _use(writing, Interactable.new(), "Examine", "INT_EC_HID_CLOCK_ROOM_WRITING", Vector3.ZERO,
		"PROMPT_EXAMINE", Interactable.Priority.CLUE, Color(0.4, 0.7, 0.9), Vector3(3.5, 2, 2.5))
	examine.give_clue = "CLUE_CLOCK_WALL_WRITING"
	examine.once = true
	root.add_child(writing)
	# Echo Detection target: a memory trace only Memory Sight can reveal.
	var trace := MemoryTrace.new()
	trace.name = "ClockmakerNote"
	trace.trace_id = "TRC_CH1_CLOCKMAKER_NOTE"
	trace.position = Vector3(11, 1.0, -3)
	trace.interactable_path = NodePath("Examine")
	var note := MeshInstance3D.new()
	note.name = "Note"
	var nm := BoxMesh.new()
	nm.size = Vector3(0.5, 0.05, 0.7)
	note.mesh = nm
	note.material_override = _mat(Color(0.9, 0.85, 0.6))
	trace.add_child(note)
	_label(trace, "A folded note", Vector3(0, 0.6, 0), 30)
	var note_use := _use(trace, Interactable.new(), "Examine", "INT_EC_HID_CLOCK_ROOM_NOTE", Vector3.ZERO,
		"PROMPT_EXAMINE", Interactable.Priority.CLUE, Color(0.9, 0.85, 0.6), Vector3(1.6, 1.6, 1.6))
	note_use.give_clue = "CLUE_CLOCKMAKER_NOTE"
	root.add_child(trace)
	# Logic: link the station clock clue with the wall writing.
	var board := ClueBoard.new()
	board.deduction_id = "DED_STUCK_AT_417"
	board.puzzle_id = "PZL_CH1_CLOCK_DEDUCTION"
	_use(root, board, "ClueBoard", "INT_EC_HID_CLOCK_ROOM_BOARD", Vector3(-6, 1, -9), "PROMPT_LINK_CLUES",
		Interactable.Priority.CLUE, Color(0.8, 0.5, 0.3), Vector3(2.5, 2, 2))
	_label(board, "Clue board:\nlink two clues", Vector3(0, 1.0, 0), 30)
	# Sequence: the dial, locked until the deduction is made.
	var lock := ConditionGate.new()
	lock.name = "DialLock"
	lock.conditions = _cond({"flags_all": ["ch1_clock_dial_unlocked"]})
	lock.position = Vector3(0, 1.6, -8.5)
	_label(lock, "Dial locked.\nLink what you know on the board.", Vector3.ZERO, 30)
	root.add_child(lock)
	var digits := ["1", "2", "4", "7", "9"]
	for i in digits.size():
		var key := Interactable.new()
		key.puzzle_id = "PZL_CH1_CLOCK_4_17"
		key.puzzle_symbol = digits[i]
		key.conditions = _cond({"flags_all": ["ch1_clock_dial_unlocked"]})
		_use(root, key, "Dial" + digits[i], "INT_EC_HID_CLOCK_ROOM_DIAL_" + digits[i],
			Vector3(-4 + i * 2, 1, -7), "PROMPT_PRESS", Interactable.Priority.STORY, Color(0.75, 0.75, 0.8), Vector3(1.5, 1.5, 1.5))
		_label(key, "%s\n%s" % [digits[i], "o".repeat(int(digits[i]))], Vector3(0, 0.8, 0), 30)
	var exit := Interactable.new()
	exit.travel_to_location = "LOC_EC_ARCHIVE_TOWER"
	_use(root, exit, "ExitToArchiveTower", "INT_EC_HID_CLOCK_ROOM_EXIT", Vector3(6, 1, 11), "PROMPT_ENTER",
		Interactable.Priority.STORY, Color(0.5, 0.8, 0.5))
	_label(exit, "Back to the Archive Tower", Vector3(0, 1.0, 0), 30)
	return root

# --- Reality Shift: the anchor fields --------------------------------------------------------------
static func _anchor_fields() -> Node:
	var root := PrototypeLocation.new()
	root.name = "AnchorFields"
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-50, 30, 0)
	root.add_child(sun)
	root.door_row_origin = Vector3(-4, 1, 8.2)
	_box(root, "PlatformA", Vector3(14, 1, 6), Vector3(0, -0.5, 6), Color(0.25, 0.25, 0.3))
	_box(root, "PlatformB", Vector3(14, 1, 6), Vector3(0, -0.5, -6), Color(0.3, 0.25, 0.25))
	_box(root, "PlatformC", Vector3(6, 1, 4), Vector3(0, -0.5, -11), Color(0.25, 0.3, 0.25))
	_spawn(root, Vector3(0, 0.5, 6.5))
	for pair in [["SafeA", Vector3(0, 0.5, 6)], ["SafeB", Vector3(0, 0.5, -5)]]:
		var m := Marker3D.new()
		m.name = pair[0]
		m.position = pair[1]
		m.add_to_group("shift_safe_points", true)
		root.add_child(m)
	# The bridge exists only in the Other Side state.
	var bridge := ShiftableObject.new()
	bridge.name = "Bridge"
	bridge.zone_id = ZONE
	bridge.visible_in_states.assign(["other_side"])
	_box(bridge, "Span", Vector3(3, 0.4, 6.4), Vector3(0, -0.2, 0), Color(0.5, 0.75, 0.9))
	root.add_child(bridge)
	_label(root, "The gap. No way across.", Vector3(0, 2.2, 0), 36)
	for spec in [["AnchorA", Vector3(0, 0.5, 4.5), "other_side", "Anchor A\nUse Reality Shift"],
			["AnchorB", Vector3(0, 0.5, -4.5), "echo_city", "Anchor B\nUse Reality Shift"]]:
		var anchor := ShiftAnchor.new()
		anchor.zone_id = ZONE
		anchor.target_state = spec[2]
		_zone_area(anchor, spec[0], spec[1], Vector3(3, 2, 3))
		_label(anchor, spec[3], Vector3(0, 1.8, 0), 30)
		root.add_child(anchor)
	# State-specific clue: the sigil only exists on the Other Side.
	var sigil_holder := ShiftableObject.new()
	sigil_holder.name = "OtherSideSigil"
	sigil_holder.zone_id = ZONE
	sigil_holder.visible_in_states.assign(["other_side"])
	sigil_holder.position = Vector3(4, 0, -6)
	var sigil := Interactable.new()
	sigil.give_clue = SIGIL_CLUE
	sigil.once = true
	_use(sigil_holder, sigil, "Sigil", "INT_DL_ANCHOR_FIELDS_SIGIL", Vector3(0, 1, 0), "PROMPT_EXAMINE",
		Interactable.Priority.CLUE, Color(0.9, 0.5, 0.9))
	_label(sigil, "A sigil that exists\nonly on the Other Side", Vector3(0, 1.0, 0), 28)
	root.add_child(sigil_holder)
	# Puzzle dependency: the gate opens only with the sigil clue AND the Echo City state.
	var gate := ConditionGate.new()
	gate.name = "ExitGate"
	gate.conditions = _cond({"clues_all": [SIGIL_CLUE], "shift_states": {ZONE: "echo_city"}})
	gate.position = Vector3(0, 1.5, -9.2)
	var wall := StaticBody3D.new()
	wall.name = "Wall"
	wall.collision_layer = 1
	var ws := CollisionShape3D.new()
	var wb := BoxShape3D.new()
	wb.size = Vector3(6, 3, 0.6)
	ws.shape = wb
	wall.add_child(ws)
	var wm := MeshInstance3D.new()
	var wbm := BoxMesh.new()
	wbm.size = Vector3(6, 3, 0.6)
	wm.mesh = wbm
	wm.material_override = _mat(Color(0.4, 0.2, 0.2))
	wall.add_child(wm)
	gate.add_child(wall)
	_label(gate, "Sealed.\nNeeds the sigil and Echo City.", Vector3(0, 0.5, 0.6), 28)
	root.add_child(gate)
	var portal := Interactable.new()
	portal.solve_puzzle = "PZL_CH3_ANCHOR_BRIDGE"
	portal.conditions = _cond({"clues_all": [SIGIL_CLUE], "shift_states": {ZONE: "echo_city"}})
	_use(root, portal, "ExitPortal", "INT_DL_ANCHOR_FIELDS_EXIT", Vector3(0, 1, -11), "PROMPT_ENTER",
		Interactable.Priority.STORY, Color(0.5, 0.9, 0.6))
	_label(portal, "Exit", Vector3(0, 1.0, 0), 30)
	# After the puzzle the bridge stays, so the player is never stranded.
	var kept := ConditionGate.new()
	kept.name = "KeptBridge"
	kept.open_when_met = false
	kept.conditions = _cond({"flags_all": ["shift_anchor_bridge_solved"]})
	_box(kept, "Span", Vector3(3, 0.4, 6.4), Vector3(0, -0.2, 0), Color(0.5, 0.75, 0.9))
	root.add_child(kept)
	return root

# --- Time Echo: the echo gallery --------------------------------------------------------------------------
static func _echo_gallery() -> Node:
	var root := PrototypeLocation.new()
	_room(root, "EchoGallery", Vector3(40, 1, 40))
	root.door_row_origin = Vector3(-4, 1, 16)
	_spawn(root, Vector3(0, 0.5, 12))
	# Memory reconstruction: watch the echo, then put the reels in order.
	var site := EchoSite.new()
	site.echo_id = "ECH_CH3_TAPE_LOADING"
	_zone_area(site, "TapeEchoSite", Vector3(-8, 1, 5), Vector3(4, 2, 4))
	_label(site, "Echo Site\nUse Time Echo", Vector3(0, 1.6, 0), 30)
	root.add_child(site)
	_box(root, "Shelf", Vector3(6, 2, 0.6), Vector3(-8, 1, -2.6), Color(0.3, 0.25, 0.2))
	for spec in [["Circle", -10.0], ["Square", -8.0], ["Triangle", -6.0]]:
		var reel := _box(root, spec[0] + "Reel", Vector3(0.6, 0.6, 0.6), Vector3(spec[1], 1.6, -2.0), Color(0.7, 0.7, 0.75), false)
		_label(reel, spec[0] + " reel", Vector3(0, 0.7, 0), 28)
	var board := ReconstructionBoard.new()
	board.name = "ReelBoard"
	board.puzzle_id = "PZL_CH3_TAPE_ORDER"
	board.card_ids.assign(["tape_circle", "tape_square", "tape_triangle"])
	board.slot_count = 3
	board.card_names = {"tape_circle": "Circle reel", "tape_square": "Square reel", "tape_triangle": "Triangle reel"}
	var cards := Node3D.new()
	cards.name = "Cards"
	board.add_child(cards)
	var slots := Node3D.new()
	slots.name = "Slots"
	board.add_child(slots)
	for spec in [["tape_triangle", -11.0, "Triangle reel"], ["tape_circle", -8.0, "Circle reel"], ["tape_square", -5.0, "Square reel"]]:
		var card := Interactable.new()
		_use(cards, card, spec[0], "INT_DL_ECHO_GALLERY_" + spec[0].to_upper(), Vector3(spec[1], 1, -6.5),
			"PROMPT_PICK_UP", Interactable.Priority.PICKUP, Color(0.8, 0.8, 0.85))
		_label(card, spec[2], Vector3(0, 0.8, 0), 28)
	for i in 3:
		var slot := Interactable.new()
		_use(slots, slot, "Slot%d" % (i + 1), "INT_DL_ECHO_GALLERY_SLOT%d" % (i + 1), Vector3(-11 + i * 3, 1, -10),
			"PROMPT_PLACE", Interactable.Priority.PICKUP, Color(0.5, 0.6, 0.8))
		var text := _label(slot, "%d: ..." % (i + 1), Vector3(0, 0.8, 0), 28)
		text.name = "Text"
	root.add_child(board)
	# Cooperative puzzle: two plates, solved alone with a recorded ghost.
	var record := EchoSite.new()
	record.allow_recording = true
	record.hint_key = "HINT_ECHO_RECORD"
	_zone_area(record, "RecordZone", Vector3(8, 1, 8), Vector3(5, 2, 5))
	_label(record, "Record zone\nUse Time Echo to record,\nuse it again to stop", Vector3(0, 1.8, 0), 28)
	root.add_child(record)
	for spec in [["PlateA", 4.0, "Plate A"], ["PlateB", 12.0, "Plate B"]]:
		var plate := PressurePlate.new()
		plate.puzzle_id = "PZL_CH3_ECHO_PLATES"
		plate.name = spec[0]
		plate.position = Vector3(spec[1], 0.2, -4)
		var shape := CollisionShape3D.new()
		shape.name = "Shape"
		var bs := BoxShape3D.new()
		bs.size = Vector3(2, 0.6, 2)
		shape.shape = bs
		plate.add_child(shape)
		var mesh := MeshInstance3D.new()
		mesh.name = "Mesh"
		var bm := BoxMesh.new()
		bm.size = Vector3(2, 0.1, 2)
		mesh.mesh = bm
		mesh.position.y = -0.15
		mesh.material_override = _mat(Color(0.45, 0.45, 0.5))
		plate.add_child(mesh)
		_label(plate, spec[2], Vector3(0, 1.0, 0), 30)
		root.add_child(plate)
	var controller := PlateController.new()
	controller.name = "PlateController"
	controller.puzzle_id = "PZL_CH3_ECHO_PLATES"
	root.add_child(controller)
	var exit := Interactable.new()
	exit.travel_to_location = "LOC_DL_ANCHOR_FIELDS"
	_use(root, exit, "ExitToAnchorFields", "INT_DL_ECHO_GALLERY_EXIT", Vector3(6, 1, 15), "PROMPT_ENTER",
		Interactable.Priority.STORY, Color(0.5, 0.8, 0.5))
	_label(exit, "Back to the Anchor Fields", Vector3(0, 1.0, 0), 30)
	return root
