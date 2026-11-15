extends Node
## Content pipeline. Run from the project folder:
##   godot --headless --path . res://tools/content_tool.tscn -- <command> [args]
## (run as a scene so the autoload systems exist while definitions are compiled)
##
## generate-world                      create/update Location, Fragment and Mission definitions
##                                     from tools/generated/world_data.json (python3 tools/world_data.py)
## bootstrap-samples                   create the sample characters, abilities, items, puzzle, dialogue
##                                     and the hand-authored sample missions (skips authored files)
## new-mission  ID "Title" main|optional LOC_ID
## new-character ID3 "Name"
## new-location LOC_ID "Name"
## new-item     ITEM_ID "Name"
## new-puzzle   PZL_ID "Title" sym1,sym2,sym3
## new-dialogue DLG_ID SPEAKER "First line"
## validate                            check every definition, ID, reference and translation
## Run `godot --headless --path . --import` once first so script classes are known.

const PO_CONTENT := "res://localization/en_content.po"
const WORLD_JSON := "res://tools/generated/world_data.json"

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var code := 1
	if args.is_empty():
		print("Usage: see the header of tools/content_tool.gd")
	else:
		match args[0]:
			"generate-world": code = _generate_world()
			"bootstrap-samples": code = _bootstrap_samples()
			"new-mission": code = _new_mission(args)
			"new-character": code = _new_character(args)
			"new-location": code = _new_location(args)
			"new-item": code = _new_item(args)
			"new-puzzle": code = _new_puzzle(args)
			"new-dialogue": code = _new_dialogue(args)
			"validate": code = _validate()
			_: print("Unknown command: %s" % args[0])
	get_tree().quit(code)

# --- helpers ---------------------------------------------------------------
func _path(folder: String, id: String) -> String:
	return "res://resources/%s/%s.tres" % [folder, id.to_lower()]

func _save(res: Resource, path: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var err := ResourceSaver.save(res, path)
	if err != OK:
		printerr("could not save %s: %s" % [path, error_string(err)])
	return err == OK

func _load_existing(path: String) -> Resource:
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	return null

func _po(key: String, text: String) -> void:
	var content := FileAccess.get_file_as_string(PO_CONTENT) if FileAccess.file_exists(PO_CONTENT) else \
		'msgid ""\nmsgstr ""\n"Language: en\\n"\n"Content-Type: text/plain; charset=UTF-8\\n"\n'
	if content.contains('msgid "%s"' % key):
		return
	var esc := text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
	content += '\nmsgid "%s"\nmsgstr "%s"\n' % [key, esc]
	var f := FileAccess.open(PO_CONTENT, FileAccess.WRITE)
	f.store_string(content)

func _obj(id: String, key: String, kind: ObjectiveDef.Kind, target: String, count: int = 1) -> ObjectiveDef:
	var o := ObjectiveDef.new()
	o.id = id
	o.text_key = key
	o.objective_kind = kind
	o.target = target
	o.count = count
	return o

func _cond(flags: Array = [], missions: Array = []) -> ConditionSet:
	var c := ConditionSet.new()
	c.flags_all.assign(flags)
	c.missions_complete.assign(missions)
	return c

func _mission(id: String, type: MissionDef.Type, locs: Array, objectives: Array, unlock: ConditionSet) -> MissionDef:
	var m := MissionDef.new()
	m.id = id
	m.mission_type = type
	m.chapter = int(id.substr(2, 1))
	m.title_key = "MISSION_%s_TITLE" % id
	m.locations.assign(locs)
	m.objectives.assign(objectives)
	m.unlock = unlock
	return m

# --- generate-world ----------------------------------------------------------
func _generate_world() -> int:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(WORLD_JSON))
	if typeof(data) != TYPE_DICTIONARY:
		printerr("missing or invalid %s (run python3 tools/world_data.py)" % WORLD_JSON)
		return 1
	var made := {"locations": 0, "fragments": 0, "missions": 0}
	for l in data["locations"]:
		var path := _path("locations", l["id"])
		var d: LocationDef = _load_existing(path) as LocationDef
		if d == null:
			d = LocationDef.new()
			d.scene_path = l["scene_path"]
			d.status = LocationDef.BuildStatus.GRAYBOX if ResourceLoader.exists(d.scene_path) else LocationDef.BuildStatus.PLANNED
		d.id = l["id"]
		d.name_key = l["id"]
		d.region_id = l["region"]
		d.location_type = l["type"]
		d.first_chapter = int(l["chapter"])
		d.safe_point = l["safe"]
		d.hidden = l["hidden"]
		var conns: Array[LocationConnection] = []
		for c in l["connections"]:
			var lc := LocationConnection.new()
			lc.to_location = c["to"]
			lc.route_type = c["type"]
			lc.gate_chapter = int(c["gate"])
			lc.note = c["note"]
			conns.append(lc)
		d.connections = conns
		if _save(d, path): made["locations"] += 1
	for f in data["fragments"]:
		var path := _path("fragments", f["id"])
		var d: FragmentDef = _load_existing(path) as FragmentDef
		if d == null:
			d = FragmentDef.new()
		d.id = f["id"]
		d.name_key = "FRAG_%s_NAME" % f["id"]
		d.location_id = f["location"]
		d.fragment_kind = {"Core": FragmentDef.Kind.CORE, "Hidden": FragmentDef.Kind.HIDDEN, "Deep": FragmentDef.Kind.DEEP}[f["kind"]]
		if _save(d, path): made["fragments"] += 1
	var previous_main := {}   # chapter -> last MAIN mission id seen
	for m in data["missions"]:
		var id: String = m["id"]
		var is_main: bool = m["type"] == "Main"
		var path := _path("missions", id)
		var chapter := int(m["chapter"])
		var unlock := ConditionSet.new()
		if is_main:
			if previous_main.has(chapter):
				unlock.missions_complete.assign([previous_main[chapter]])
			elif chapter == 1:
				unlock.flags_all.assign(["ch1_started"])
			previous_main[chapter] = id
		if _load_existing(path) != null:
			continue    # never overwrite: designers may have edited it
		var objectives: Array = []
		for loc in m["locations"]:
			var short: String = loc.trim_prefix("LOC_")
			objectives.append(_obj("reach_" + short.to_lower(), "MISSION_%s_OBJ_REACH_%s" % [id, short],
				ObjectiveDef.Kind.REACH_LOCATION, loc))
		var mission := _mission(id, MissionDef.Type.MAIN if is_main else MissionDef.Type.OPTIONAL,
			m["locations"], objectives, unlock)
		if _save(mission, path): made["missions"] += 1
	print("generate-world: wrote %s" % [made])
	return 0

