extends Node
## Loads every definition under res://resources/ and serves them by kind + id.
## Adding content = adding a .tres file. No code changes, no registration list.

## kind -> folder. File name must be the lower-case id (ch1_m01.tres).
const FOLDERS := {
	"location": "res://resources/locations",
	"mission": "res://resources/missions",
	"fragment": "res://resources/fragments",
	"dialogue": "res://resources/dialogue",
	"item": "res://resources/items",
	"ability": "res://resources/abilities",
	"puzzle": "res://resources/puzzles",
	"character": "res://resources/characters",
	"audio": "res://resources/audio",
	"deduction": "res://resources/deductions",
	"story_state": "res://resources/story_states",
	"info": "res://resources/info",
	"shift_zone": "res://resources/shift_zones",
	"echo": "res://resources/echoes",
}

var _defs: Dictionary = {}       # kind -> {id: GameDef}
var load_errors: Array[String] = []

func _ready() -> void:
	reload()

func reload() -> void:
	_defs.clear()
	load_errors.clear()
	for kind in FOLDERS:
		_defs[kind] = {}
		_scan(kind, FOLDERS[kind])
	if is_inside_tree() and has_node("/root/StoryState"):
		get_node("/root/StoryState").rebuild_aliases()

func _scan(kind: String, dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for sub in DirAccess.get_directories_at(dir):
		_scan(kind, dir.path_join(sub))
	for file in DirAccess.get_files_at(dir):
		var name := file.trim_suffix(".remap")   # exported builds rename resources
		if not (name.ends_with(".tres") or name.ends_with(".res")):
			continue
		var path := dir.path_join(name)
		var res := ResourceLoader.load(path)
		if res == null or not (res is GameDef):
			load_errors.append("%s: not a GameDef resource" % path)
			continue
		var def := res as GameDef
		if def.kind() != kind:
			load_errors.append("%s: is a %s but lives in the %s folder" % [path, def.kind(), kind])
			continue
		if _defs[kind].has(def.id):
			load_errors.append("%s: duplicate %s id '%s'" % [path, kind, def.id])
			continue
		if name.get_basename() != IdRules.file_stem(def.id):
			load_errors.append("%s: file name must be '%s'" % [path, IdRules.file_stem(def.id)])
		_defs[kind][def.id] = def

## Adds a definition at runtime (tests, mods, procedural content). Same rules as files.
func register_runtime(def: GameDef) -> bool:
	var kind := def.kind()
	if not _defs.has(kind) or _defs[kind].has(def.id):
		return false
	_defs[kind][def.id] = def
	if kind == "story_state" and has_node("/root/StoryState"):
		get_node("/root/StoryState").rebuild_aliases()
	return true

func has_def(kind: String, id: String) -> bool:
	return _defs.get(kind, {}).has(id)

func get_def(kind: String, id: String) -> GameDef:
	return _defs.get(kind, {}).get(id)

func all(kind: String) -> Array:
	return _defs.get(kind, {}).values()

func ids(kind: String) -> Array:
	return _defs.get(kind, {}).keys()

## Typed shortcuts.
func get_location(id: String) -> LocationDef: return get_def("location", id) as LocationDef
func get_mission(id: String) -> MissionDef: return get_def("mission", id) as MissionDef
func get_fragment(id: String) -> FragmentDef: return get_def("fragment", id) as FragmentDef
func get_dialogue(id: String) -> DialogueDef: return get_def("dialogue", id) as DialogueDef
func get_item(id: String) -> ItemDef: return get_def("item", id) as ItemDef
func get_ability(id: String) -> AbilityDef: return get_def("ability", id) as AbilityDef
func get_puzzle(id: String) -> PuzzleDef: return get_def("puzzle", id) as PuzzleDef
func get_character(id: String) -> CharacterDef: return get_def("character", id) as CharacterDef
func get_audio(id: String) -> AudioCueDef: return get_def("audio", id) as AudioCueDef
func get_deduction(id: String) -> DeductionDef: return get_def("deduction", id) as DeductionDef
func get_story_state(id: String) -> StoryStateDef: return get_def("story_state", id) as StoryStateDef
func get_info(id: String) -> InfoDef: return get_def("info", id) as InfoDef
func get_shift_zone(id: String) -> ShiftZoneDef: return get_def("shift_zone", id) as ShiftZoneDef
func get_echo(id: String) -> TimeEchoDef: return get_def("echo", id) as TimeEchoDef

## Full content check: IDs, naming, dangling references, translations.
## Returns a list of problems (empty = healthy). Run by tests and tools/content_tool.gd.
func validate_all() -> Array[String]:
	var errors: Array[String] = load_errors.duplicate()
	for kind in _defs:
		for def in _defs[kind].values():
			errors.append_array(def.validate())
	for m in all("mission"):
		for l in m.locations:
			_require(errors, "location", l, "mission %s" % m.id)
		_require_optional(errors, "dialogue", m.completion_dialogue, "mission %s" % m.id)
		_require_optional(errors, "location", m.respawn_location, "mission %s" % m.id)
		for f in m.reward_fragments: _require(errors, "fragment", f, "mission %s" % m.id)
		for i in m.reward_items: _require(errors, "item", i, "mission %s" % m.id)
		for a in m.reward_abilities: _require(errors, "ability", a, "mission %s" % m.id)
		for o in m.objectives:
			var k: String = o.target_id_kind()
			if k in ["location", "fragment", "item", "puzzle", "dialogue"]:
				_require(errors, k, o.target, "mission %s/%s" % [m.id, o.id])
			_check_key(errors, o.text_key, "mission %s/%s" % [m.id, o.id])
		if m.unlock != null:
			_check_conditions(errors, m.unlock, "mission %s" % m.id)
		_check_key(errors, m.title_key, "mission %s" % m.id)
	for f in all("fragment"):
		_require(errors, "location", f.location_id, "fragment %s" % f.id)
		_check_key(errors, f.name_key, "fragment %s" % f.id)
	for l in all("location"):
		_check_key(errors, l.name_key, "location %s" % l.id)
		for c in l.connections:
			_require(errors, "location", c.to_location, "location %s" % l.id)
	for d in all("dialogue"):
		for n in d.nodes:
			_require_optional(errors, "character", n.speaker_id, "dialogue %s/%s" % [d.id, n.id])
			_check_key(errors, n.text_key, "dialogue %s/%s" % [d.id, n.id])
			if n.conditions != null: _check_conditions(errors, n.conditions, "dialogue %s/%s" % [d.id, n.id])
			for c in n.choices:
				_check_key(errors, c.text_key, "dialogue %s/%s choice" % [d.id, n.id])
	for p in all("puzzle"):
		for h in p.hint_keys: _check_key(errors, h, "puzzle %s hint" % p.id)
		if p.puzzle_type == PuzzleDef.Type.ORDERING:
			for i in p.solution: _require(errors, "item", i, "puzzle %s" % p.id)
	for c in all("character"):
		_check_key(errors, c.name_key, "character %s" % c.id)
	_validate_story_data(errors)
	return errors

## Story-state consistency, plus the Prompt 08/09 definition kinds.
func _validate_story_data(errors: Array[String]) -> void:
	for m in all("mission"):
		for f in m.start_flags + m.complete_flags + m.fail_flags:
			_check_flag(errors, f, "mission %s" % m.id)
		for s in m.complete_states:
			_check_flag(errors, str(s), "mission %s complete_states" % m.id)
		for i in m.reward_info:
			_require(errors, "info", i, "mission %s" % m.id)
		for c in m.reward_clues:
			if not IdRules.is_valid("clue", c): errors.append("mission %s: bad clue '%s'" % [m.id, c])
		_require_optional(errors, "dialogue", m.fail_dialogue, "mission %s" % m.id)
		for o in m.objectives:
			if o.objective_kind == ObjectiveDef.Kind.FLAG:
				_check_flag(errors, o.target, "mission %s/%s" % [m.id, o.id])
			elif o.target_id_kind() in ["echo", "shift_zone", "info"]:
				_require(errors, o.target_id_kind(), o.target, "mission %s/%s" % [m.id, o.id])
			if o.objective_kind == ObjectiveDef.Kind.SHIFT:
				var zone := get_shift_zone(o.target)
				if zone != null and o.value not in zone.states:
					errors.append("mission %s/%s: '%s' is not a state of %s" % [m.id, o.id, o.value, o.target])
			if o.conditions != null:
				_check_conditions(errors, o.conditions, "mission %s/%s" % [m.id, o.id])
	for d in all("dialogue"):
		for n in d.nodes:
			for f in n.set_flags: _check_flag(errors, f, "dialogue %s/%s" % [d.id, n.id])
			for s in n.set_states: _check_flag(errors, str(s), "dialogue %s/%s" % [d.id, n.id])
			for i in n.reveals_info: _require(errors, "info", i, "dialogue %s/%s" % [d.id, n.id])
			for c in n.choices:
				for f in c.set_flags: _check_flag(errors, f, "dialogue %s choice" % d.id)
				for s in c.set_states: _check_flag(errors, str(s), "dialogue %s choice" % d.id)
				for i in c.reveals_info: _require(errors, "info", i, "dialogue %s choice" % d.id)
				if c.conditions != null: _check_conditions(errors, c.conditions, "dialogue %s choice" % d.id)
	for p in all("puzzle"):
		for f in p.set_flags: _check_flag(errors, f, "puzzle %s" % p.id)
		for a in p.required_abilities: _require(errors, "ability", a, "puzzle %s" % p.id)
		for fr in p.reward_fragments: _require(errors, "fragment", fr, "puzzle %s" % p.id)
		for i in p.reward_items: _require(errors, "item", i, "puzzle %s" % p.id)
		_require_optional(errors, "location", p.location_id, "puzzle %s" % p.id)
		_check_key(errors, p.title_key, "puzzle %s" % p.id)
	for dd in all("deduction"):
		for f in dd.set_flags: _check_flag(errors, f, "deduction %s" % dd.id)
	for e in all("echo"):
		_require_optional(errors, "location", e.location_id, "echo %s" % e.id)
		for f in e.set_flags: _check_flag(errors, f, "echo %s" % e.id)
		if e.conditions != null: _check_conditions(errors, e.conditions, "echo %s" % e.id)
		for cue in e.audio_events: _require(errors, "audio", cue.cue_id, "echo %s" % e.id)
		for cap in e.captions: _check_key(errors, cap.text_key, "echo %s caption" % e.id)
		for cm in e.clue_moments:
			_require_optional(errors, "fragment", cm.fragment_id, "echo %s" % e.id)
			_require_optional(errors, "info", cm.info_id, "echo %s" % e.id)
		for t in e.tracks:
			_require_optional(errors, "character", t.actor_id if not t.is_prop else "", "echo %s" % e.id)
	for z in all("shift_zone"):
		_require_optional(errors, "location", z.location_id, "shift zone %s" % z.id)
		_check_key(errors, z.title_key, "shift zone %s" % z.id)
	for i in all("info"):
		_require(errors, "character", i.character_id, "info %s" % i.id)
		_check_key(errors, i.text_key, "info %s" % i.id)
	for ab in all("ability"):
		_require_optional(errors, "audio", ab.activation_cue, "ability %s" % ab.id)

func _check_flag(errors: Array[String], flag: String, owner: String) -> void:
	if not StoryState.is_known(flag):
		errors.append("%s: '%s' is not a registered story state (add it to resources/story_states)" % [owner, flag])

func _require(errors: Array[String], kind: String, id: String, owner: String) -> void:
	if not has_def(kind, id):
		errors.append("%s: unknown %s '%s'" % [owner, kind, id])

func _require_optional(errors: Array[String], kind: String, id: String, owner: String) -> void:
	if id != "":
		_require(errors, kind, id, owner)

func _check_key(errors: Array[String], key: String, owner: String) -> void:
	if key == "" or TranslationServer.translate(key) == key:
		errors.append("%s: missing translation for '%s'" % [owner, key])

func _check_conditions(errors: Array[String], c: ConditionSet, owner: String) -> void:
	var refs := c.referenced_ids()
	for kind in refs:
		if kind in ["clue", "trace"]:
			continue
		for id in refs[kind]:
			_require(errors, kind, id, owner)
	for f in c.referenced_flags():
		_check_flag(errors, f, owner)
