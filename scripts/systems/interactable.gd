class_name Interactable
extends Area3D
## Anything the player can use: NPCs, doors, notes, documents, phones, computers, puzzle objects,
## memory objects, mechanisms, pickups. Behaviour is data: the node's interaction_id points at a
## definition in resources/interactions/ (or resources/dev/interactions/), so the SAME id appears in
## mission objectives ("interacted") and dialogue effects. Nodes can also be configured in code via
## configure(def) (used by the graybox generator and tests).
##
## Types: npc, phone, door, note, document, computer, puzzle, memory, mechanism, pickup, generic.

signal used(by: Node)
signal focus_changed(focused: bool)
signal state_changed(active: bool)

const DEFAULT_PROMPTS := {
	"npc": "prompt.talk", "phone": "prompt.answer", "door": "prompt.open", "note": "prompt.read",
	"document": "prompt.read", "computer": "prompt.use", "puzzle": "prompt.examine",
	"memory": "prompt.remember", "mechanism": "prompt.use", "pickup": "prompt.take", "generic": "prompt.examine",
}

@export var interaction_id: String = ""
@export var type_override: String = ""         ## optional; normally comes from the definition

var def: Dictionary = {}
var focused: bool = false

func _init() -> void:
	collision_layer = 2          # layer 2: interactables
	collision_mask = 0
	monitorable = true
	monitoring = false

func _ready() -> void:
	if interaction_id != "" and def.is_empty():
		def = DataRegistry.get_def("interactions", interaction_id)
		if def.is_empty():
			Log.warn("Interactable", "No definition for '%s' (node %s)" % [interaction_id, name])
	_apply_hide_rules()
	if not _has_shape():
		var cs := CollisionShape3D.new()
		cs.name = "Shape"
		var sp := SphereShape3D.new()
		sp.radius = 0.8
		cs.shape = sp
		add_child(cs)

func _has_shape() -> bool:
	for c in get_children():
		if c is CollisionShape3D:
			return true
	return false

## Code-side configuration; id may be empty only for non-mission props.
func configure(definition: Dictionary) -> void:
	def = definition
	interaction_id = str(definition.get("id", interaction_id))
	_apply_hide_rules()

func _apply_hide_rules() -> void:
	if def.has("hide_when") and Condition.check(def["hide_when"]):
		_disable()
		return
	if bool(def.get("one_shot", false)) and GameState.get_flag("consumed:" + interaction_id):
		_disable()

func _disable() -> void:
	visible = false
	monitorable = false
	process_mode = Node.PROCESS_MODE_DISABLED
	for c in get_children():
		if c is Node3D:
			(c as Node3D).visible = false

func type_name() -> String:
	return type_override if type_override != "" else str(def.get("type", "generic"))

func hold_time() -> float:
	return float(def.get("hold_time", 0.0))

func is_available() -> bool:
	return monitorable and visible and Condition.check(def.get("visible_if", {}))

func prompt_key() -> String:
	return str(def.get("prompt_key", DEFAULT_PROMPTS.get(type_name(), "prompt.examine")))

func prompt_text() -> String:
	return Loc.t(prompt_key())

func set_focused(value: bool) -> void:
	if value == focused:
		return
	focused = value
	focus_changed.emit(value)
	for c in get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).material_override is StandardMaterial3D:
			var m := (c as MeshInstance3D).material_override as StandardMaterial3D
			m.emission_enabled = value
			m.emission = Color(0.9, 0.8, 0.3)
			m.emission_energy_multiplier = 0.6

## Entry point used by the Interactor. Returns true when the interaction actually happened.
func interact(by: Node = null) -> bool:
	if not is_available():
		return false
	if not Condition.check(def.get("requires", {})):
		EventBus.toast_requested.emit(Loc.t(str(def.get("locked_key", "ui.locked"))))
		return false
	_run_type_behaviour()
	Effects.run(def.get("effects", []))
	EventBus.interacted.emit(interaction_id)
	used.emit(by)
	if bool(def.get("one_shot", false)):
		GameState.set_flag("consumed:" + interaction_id, true)
		_disable()
	return true

func _run_type_behaviour() -> void:
	match type_name():
		"npc", "phone":
			if def.has("dialogue_id"):
				DialogueManager.start(str(def["dialogue_id"]))
		"door":
			if def.has("target_location"):
				SceneManager.go_to_location(str(def["target_location"]), str(def.get("spawn", "")))
			else:
				GameState.set_flag(str(def.get("state_flag", "door:" + interaction_id)), true)
		"note", "document":
			GameState.set_flag("read:" + interaction_id, true)
			EventBus.document_requested.emit(str(def.get("title_key", "ui.document")), str(def.get("text_key", "")))
		"computer", "puzzle":
			if def.has("puzzle_id"):
				EventBus.puzzle_requested.emit(str(def["puzzle_id"]))
			if def.has("dialogue_id"):
				DialogueManager.start(str(def["dialogue_id"]))
		"memory":
			if def.has("fragment_id"):
				MemoryManager.collect(str(def["fragment_id"]))
		"mechanism":
			var flag := str(def.get("state_flag", "mech:" + interaction_id))
			var now := not bool(GameState.get_flag(flag))
			GameState.set_flag(flag, now)
			state_changed.emit(now)
		"pickup":
			if def.has("item_id"):
				InventoryManager.add_item(str(def["item_id"]))