# --- bootstrap-samples -------------------------------------------------------
func _bootstrap_samples() -> int:
	# Characters (IDs from CHARACTER_BIBLE.md)
	var chars := [["ALX", "Alex Morgan", Color(0.55, 0.8, 1.0)], ["MAY", "Maya Reed", Color(1.0, 0.7, 0.5)],
		["ARV", "The Archivist", Color(0.85, 0.85, 0.7)], ["ARC", "The Architect", Color(0.8, 0.4, 0.4)],
		["FCH", "The Forgotten Child", Color(0.75, 0.7, 1.0)]]
	for c in chars:
		var d := CharacterDef.new()
		d.id = c[0]
		d.name_key = "CHR_%s_NAME" % c[0]
		d.accent_color = c[2]
		_po(d.name_key, c[1])
		_save(d, _path("characters", c[0]))
	# Abilities (GAMEPLAY_SYSTEMS.md)
	var abilities := [
		["ABIL_MEMORY_SIGHT", "Memory Sight", 1, 1, 8.0, 6.0, MemorySightBehavior],
		["ABIL_REALITY_SHIFT", "Reality Shift", 3, 2, 0.0, 0.0, RealityShiftBehavior],
		["ABIL_TIME_ECHO", "Time Echo", 3, 3, 10.0, 0.0, TimeEchoBehavior],
		["ABIL_ECHO_VOICE", "Echo Voice", 5, 4, 0.0, 0.0, EchoVoiceBehavior]]
	for a in abilities:
		var d := AbilityDef.new()
		d.id = a[0]
		d.name_key = a[0] + "_NAME"
		d.description_key = a[0] + "_DESC"
		d.unlock_chapter = a[2]
		d.input_slot = a[3]
		d.duration = a[4]
		d.cooldown = a[5]
		d.behavior = a[6]
		_po(d.name_key, a[1])
		_po(d.description_key, "See docs/GAMEPLAY_SYSTEMS.md")
		_save(d, _path("abilities", a[0]))
	# Items
	var card := ItemDef.new()
	card.id = "ITEM_ARCHIVE_CARD"
	card.name_key = "ITEM_ARCHIVE_CARD_NAME"
	card.description_key = "ITEM_ARCHIVE_CARD_DESC"
	_po(card.name_key, "Archive Card")
	_po(card.description_key, "A blank index card. It opens the way to the Forgotten Quarter.")
	_save(card, _path("items", card.id))
	var tag := ItemDef.new()
	tag.id = "ITEM_LUGGAGE_TAG"
	tag.name_key = "ITEM_LUGGAGE_TAG_NAME"
	tag.description_key = "ITEM_LUGGAGE_TAG_DESC"
	tag.stackable = true
	tag.max_stack = 3
	_po(tag.name_key, "Luggage Tag")
	_po(tag.description_key, "A tag from lost luggage. Someone wrote a name, then scratched it out.")
	_save(tag, _path("items", tag.id))
	# Puzzle: the 4:17 clock (CH1_S02, LOC_EC_HID_CLOCK_ROOM)
	var pz := PuzzleDef.new()
	pz.id = "PZL_CH1_CLOCK_4_17"
	pz.puzzle_type = PuzzleDef.Type.PATTERN
	pz.title_key = "PZL_CH1_CLOCK_4_17_TITLE"
	pz.location_id = "LOC_EC_HID_CLOCK_ROOM"
	pz.hint_keys.assign(["PZL_CH1_CLOCK_4_17_HINT_1", "PZL_CH1_CLOCK_4_17_HINT_2", "PZL_CH1_CLOCK_4_17_HINT_3"])
	pz.solution.assign(["4", "1", "7"])
	pz.set_flags.assign(["ch1_clock_solved"])
	pz.reward_fragments.assign(["CH1_F05"])
	_po(pz.title_key, "The Stopped Clock")
	_po(pz.hint_keys[0], "Every clock in this city agrees on one moment.")
	_po(pz.hint_keys[1], "The moment is written on the receipts and on the station clock.")
	_po(pz.hint_keys[2], "Press 4, then 1, then 7.")
	_save(pz, _path("puzzles", pz.id))
	# Dialogue: Catalogue Desk (DIALOGUE_SCRIPT.md, Chapter 1)
	var lines := [
		["arv_001", "ARV", "Item: one visitor. Condition: awake. This is... unusual."],
		["alx_001", "ALX", "Where am I? Who are you?"],
		["arv_002", "ARV", "Echo City. And I am merely the one who keeps the records."],
		["alx_002", "ALX", "Then you have mine."],
		["arv_003", "ARV", "Item: your name. Condition: misplaced. I am sorry."],
		["alx_003", "ALX", "That's not an answer."],
		["arv_004", "ARV", "It is the only one I am permitted to give. We... I am permitted to give."],
		["alx_004", "ALX", "\"We\"?"],
		["arv_005", "ARV", "A slip. Please record it as a slip."],
		["arv_006", "ARV", "Take this card. Find what was removed."]]
	var dlg := DialogueDef.new()
	dlg.id = "DLG_CH1_M03_CATALOGUE"
	dlg.start_id = "arv_001"
	dlg.repeatable = false
	for i in lines.size():
		var n := DialogueNode.new()
		n.id = lines[i][0]
		n.speaker_id = lines[i][1]
		n.text_key = "%s_%s" % [dlg.id, n.id.to_upper()]
		n.next_id = lines[i + 1][0] if i + 1 < lines.size() else ""
		if i == lines.size() - 1:
			n.set_flags.assign(["ch1_archive_card_received"])
		_po(n.text_key, lines[i][2])
		dlg.nodes.append(n)
	_save(dlg, _path("dialogue", dlg.id))
	# Dialogue: Maya's cafe with choices (Chapter 2)
	var cafe := DialogueDef.new()
	cafe.id = "DLG_CH2_M02_CAFE"
	cafe.start_id = "may_001"
	cafe.repeatable = false
	var cafe_lines := [
		["may_001", "MAY", "Alex? Alex, look at me. It's me.", "alx_001"],
		["alx_001", "ALX", "I don't... remember you.", "may_002"],
		["may_002", "MAY", "That's okay. Vitals first. You're breathing, you're upright. We'll do the rest.", "may_003"],
		["may_003", "MAY", "I'm not from here, Alex. This city is making me fuzzy at the edges.", "alx_choice"],
		["alx_choice", "ALX", "(Ask Maya)", ""],
		["may_004", "MAY", "Because I'm the one who never left. Don't go through that door alone.", ""]]
	for c in cafe_lines:
		var n := DialogueNode.new()
		n.id = c[0]
		n.speaker_id = c[1]
		n.text_key = "%s_%s" % [cafe.id, n.id.to_upper()]
		n.next_id = c[3]
		_po(n.text_key, c[2])
		cafe.nodes.append(n)
	var choice_node: DialogueNode = cafe.find_node("alx_choice")
	var why := DialogueChoice.new()
	why.text_key = "DLG_CH2_M02_CAFE_CHOICE_WHY"
	why.next_id = "may_004"
	why.relationship_changes = {"maya_trust": 1}
	_po(why.text_key, "Then why are you here?")
	var real := DialogueChoice.new()
	real.text_key = "DLG_CH2_M02_CAFE_CHOICE_REAL"
	real.next_id = "may_004"
	real.log_choice = "asked_maya_if_real"
	_po(real.text_key, "How do I know you're real?")
	choice_node.choices.assign([why, real])
	_po(choice_node.text_key, "...")
	_save(cafe, _path("dialogue", cafe.id))
	# Hand-authored sample missions (templates for designers). Existing authored files are kept.
	var made: Array = []
	var m01 := _mission("CH1_M01", MissionDef.Type.MAIN,
		["LOC_UM_ECHO_STATION", "LOC_UM_CONCOURSE", "LOC_EC_METRO_ENTRANCE"],
		[_obj("reach_um_concourse", "MISSION_CH1_M01_OBJ_REACH_UM_CONCOURSE", ObjectiveDef.Kind.REACH_LOCATION, "LOC_UM_CONCOURSE"),
		 _obj("reach_ec_metro_entrance", "MISSION_CH1_M01_OBJ_REACH_EC_METRO_ENTRANCE", ObjectiveDef.Kind.REACH_LOCATION, "LOC_EC_METRO_ENTRANCE")],
		_cond(["ch1_started"]))
	m01.complete_flags.assign(["ch1_exit_reached"])
	m01.reward_fragments.assign(["CH1_F01"])
	m01.respawn_location = "LOC_UM_ECHO_STATION"
	made.append(m01)
	var m03 := _mission("CH1_M03", MissionDef.Type.MAIN, ["LOC_EC_ARCHIVE_TOWER"],
		[_obj("reach_ec_archive_tower", "MISSION_CH1_M03_OBJ_REACH_EC_ARCHIVE_TOWER", ObjectiveDef.Kind.REACH_LOCATION, "LOC_EC_ARCHIVE_TOWER"),
		 _obj("talk_to_archivist", "MISSION_CH1_M03_OBJ_TALK", ObjectiveDef.Kind.DIALOGUE, "DLG_CH1_M03_CATALOGUE")],
		_cond([], ["CH1_M02"]))
	m03.reward_items.assign(["ITEM_ARCHIVE_CARD"])
	m03.complete_flags.assign(["ch1_archive_card_given"])
	_po("MISSION_CH1_M03_OBJ_TALK", "Speak with the Archivist")
	made.append(m03)
	var s01 := _mission("CH1_S01", MissionDef.Type.OPTIONAL, ["LOC_UM_CONCOURSE", "LOC_EC_CONV_STORE"],
		[_obj("find_luggage_tags", "MISSION_CH1_S01_OBJ_TAGS", ObjectiveDef.Kind.ITEM, "ITEM_LUGGAGE_TAG", 3)],
		_cond(["ch1_started"]))
	_po("MISSION_CH1_S01_OBJ_TAGS", "Find the lost luggage tags")
	made.append(s01)
	var s02 := _mission("CH1_S02", MissionDef.Type.OPTIONAL, ["LOC_EC_HID_CLOCK_ROOM"],
		[_obj("stop_the_clock", "MISSION_CH1_S02_OBJ_CLOCK", ObjectiveDef.Kind.PUZZLE, "PZL_CH1_CLOCK_4_17")],
		_cond(["ch1_started"]))
	_po("MISSION_CH1_S02_OBJ_CLOCK", "Solve the stopped clock")
	made.append(s02)
	var c2 := _mission("CH2_M02", MissionDef.Type.MAIN, ["LOC_EC_MAYA_CAFE"],
		[_obj("reach_ec_maya_cafe", "MISSION_CH2_M02_OBJ_REACH_EC_MAYA_CAFE", ObjectiveDef.Kind.REACH_LOCATION, "LOC_EC_MAYA_CAFE"),
		 _obj("talk_to_maya", "MISSION_CH2_M02_OBJ_TALK", ObjectiveDef.Kind.DIALOGUE, "DLG_CH2_M02_CAFE")],
		_cond([], ["CH2_M01"]))
	c2.reward_fragments.assign(["CH2_F01"])
	_po("MISSION_CH2_M02_OBJ_TALK", "Talk to Maya")
	made.append(c2)
	for m in made:
		m.authored = true
		var path := _path("missions", m.id)
		var existing := _load_existing(path) as MissionDef
		if existing != null and existing.authored:
			continue
		_save(m, path)
	print("bootstrap-samples: done")
	return 0

