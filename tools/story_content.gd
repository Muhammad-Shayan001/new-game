class_name StoryContent
extends RefCounted
## Authored content for Prompts 08 and 09: story-state registry, character info, the Reality
## Shift zone, the Time Echo, the five prototype puzzles, abilities and the missions that
## use them. Run through tools/content_tool.gd (bootstrap-story). Safe to run again: it
## rewrites exactly these files.

const PO := "res://localization/en_content.po"

static func _path(folder: String, id: String) -> String:
	return "res://resources/%s/%s.tres" % [folder, id.to_lower()]

static func _save(res: Resource, folder: String, id: String) -> void:
	var path := _path(folder, id)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var err := ResourceSaver.save(res, path)
	if err != OK:
		printerr("could not save %s: %s" % [path, error_string(err)])

static func _po(key: String, text: String) -> void:
	var content := FileAccess.get_file_as_string(PO)
	if content.contains('msgid "%s"' % key):
		return
	var esc := text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
	content += '\nmsgid "%s"\nmsgstr "%s"\n' % [key, esc]
	var f := FileAccess.open(PO, FileAccess.WRITE)
	f.store_string(content)

static func _cond(values: Dictionary) -> ConditionSet:
	var c := ConditionSet.new()
	for k in values:
		var current: Variant = c.get(k)
		if current is Array:
			current.assign(values[k])
		else:
			c.set(k, values[k])
	return c

static func _obj(id: String, kind: ObjectiveDef.Kind, target: String, text_key: String, text: String = "",
		count: int = 1, optional: bool = false, value: String = "") -> ObjectiveDef:
	var o := ObjectiveDef.new()
	o.id = id
	o.objective_kind = kind
	o.target = target
	o.text_key = text_key
	o.count = count
	o.optional = optional
	o.value = value
	if text != "":
		_po(text_key, text)
	return o

static func _reach(mission: String, loc: String) -> ObjectiveDef:
	var short := loc.trim_prefix("LOC_")
	return _obj("reach_" + short.to_lower(), ObjectiveDef.Kind.REACH_LOCATION, loc,
		"MISSION_%s_OBJ_REACH_%s" % [mission, short])

static func _mission(id: String, type: MissionDef.Type, locs: Array, objectives: Array, unlock: ConditionSet) -> MissionDef:
	var m := MissionDef.new()
	m.id = id
	m.mission_type = type
	m.chapter = int(id.substr(2, 1))
	m.title_key = "MISSION_%s_TITLE" % id
	m.locations.assign(locs)
	m.objectives.assign(objectives)
	m.unlock = unlock
	m.authored = true
	return m

static func build_all() -> void:
	_story_states()
	_info()
	_audio()
	_abilities()
	_shift_zone()
	_deduction()
	_echo()
	_puzzles()
	_patch_dialogue()
	_missions()
	print("bootstrap-story: done")

# --- story-state registry (docs/STORY_STATE_REGISTRY.md) -----------------------
static func _state(id: String, desc: String, chapter: int, ending: bool = false,
		is_int: bool = false, lo: int = 0, hi: int = 1, rel: String = "", aliases: Array = []) -> void:
	var s := StoryStateDef.new()
	s.id = id
	s.description = desc
	s.chapter = chapter
	s.ending_relevant = ending
	s.value_type = StoryStateDef.ValueType.INT if is_int else StoryStateDef.ValueType.BOOL
	s.min_value = lo
	s.max_value = hi
	s.relationship_key = rel
	s.aliases.assign(aliases)
	_save(s, "story_states", id)

