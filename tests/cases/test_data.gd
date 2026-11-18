extends "res://tests/test_case.gd"
## Data integrity: every reference between content files must resolve.

const KEY_FIELDS := ["name_key", "desc_key", "text_key", "title_key", "prompt_key", "locked_key", "label_key"]

func test_registry_loads_cleanly() -> void:
	eq(DataRegistry.errors.size(), 0, "registry errors: " + "; ".join(DataRegistry.errors))
	eq(DataRegistry.count("locations") >= 48, true, "locations loaded (47 world + dev arena)")
	eq(DataRegistry.count("fragments"), 30, "30 memory fragments")
	eq(DataRegistry.count("abilities"), 4, "4 abilities")
	eq(DataRegistry.count("characters"), 5, "5 characters")

func test_location_connections_are_valid_and_symmetric() -> void:
	for loc: Dictionary in DataRegistry.all_defs("locations"):
		for c: Dictionary in loc["connections"]:
			ok(DataRegistry.has_def("locations", c["to"]), "%s -> %s exists" % [loc["id"], c["to"]])
			var back := false
			for c2: Dictionary in DataRegistry.get_def("locations", c["to"])["connections"]:
				if c2["to"] == loc["id"]:
					back = true
			ok(back, "%s <-> %s is symmetric" % [loc["id"], c["to"]])

func test_missions_reference_real_content() -> void:
	for m: Dictionary in DataRegistry.all_defs("missions"):
		ok(DataRegistry.has_def("locations", m["location"]), "%s location" % m["id"])
		for o: Dictionary in m["objectives"]:
			var cw: Dictionary = o.get("complete_when", {})
			match cw.get("event", ""):
				"location_entered": ok(DataRegistry.has_def("locations", cw["arg"]), "%s objective location %s" % [m["id"], cw["arg"]])
				"dialogue_finished": ok(DataRegistry.has_def("dialogue", cw["arg"]), "%s dialogue %s" % [m["id"], cw["arg"]])
				"puzzle_solved": ok(DataRegistry.has_def("puzzles", cw["arg"]), "%s puzzle %s" % [m["id"], cw["arg"]])
				"interacted": ok(DataRegistry.has_def("interactions", cw["arg"]), "%s interaction %s" % [m["id"], cw["arg"]])
		for list_name in ["on_start", "on_complete"]:
			for e: Dictionary in m.get(list_name, []):
				if e["do"] == "unlock_ability":
					ok(DataRegistry.has_def("abilities", e["id"]), "%s ability %s" % [m["id"], e["id"]])

func test_fragments_and_interactions_reference_real_content() -> void:
	for f: Dictionary in DataRegistry.all_defs("fragments"):
		ok(DataRegistry.has_def("locations", f["location"]), "fragment %s location" % f["id"])
	for i: Dictionary in DataRegistry.all_defs("interactions"):
		if i.has("location"):
			ok(DataRegistry.has_def("locations", i["location"]), "interaction %s location" % i["id"])
		if i.has("dialogue_id"):
			ok(DataRegistry.has_def("dialogue", i["dialogue_id"]), "interaction %s dialogue" % i["id"])
		if i.has("puzzle_id"):
			ok(DataRegistry.has_def("puzzles", i["puzzle_id"]), "interaction %s puzzle" % i["id"])
		if i.has("item_id"):
			ok(DataRegistry.has_def("items", i["item_id"]), "interaction %s item" % i["id"])
		if i.has("fragment_id"):
			ok(DataRegistry.has_def("fragments", i["fragment_id"]), "interaction %s fragment" % i["id"])

func test_dialogue_graphs_are_well_formed() -> void:
	for d: Dictionary in DataRegistry.all_defs("dialogue"):
		var nodes: Dictionary = d["nodes"]
		ok(nodes.has(d["start"]), "%s start node" % d["id"])
		for nid: String in nodes:
			var n: Dictionary = nodes[nid]
			if n.has("speaker"):
				ok(DataRegistry.has_def("characters", n["speaker"]), "%s speaker %s" % [d["id"], n["speaker"]])
			if n.has("next"):
				ok(nodes.has(n["next"]), "%s next %s" % [d["id"], n["next"]])
			for c: Dictionary in n.get("choices", []):
				ok(c.get("next", "") == "" or nodes.has(c["next"]), "%s choice target" % d["id"])
			for b: Dictionary in n.get("branch", []):
				ok(b.get("next", "") == "" or nodes.has(b["next"]), "%s branch target" % d["id"])

func test_every_localization_key_exists() -> void:
	var missing: Array = []
	for kind in DataRegistry.KINDS:
		for d: Dictionary in DataRegistry.all_defs(kind):
			_collect_keys(d, missing)
	for k in missing:
		fails.append("%s: missing localization key %s" % [current, k])
	ok(true)

func _collect_keys(v: Variant, missing: Array) -> void:
	if v is Dictionary:
		for k in v:
			if k in KEY_FIELDS and v[k] is String and not Loc.has_key(v[k]):
				missing.append(v[k])
			elif k == "args_keys":
				for ak in v[k]:
					if not Loc.has_key(v[k][ak]):
						missing.append(v[k][ak])
			elif k == "hints":
				for h in v[k]:
					if not Loc.has_key(h):
						missing.append(h)
			else:
				_collect_keys(v[k], missing)
	elif v is Array:
		for e in v:
			_collect_keys(e, missing)

func test_dialogue_speaker_names_localized() -> void:
	for c: Dictionary in DataRegistry.all_defs("characters"):
		ok(Loc.has_key(c["name_key"]), "character name %s" % c["id"])

func test_abilities_load_their_scripts() -> void:
	for a: Dictionary in DataRegistry.all_defs("abilities"):
		ok(load(a["script"]) is Script, "ability script %s" % a["script"])
