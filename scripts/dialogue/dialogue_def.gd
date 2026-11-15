class_name DialogueDef
extends GameDef
## A complete conversation. All text is stored as translation keys.

const MAX_CHOICES := 3

@export var start_id: String = ""
@export var nodes: Array[DialogueNode] = []
## If false the dialogue can only be played once (flag dlg_done_<id>).
@export var repeatable: bool = true

func kind() -> String:
	return "dialogue"

func find_node(node_id: String) -> DialogueNode:
	for n in nodes:
		if n.id == node_id:
			return n
	return null

func validate() -> Array[String]:
	var errors := super.validate()
	if find_node(start_id) == null:
		errors.append("%s: start_id '%s' is not a node" % [id, start_id])
	var seen := {}
	for n in nodes:
		if not IdRules.is_valid("node", n.id):
			errors.append("%s: node id '%s' must be snake_case" % [id, n.id])
		if seen.has(n.id):
			errors.append("%s: duplicate node id '%s'" % [id, n.id])
		seen[n.id] = true
		if n.next_id != "" and find_node(n.next_id) == null:
			errors.append("%s/%s: next_id '%s' is not a node" % [id, n.id, n.next_id])
		if n.choices.size() > MAX_CHOICES:
			errors.append("%s/%s: more than %d choices" % [id, n.id, MAX_CHOICES])
		if n.speaker_id != "" and not IdRules.is_valid("character", n.speaker_id):
			errors.append("%s/%s: bad speaker_id '%s'" % [id, n.id, n.speaker_id])
		for c in n.choices:
			if c.next_id != "" and find_node(c.next_id) == null:
				errors.append("%s/%s: choice next_id '%s' is not a node" % [id, n.id, c.next_id])
	return errors