static func _story_states() -> void:
	_state("ch1_started", "Set by GameRoot when a new game starts. Unlocks CH1_M01.", 1)
	_state("ch1_exit_reached", "Set by CH1_M01 when Alex reaches the Metro Entrance.", 1)
	_state("alex_found_first_memory", "Set by CH1_M01. Fragment CH1_F01 (A Name on a Ticket) was recovered.", 1)
	_state("archivist_met", "Set by DLG_CH1_M03_CATALOGUE when the Archivist first speaks.", 1)
	_state("archive_card_received", "Set at the end of DLG_CH1_M03_CATALOGUE. The Archive Card opens the Forgotten Quarter.", 1)
	_state("forgotten_quarter_unlocked", "Set by CH1_M03 completion. The alley to the Forgotten Quarter opens.", 1)
	_state("ch1_clock_dial_unlocked", "Set by puzzle PZL_CH1_CLOCK_DEDUCTION. The clock-room dial becomes usable.", 1)
	_state("ch1_clock_solved", "Set by puzzle PZL_CH1_CLOCK_4_17.", 1)
	_state("maya_met", "Set by DLG_CH2_M02_CAFE. Alex has talked to Maya.", 2)
	_state("metro_unlocked", "Set by CH2_M03 completion. The Static Tunnel to the Underground Metro opens.", 2)
	_state("other_side_reached", "Set by CH3_M01 completion. Alex has crossed to the Other Side.", 3)
	_state("shift_anchor_bridge_solved", "Set by puzzle PZL_CH3_ANCHOR_BRIDGE.", 3)
	_state("tape_order_solved", "Set by puzzle PZL_CH3_TAPE_ORDER.", 3)
	_state("echo_plates_solved", "Set by puzzle PZL_CH3_ECHO_PLATES.", 3)
	_state("time_echo_upgraded", "Set in Chapter 5. Time Echo can hold two ghost copies.", 5)
	_state("architect_revelation_seen", "Set by the Chapter 5 mission where the Architect shows Wren alive inside the Index.", 5)
	_state("spared_forgotten", "Decision: Alex spared the Forgotten Child. Ending variable.", 4, true)
	_state("told_maya_truth", "Decision: Alex told Maya the truth. Ending variable.", 5, true)
	_state("trusted_archivist", "Decision: Alex trusted the Archivist.", 5, true)
	_state("kept_wren_memory", "Decision: Alex kept the Wren memory. Ending variable.", 6, true)
	_state("lullaby_puzzle_solved", "Set by the Core lullaby puzzle. Required for the secret ending.", 6, true)
	_state("maya_trust", "Maya's trust in Alex, -3 to +3. Changed by dialogue choices.", 2, true, true, -3, 3, "maya_trust", ["maya_trust_level"])
	_state("archivist_trust", "The Archivist's trust in Alex, -3 to +3.", 1, true, true, -3, 3, "archivist_trust")
	_state("forgotten_mercy", "How merciful Alex was to the Forgotten, -3 to +3.", 4, true, true, -3, 3, "forgotten_mercy")
	_state("destroyed_index_node", "Number of Index nodes Alex destroyed, 0 to 3. Ending variable.", 5, true, true, 0, 3)
	_state("deep_fragments", "Count of Deep Memory Fragments recovered, 0 to 3. Kept by MemoryManager.", 2, true, true, 0, 3)
	_state("fragments_total", "Count of all Memory Fragments recovered, 0 to 30. Kept by ProgressionManager.", 1, false, true, 0, 30)

# --- character information --------------------------------------------------
static func _info_def(id: String, chr: String, text: String, chapter: int) -> void:
	var d := InfoDef.new()
	d.id = id
	d.character_id = chr
	d.text_key = id + "_TEXT"
	d.chapter = chapter
	_po(d.text_key, text)
	_save(d, "info", id)

static func _info() -> void:
	_info_def("INFO_ARV_KEEPS_RECORDS", "ARV", "The Archivist keeps the records of Echo City. He says he is only permitted to give some answers.", 1)
	_info_def("INFO_ARV_SLIP_WE", "ARV", "The Archivist said \"we\", then asked for it to be recorded as a slip.", 1)
	_info_def("INFO_MAY_NOT_FROM_HERE", "MAY", "Maya says she is not from Echo City. The city makes her fuzzy at the edges.", 2)
	_info_def("INFO_ARC_TAPE_LOADER", "ARC", "A figure loaded three reels into the machine in a fixed order. Someone built this gallery on purpose.", 3)

# --- audio cues (placeholders without a stream; they log once and are skipped) ------
static func _cue(id: String, cat: AudioCueDef.Category) -> void:
	var c := AudioCueDef.new()
	c.id = id
	c.category = cat
	_save(c, "audio", id)

