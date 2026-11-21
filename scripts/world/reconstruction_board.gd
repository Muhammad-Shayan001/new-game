class_name ReconstructionBoard
extends Node3D
## Memory reconstruction component: pick a memory card, place it in a numbered slot.
## When every slot is filled the arrangement goes to PuzzleManager (ORDERING logic).
## Children: Cards/<card_id> and Slots/Slot<N> Interactables (the scene builder makes them).
## Accessibility: slots are numbered and cards carry text names, no colour needed.

signal slots_changed

@export var puzzle_id: String = ""
@export var card_ids: Array[String] = []
@export var slot_count: int = 3
## card id -> text shown in a slot (accessibility: names, not colours).
@export var card_names: Dictionary = {}

var selected: String = ""
var slots: Array[String] = []

func _ready() -> void:
	slots.resize(slot_count)
	for id in card_ids:
		var card := get_node_or_null("Cards/" + id) as Interactable
		if card != null:
			card.interacted.connect(func(): select(id))
	for i in slot_count:
		var slot := get_node_or_null("Slots/Slot%d" % (i + 1)) as Interactable
		if slot != null:
			slot.interacted.connect(func(): place(i))

func select(card_id: String) -> void:
	if card_id in slots:
		return
	selected = card_id
	_update_labels()
	slots_changed.emit()

func place(index: int) -> void:
	if selected == "" or index < 0 or index >= slot_count:
		return
	slots[index] = selected
	selected = ""
	_update_labels()
	slots_changed.emit()
	if "" not in slots:
		var result := PuzzleManager.submit(puzzle_id, slots.duplicate())
		if result != PuzzleRuntime.Result.SOLVED:
			clear()

func clear() -> void:
	slots.fill("")
	selected = ""
	_update_labels()
	slots_changed.emit()

func _update_labels() -> void:
	for i in slot_count:
		var text := get_node_or_null("Slots/Slot%d/Text" % (i + 1)) as Label3D
		if text != null:
			text.text = "%d: %s" % [i + 1, card_names.get(slots[i], "...") if slots[i] != "" else "..."]