# --- scaffolding for new content -------------------------------------------
func _new_mission(args: PackedStringArray) -> int:
	if args.size() < 5:
		print('usage: new-mission ID "Title" main|optional LOC_ID')
		return 1
	var id := args[1]
	var m := _mission(id, MissionDef.Type.MAIN if args[3] == "main" else MissionDef.Type.OPTIONAL,
		[args[4]], [_obj("reach_" + args[4].trim_prefix("LOC_").to_lower(),
			"MISSION_%s_OBJ_REACH" % id, ObjectiveDef.Kind.REACH_LOCATION, args[4])], ConditionSet.new())
	m.authored = true
	_po(m.title_key, args[2])
	_po("MISSION_%s_OBJ_REACH" % id, "Reach: " + args[4])
	return 0 if _save(m, _path("missions", id)) else 1

func _new_character(args: PackedStringArray) -> int:
	if args.size() < 3:
		print('usage: new-character ID3 "Name"')
		return 1
	var d := CharacterDef.new()
	d.id = args[1]
	d.name_key = "CHR_%s_NAME" % args[1]
	_po(d.name_key, args[2])
	return 0 if _save(d, _path("characters", args[1])) else 1

func _new_location(args: PackedStringArray) -> int:
	if args.size() < 3:
		print('usage: new-location LOC_XX_NAME "Display name"')
		return 1
	var d := LocationDef.new()
	d.id = args[1]
	d.name_key = args[1]
	d.region_id = args[1].get_slice("_", 1)
	_po(d.name_key, args[2])
	return 0 if _save(d, _path("locations", args[1])) else 1