static func _audio() -> void:
	_cue("AUD_ECHO_PING", AudioCueDef.Category.SFX)
	_cue("AUD_ECHO_REEL_CLICK", AudioCueDef.Category.SFX)
	_cue("AUD_ABILITY_ACTIVATE", AudioCueDef.Category.SFX)

# --- abilities ---------------------------------------------------------------------
static func _abilities() -> void:
	var rows := [
		["ABIL_MEMORY_SIGHT", 8.0, 6.0, "HINT_ABILITY_MEMORY_SIGHT", "Reveals hidden memories, writing and clues for a few seconds."],
		["ABIL_REALITY_SHIFT", 0.0, 1.0, "HINT_ABILITY_REALITY_SHIFT", "Stand on a Shift Anchor to swap that area between two states."],
		["ABIL_TIME_ECHO", 0.0, 0.5, "HINT_ABILITY_TIME_ECHO", "At an Echo Site watch a past event. In a record zone record a ghost copy of yourself."],
		["ABIL_ECHO_VOICE", 0.0, 0.0, "HINT_ABILITY_ECHO_VOICE", "Not available yet."]]
	for r in rows:
		var d := DataRegistry.get_ability(r[0])
		if d == null:
			d = load(_path("abilities", r[0])) as AbilityDef
		d.duration = r[1]
		d.cooldown = r[2]
		d.hint_key = r[3]
		d.activation_cue = "AUD_ABILITY_ACTIVATE"
		_po(r[3], r[4])
		_save(d, "abilities", r[0])

# --- Reality Shift zone -------------------------------------------------------------
static func _shift_zone() -> void:
	var z := ShiftZoneDef.new()
	z.id = "SHF_CH3_ANCHOR_BRIDGE"
	z.title_key = "SHF_CH3_ANCHOR_BRIDGE_TITLE"
	z.location_id = "LOC_DL_ANCHOR_FIELDS"
	z.states.assign(["echo_city", "other_side"])
	z.default_state = "echo_city"
	_po(z.title_key, "The Anchor Fields gap")
	_save(z, "shift_zones", z.id)

static func _deduction() -> void:
	var d := DeductionDef.new()
	d.id = "DED_STUCK_AT_417"
	d.clue_a = "CLUE_STATION_CLOCK"
	d.clue_b = "CLUE_CLOCK_WALL_WRITING"
	d.title_key = "DED_STUCK_AT_417_TITLE"
	d.set_flags.assign(["ch1_clock_dial_unlocked"])
	_po(d.title_key, "The clocks stopped at the same moment")
	_save(d, "deductions", d.id)

# --- Time Echo (replay of the tape-loading event) ----------------------------------------
static func _key(t: float, pos: Vector3, yaw: float, state: String) -> EchoKey:
	var k := EchoKey.new()
	k.time = t
	k.position = pos
	k.yaw_degrees = yaw
	k.state = state
	return k

static func _cam(t: float, pos: Vector3, look: Vector3) -> EchoCameraKey:
	var c := EchoCameraKey.new()
	c.time = t
	c.position = pos
	c.look_at = look
	return c

static func _caption(t: float, key: String, text: String) -> EchoCaption:
	var c := EchoCaption.new()
	c.time = t
	c.duration = 1.8
	c.speaker_id = "ARC"
	c.text_key = key
	_po(key, text)
	return c

