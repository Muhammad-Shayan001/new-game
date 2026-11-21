extends Node
## Runs DialogueDef resources. Knows nothing about UI: it emits EventBus signals and
## the DialogueBox (or any other UI) calls advance() / choose().

var _def: DialogueDef
var _node: DialogueNode
var _visible_choices: Array[DialogueChoice] = []

func is_active() -> bool:
	return _def != null

func start(dialogue_id: String) -> bool:
	if is_active():
		GameLog.warn("Dialogue", "'%s' ignored: '%s' is already running" % [dialogue_id, _def.id])
		return false
	var def := DataRegistry.get_dialogue(dialogue_id)
	if def == null:
		GameLog.error("Dialogue", "unknown dialogue '%s'" % dialogue_id)
		return false
	var done_flag := _done_flag(dialogue_id)
	if not def.repeatable and GameState.get_flag(done_flag, false):
		return false
	_def = def
	InputService.push_lock("dialogue")
	EventBus.dialogue_started.emit(dialogue_id)
	_show(def.start_id)
	return true

## Player pressed "continue". Ignored while choices are on screen.
func advance() -> void:
	if _def == null or not _visible_choices.is_empty():
		return
	_show(_node.next_id)

func choose(index: int) -> void:
	if _def == null or index < 0 or index >= _visible_choices.size():
		return
	var choice := _visible_choices[index]
	for f in choice.set_flags:
		GameState.set_flag(f, true)
	_apply_effects(choice.set_states, choice.reveals_info)
	_apply_relationships(choice.relationship_changes)
	if choice.log_choice != "" and choice.log_choice not in GameState.choices:
		GameState.choices.append(choice.log_choice)
	_visible_choices = []
	_show(choice.next_id)

func cancel() -> void:
	if _def != null:
		_end()

func _show(node_id: String) -> void:
	# Skip nodes whose conditions are not met; guard against accidental loops.
	var guard := 0
	var node := _def.find_node(node_id) if node_id != "" else null
	while node != null and not ConditionSet.check(node.conditions) and guard < 64:
		node = _def.find_node(node.next_id) if node.next_id != "" else null
		guard += 1
	if node == null:
		_end()
		return
	_node = node
	for f in node.set_flags:
		GameState.set_flag(f, true)
	_apply_effects(node.set_states, node.reveals_info)
	_apply_relationships(node.relationship_changes)
	if node.voice_cue != "":
		AudioManager.play_cue(node.voice_cue)
	EventBus.dialogue_line_shown.emit(node.speaker_id, node.text_key)
	_visible_choices = []
	var payload: Array = []
	for c in node.choices:
		if ConditionSet.check(c.conditions) and _visible_choices.size() < DialogueDef.MAX_CHOICES:
			payload.append({"index": _visible_choices.size(), "text_key": c.text_key})
			_visible_choices.append(c)
	if not payload.is_empty():
		EventBus.dialogue_choices_presented.emit(payload)

func _end() -> void:
	var finished_id := _def.id
	GameState.set_flag(_done_flag(finished_id), true)
	_def = null
	_node = null
	_visible_choices = []
	InputService.pop_lock("dialogue")
	EventBus.dialogue_finished.emit(finished_id)

func _apply_effects(states: Dictionary, info: Array[String]) -> void:
	for s in states:
		StoryState.set_value(str(s), states[s])
	for i in info:
		ProgressionManager.reveal_info(i)

func _apply_relationships(changes: Dictionary) -> void:
	for key in changes:
		if StoryState.get_def(str(key)) != null:
			StoryState.add_value(str(key), int(changes[key]))
		else:
			GameState.add_relationship(str(key), int(changes[key]))

func _done_flag(dialogue_id: String) -> String:
	return "dlg_done_" + dialogue_id.to_lower()