func _new_item(args: PackedStringArray) -> int:
	if args.size() < 3:
		print('usage: new-item ITEM_ID "Name"')
		return 1
	var d := ItemDef.new()
	d.id = args[1]
	d.name_key = args[1] + "_NAME"
	d.description_key = args[1] + "_DESC"
	_po(d.name_key, args[2])
	_po(d.description_key, "TODO description")
	return 0 if _save(d, _path("items", args[1])) else 1

func _new_puzzle(args: PackedStringArray) -> int:
	if args.size() < 4:
		print('usage: new-puzzle PZL_ID "Title" sym1,sym2,sym3')
		return 1
	var d := PuzzleDef.new()
	d.id = args[1]
	d.title_key = args[1] + "_TITLE"
	d.solution.assign(args[3].split(","))
	d.hint_keys.assign([args[1] + "_HINT_1", args[1] + "_HINT_2", args[1] + "_HINT_3"])
	_po(d.title_key, args[2])
	for i in 3:
		_po(d.hint_keys[i], "TODO hint tier %d" % (i + 1))
	return 0 if _save(d, _path("puzzles", args[1])) else 1

func _new_dialogue(args: PackedStringArray) -> int:
	if args.size() < 4:
		print('usage: new-dialogue DLG_ID SPEAKER "First line"')
		return 1
	var d := DialogueDef.new()
	d.id = args[1]
	d.start_id = "line_001"
	var n := DialogueNode.new()
	n.id = "line_001"
	n.speaker_id = args[2]
	n.text_key = args[1] + "_LINE_001"
	_po(n.text_key, args[3])
	d.nodes.append(n)
	return 0 if _save(d, _path("dialogue", args[1])) else 1

# --- validate ------------------------------------------------------------------
func _validate() -> int:
	DataRegistry.reload()
	var errors: Array = DataRegistry.validate_all()
	for e in errors:
		printerr("ERROR: " + e)
	print("validate: %d problem(s)" % errors.size())
	return 1 if not errors.is_empty() else 0