static func _echo() -> void:
	var e := TimeEchoDef.new()
	e.id = "ECH_CH3_TAPE_LOADING"
	e.title_key = "ECH_CH3_TAPE_LOADING_TITLE"
	e.location_id = "LOC_DL_ECHO_GALLERY"
	e.duration = 9.0
	_po(e.title_key, "The Reel Loader")
	var track := EchoTrack.new()
	track.actor_id = "ARC"
	track.label_key = "CHR_ARC_NAME"
	track.keys.assign([
		_key(0.0, Vector3(-8, 0, 3), 0.0, "enters"),
		_key(2.0, Vector3(-10, 0, -1), 0.0, "loads circle"),
		_key(4.0, Vector3(-8, 0, -1), 0.0, "loads square"),
		_key(6.0, Vector3(-6, 0, -1), 0.0, "loads triangle"),
		_key(8.0, Vector3(-8, 0, 3), 180.0, "leaves"),
		_key(9.0, Vector3(-8, 0, 4), 180.0, "gone")])
	e.tracks.assign([track])
	e.camera_keys.assign([_cam(0.0, Vector3(-8, 3, 7), Vector3(-8, 1, -1)),
		_cam(4.0, Vector3(-8, 2.5, 4), Vector3(-8, 1.2, -1)), _cam(8.0, Vector3(-8, 3, 7), Vector3(-8, 1, 0))])
	for t in [2.0, 4.0, 6.0]:
		var ev := EchoAudioEvent.new()
		ev.time = t
		ev.cue_id = "AUD_ECHO_REEL_CLICK"
		e.audio_events.append(ev)
	e.captions.assign([
		_caption(1.8, "ECH_CH3_TAPE_LOADING_CAP_1", "The figure loads the CIRCLE reel. (click)"),
		_caption(3.8, "ECH_CH3_TAPE_LOADING_CAP_2", "Then the SQUARE reel. (click)"),
		_caption(5.8, "ECH_CH3_TAPE_LOADING_CAP_3", "Last, the TRIANGLE reel. (click)"),
		_caption(7.8, "ECH_CH3_TAPE_LOADING_CAP_4", "The figure leaves. The machine hums.")])
	var moment := EchoClueMoment.new()
	moment.time = 8.5
	moment.clue_id = "CLUE_TAPE_ORDER"
	moment.info_id = "INFO_ARC_TAPE_LOADER"
	e.clue_moments.assign([moment])
	_save(e, "echoes", e.id)

# --- puzzles (docs/PUZZLE_DESIGN_LIBRARY.md) ------------------------------------------------------
static func _puzzle(id: String, type: PuzzleDef.Type, loc: String, title: String, hints: Array, abilities: Array,
		access: String, notes: String) -> PuzzleDef:
	var p := PuzzleDef.new()
	p.id = id
	p.puzzle_type = type
	p.location_id = loc
	p.title_key = id + "_TITLE"
	_po(p.title_key, title)
	var keys: Array[String] = []
	for i in 3:
		keys.append("%s_HINT_%d" % [id, i + 1])
		_po(keys[i], hints[i])
	p.hint_keys = keys
	p.required_abilities.assign(abilities)
	p.accessibility_notes = access
	p.design_notes = notes
	return p

