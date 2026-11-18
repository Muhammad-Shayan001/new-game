extends "res://tests/test_case.gd"

var lines: Array = []
var choices: Array = []
var finished: Array = []

func _hook() -> void:
	lines = []
	choices = []
	finished = []
	EventBus.dialogue_line_shown.connect(func(n, s, t): lines.append([n, s, t]))
	EventBus.dialogue_choices_shown.connect(func(c): choices = c)
	EventBus.dialogue_finished.connect(func(id): finished.append(id))

func test_linear_dialogue_and_effects() -> void:
	_hook()
	ok(DialogueManager.start("DLG_CH1_CATALOGUE"), "starts")
	ok(InputRouter.is_locked(), "input locked during dialogue")
	var guard := 0
	while DialogueManager.is_active() and guard < 30:
		DialogueManager.advance()
		guard += 1
	eq(lines.size(), 10, "ten lines shown")
	eq(lines[0][1], "ARV", "speaker id")
	ok(lines[0][2].begins_with("Item: one visitor"), "text localized")
	ok(not InputRouter.is_locked(), "input unlocked after")
	ok(InventoryManager.has_item("ITEM_ARCHIVE_CARD"), "end-of-dialogue effect granted item")
	ok(finished.has("DLG_CH1_CATALOGUE"), "finished signal")
	ok(not DialogueManager.start("DLG_CH1_CATALOGUE"), "once-only dialogue cannot repeat")

func test_choices_and_consequences() -> void:
	_hook()
	DialogueManager.start("DLG_CH2_CAFE")
	var guard := 0
	while choices.is_empty() and guard < 20:
		DialogueManager.advance()
		guard += 1
	eq(choices.size(), 2, "two choices shown")
	DialogueManager.choose(0)
	eq(GameState.get_relationship("maya_trust"), 1, "choice changed relationship")
	eq(GameState.decisions.size(), 1, "decision logged")
	DialogueManager.advance()
	ok(not DialogueManager.is_active(), "dialogue over")

func test_conditional_choice_hidden() -> void:
	_hook()
	DialogueManager.start("DLG_TEST_NPC")
	DialogueManager.advance()
	eq(choices.size(), 2, "choice requiring unset flag is hidden")
	DialogueManager.choose(1)          # visible index 1 = "Goodbye"
	eq(GameState.get_relationship("maya_trust"), -1, "mapped to the right underlying choice")
	DialogueManager.abort()

func test_cannot_start_two_dialogues() -> void:
	_hook()
	DialogueManager.start("DLG_TEST_PHONE")
	ok(not DialogueManager.start("DLG_TEST_NPC"), "second dialogue ignored while one runs")
	DialogueManager.abort()
	ok(not DialogueManager.is_active(), "abort ends it")

func test_unknown_dialogue_is_safe() -> void:
	ok(not DialogueManager.start("DLG_NOPE"), "unknown id returns false")