static func _puzzles() -> void:
	var logic := _puzzle("PZL_CH1_CLOCK_DEDUCTION", PuzzleDef.Type.LOGIC, "LOC_EC_HID_CLOCK_ROOM", "What the Clocks Agree On",
		["Two things you found say the same thing. One is on a wall you can only read with Memory Sight.",
		"Examine the station clock in Echo Station, then find the hidden writing in the clock room.",
		"Use the clue board in the clock room. It links the station clock and the wall writing."],
		["ABIL_MEMORY_SIGHT"],
		"No timer. Both clues are written text kept in the Journal. The board says which clue is missing. Hint tier 3 names the answer.",
		"Logic discovery: combine two clues from different places. Solved by making the deduction.")
	logic.completion = PuzzleDef.Completion.DEDUCTION
	logic.reset_policy = PuzzleDef.ResetPolicy.MANUAL
	logic.set_flags.assign(["ch1_clock_dial_unlocked"])
	logic.initial_state = {"board": "locked", "clues_needed": 2}
	_save(logic, "puzzles", logic.id)
	var dial := _puzzle("PZL_CH1_CLOCK_4_17", PuzzleDef.Type.PATTERN, "LOC_EC_HID_CLOCK_ROOM", "The Stopped Clock",
		["Every clock in this city agrees on one moment.", "The moment is written on the wall and on the station clock.", "Press 4, then 1, then 7."],
		["ABIL_MEMORY_SIGHT"],
		"Dial keys show their digit as text and as a number of notches. No timing. Progress is saved, so leaving does not lose it.",
		"Sequence: enter three symbols in order. The digits come from the observation puzzle (Memory Sight reveals the wall writing).")
	dial.solution.assign(["4", "1", "7"])
	dial.set_flags.assign(["ch1_clock_solved"])
	dial.reward_fragments.assign(["CH1_F05"])
	dial.save_policy = PuzzleDef.SavePolicy.PROGRESS
	dial.initial_state = {"entered": [], "dial_unlocked_by": "PZL_CH1_CLOCK_DEDUCTION"}
	_save(dial, "puzzles", dial.id)
	var bridge := _puzzle("PZL_CH3_ANCHOR_BRIDGE", PuzzleDef.Type.REALITY_SWAP, "LOC_DL_ANCHOR_FIELDS", "The Missing Bridge",
		["There is no way across in this state. Try the anchor where you start.",
		"On the Other Side a bridge exists, and a sigil only that side can show.",
		"Shift at the first anchor, cross, read the sigil, shift back at the second anchor, then open the exit."],
		["ABIL_REALITY_SHIFT"],
		"No timer, no falling hazard on the bridge (shifting only works at anchors). The sigil is text. The state is shown in the HUD. Safe transitions move the player out of solid objects.",
		"Environmental manipulation with dependencies: shift (bridge) -> clue (only in the other state) -> shift back (gate needs echo_city) -> exit.")
	bridge.completion = PuzzleDef.Completion.SCENE_EVENT
	bridge.set_flags.assign(["shift_anchor_bridge_solved"])
	bridge.initial_state = {"zone": "SHF_CH3_ANCHOR_BRIDGE", "state": "echo_city", "bridge": "absent"}
	bridge.reset_policy = PuzzleDef.ResetPolicy.MANUAL
	_save(bridge, "puzzles", bridge.id)
	var tapes := _puzzle("PZL_CH3_TAPE_ORDER", PuzzleDef.Type.MEMORY_RECON, "LOC_DL_ECHO_GALLERY", "The Reel Order",
		["Watch the echo again. The order matters.", "Three reels: circle, square, triangle. Watch which goes in first.",
		"Place CIRCLE in slot 1, SQUARE in slot 2, TRIANGLE in slot 3."],
		["ABIL_TIME_ECHO"],
		"The echo has captions for every sound and can be replayed or skipped. Cards and slots have text names and numbers, no colour needed. No timer.",
		"Memory reconstruction: arrange cards to match what the Time Echo showed. Wrong arrangement clears the slots.")
	tapes.solution.assign(["tape_circle", "tape_square", "tape_triangle"])
	tapes.set_flags.assign(["tape_order_solved"])
	tapes.reward_fragments.assign(["CH3_F04"])
	_save(tapes, "puzzles", tapes.id)
	var plates := _puzzle("PZL_CH3_ECHO_PLATES", PuzzleDef.Type.TIME_ECHO, "LOC_DL_ECHO_GALLERY", "Two Plates, One Person",
		["Both plates must be pressed at the same time.", "You cannot stand on both. Record yourself with Time Echo.",
		"Record yourself walking onto plate A, stop, then stand on plate B while your echo holds plate A."],
		["ABIL_TIME_ECHO"],
		"Recording is 10 seconds and forgiving: no precision needed. The HUD shows a recording indicator. Plates need a 1 second hold, not fast reactions.",
		"Cooperative puzzle for future co-op: two players each hold a plate. In solo play a Time Echo ghost replaces the second player.")
	plates.completion = PuzzleDef.Completion.SCENE_EVENT
	plates.cooperative = true
	plates.min_players = 2
	plates.reset_policy = PuzzleDef.ResetPolicy.ON_LEAVE
	plates.set_flags.assign(["echo_plates_solved"])
	_save(plates, "puzzles", plates.id)

# --- dialogue links into the story states ---------------------------------------------
static func _patch_dialogue() -> void:
	var cat := load(_path("dialogue", "DLG_CH1_M03_CATALOGUE")) as DialogueDef
	cat.find_node("arv_001").set_flags.assign(["archivist_met"])
	cat.find_node("arv_001").reveals_info.assign(["INFO_ARV_KEEPS_RECORDS"])
	cat.find_node("arv_005").reveals_info.assign(["INFO_ARV_SLIP_WE"])
	cat.find_node("arv_006").set_flags.assign(["archive_card_received"])
	_save(cat, "dialogue", cat.id)
	var cafe := load(_path("dialogue", "DLG_CH2_M02_CAFE")) as DialogueDef
	cafe.find_node("may_001").set_flags.assign(["maya_met"])
	cafe.find_node("may_003").reveals_info.assign(["INFO_MAY_NOT_FROM_HERE"])
	_save(cafe, "dialogue", cafe.id)

# --- missions -------------------------------------------------------------------------------------
static func _missions() -> void:
	var m01 := _mission("CH1_M01", MissionDef.Type.MAIN, ["LOC_UM_ECHO_STATION", "LOC_UM_CONCOURSE", "LOC_EC_METRO_ENTRANCE"],
		[_reach("CH1_M01", "LOC_UM_CONCOURSE"), _reach("CH1_M01", "LOC_EC_METRO_ENTRANCE")], _cond({"flags_all": ["ch1_started"]}))
	m01.complete_flags.assign(["ch1_exit_reached", "alex_found_first_memory"])
	m01.reward_fragments.assign(["CH1_F01"])
	m01.respawn_location = "LOC_UM_ECHO_STATION"
	_save(m01, "missions", m01.id)
	var m02 := _mission("CH1_M02", MissionDef.Type.MAIN,
		["LOC_EC_MAIN_STREET", "LOC_EC_APT_BLDG", "LOC_EC_SAFE_ROOM", "LOC_EC_ALEX_APT"],
		[_reach("CH1_M02", "LOC_EC_MAIN_STREET"), _reach("CH1_M02", "LOC_EC_APT_BLDG"),
		_reach("CH1_M02", "LOC_EC_SAFE_ROOM"), _reach("CH1_M02", "LOC_EC_ALEX_APT")], _cond({"missions_complete": ["CH1_M01"]}))
	m02.reward_abilities.assign(["ABIL_MEMORY_SIGHT"])
	m02.respawn_location = "LOC_EC_SAFE_ROOM"
	_save(m02, "missions", m02.id)
	var m03 := _mission("CH1_M03", MissionDef.Type.MAIN, ["LOC_EC_ARCHIVE_TOWER"],
		[_reach("CH1_M03", "LOC_EC_ARCHIVE_TOWER"),
		_obj("talk_to_archivist", ObjectiveDef.Kind.DIALOGUE, "DLG_CH1_M03_CATALOGUE", "MISSION_CH1_M03_OBJ_TALK", "Speak with the Archivist")],
		_cond({"missions_complete": ["CH1_M02"]}))
	m03.reward_items.assign(["ITEM_ARCHIVE_CARD"])
	m03.complete_flags.assign(["forgotten_quarter_unlocked"])
	_save(m03, "missions", m03.id)
	var s01 := _mission("CH1_S01", MissionDef.Type.OPTIONAL, ["LOC_UM_CONCOURSE", "LOC_EC_CONV_STORE"],
		[_obj("find_luggage_tags", ObjectiveDef.Kind.ITEM, "ITEM_LUGGAGE_TAG", "MISSION_CH1_S01_OBJ_TAGS", "Find the lost luggage tags", 3)],
		_cond({"flags_all": ["ch1_started"]}))
	_save(s01, "missions", s01.id)
	var s02 := _mission("CH1_S02", MissionDef.Type.OPTIONAL, ["LOC_EC_HID_CLOCK_ROOM"],
		[_reach("CH1_S02", "LOC_EC_HID_CLOCK_ROOM"),
		_obj("link_the_clues", ObjectiveDef.Kind.PUZZLE, "PZL_CH1_CLOCK_DEDUCTION", "MISSION_CH1_S02_OBJ_DEDUCE", "Link what the wall and the station clock tell you"),
		_obj("set_the_dial", ObjectiveDef.Kind.PUZZLE, "PZL_CH1_CLOCK_4_17", "MISSION_CH1_S02_OBJ_DIAL", "Set the dial"),
		_obj("find_the_note", ObjectiveDef.Kind.TRACE, "TRC_CH1_CLOCKMAKER_NOTE", "MISSION_CH1_S02_OBJ_TRACE", "Find the clockmaker's note (optional)", 1, true)],
		_cond({"flags_all": ["ch1_started"], "abilities_all": ["ABIL_MEMORY_SIGHT"]}))
	_save(s02, "missions", s02.id)
	var c2 := _mission("CH2_M02", MissionDef.Type.MAIN, ["LOC_EC_MAYA_CAFE"],
		[_reach("CH2_M02", "LOC_EC_MAYA_CAFE"),
		_obj("talk_to_maya", ObjectiveDef.Kind.DIALOGUE, "DLG_CH2_M02_CAFE", "MISSION_CH2_M02_OBJ_TALK", "Talk to Maya")],
		_cond({"missions_complete": ["CH2_M01"]}))
	c2.reward_fragments.assign(["CH2_F01"])
	_save(c2, "missions", c2.id)
	var c3 := _mission("CH2_M03", MissionDef.Type.MAIN, ["LOC_EC_ABANDONED_BLDG"],
		[_reach("CH2_M03", "LOC_EC_ABANDONED_BLDG")], _cond({"missions_complete": ["CH2_M02"]}))
	c3.complete_flags.assign(["metro_unlocked"])
	_save(c3, "missions", c3.id)
	var d1 := DataRegistry.get_mission("CH3_M01")
	var loc3: Array = d1.locations if d1 != null else []
	var objectives3: Array = []
	for l in loc3:
		objectives3.append(_reach("CH3_M01", l))
	var m31 := _mission("CH3_M01", MissionDef.Type.MAIN, loc3, objectives3, ConditionSet.new())
	m31.reward_abilities.assign(["ABIL_REALITY_SHIFT", "ABIL_TIME_ECHO"])
	m31.complete_flags.assign(["other_side_reached"])
	_save(m31, "missions", m31.id)
	var m32 := _mission("CH3_M02", MissionDef.Type.MAIN, ["LOC_DL_ANCHOR_FIELDS"],
		[_reach("CH3_M02", "LOC_DL_ANCHOR_FIELDS"),
		_obj("use_reality_shift", ObjectiveDef.Kind.SHIFT, "SHF_CH3_ANCHOR_BRIDGE", "MISSION_CH3_M02_OBJ_SHIFT",
			"Use Reality Shift at the first anchor", 1, false, "other_side"),
		_obj("cross_and_exit", ObjectiveDef.Kind.PUZZLE, "PZL_CH3_ANCHOR_BRIDGE", "MISSION_CH3_M02_OBJ_BRIDGE",
			"Cross to the far platform and open the exit")], _cond({"missions_complete": ["CH3_M01"]}))
	m32.reward_fragments.assign(["CH3_F01"])
	m32.respawn_location = "LOC_DL_ANCHOR_FIELDS"
	_save(m32, "missions", m32.id)
	var s31 := _mission("CH3_S01", MissionDef.Type.OPTIONAL, ["LOC_DL_ECHO_GALLERY"],
		[_reach("CH3_S01", "LOC_DL_ECHO_GALLERY"),
		_obj("watch_the_echo", ObjectiveDef.Kind.ECHO, "ECH_CH3_TAPE_LOADING", "MISSION_CH3_S01_OBJ_ECHO", "Watch the echo of the reel loader"),
		_obj("order_the_reels", ObjectiveDef.Kind.PUZZLE, "PZL_CH3_TAPE_ORDER", "MISSION_CH3_S01_OBJ_TAPES", "Put the memories in order"),
		_obj("hold_both_plates", ObjectiveDef.Kind.PUZZLE, "PZL_CH3_ECHO_PLATES", "MISSION_CH3_S01_OBJ_PLATES", "Hold both plates with an echo")],
		_cond({"abilities_all": ["ABIL_TIME_ECHO"]}))
	_save(s31, "missions", s31.id)
