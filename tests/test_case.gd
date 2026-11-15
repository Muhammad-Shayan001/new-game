class_name TestCase
extends Node
## Minimal test base. Test files live in tests/unit/test_*.gd; every method named
## test_* runs with a fresh world. Run all: see documentation in docs/BUILD_AND_TEST_GUIDE.md.

const TEST_SAVE_DIR := "user://test_saves"

var failures: Array[String] = []
var current_test := ""

func before_each() -> void:
	GameLog.reset_counters()
	GameState.reset()
	GameState.autosave_blocks = 0
	InputService.clear_locks()
	DialogueManager.cancel()
	AbilityManager.reset_runtime()
	PuzzleManager.reset_runtime()
	SaveManager.save_dir = TEST_SAVE_DIR
	for slot in [0, 1, 2, 3]:
		SaveManager.delete_slot(slot)

func after_each() -> void:
	pass

func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		failures.append("%s: expected true. %s" % [current_test, message])

func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		failures.append("%s: expected false. %s" % [current_test, message])

func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("%s: expected <%s> but got <%s>. %s" % [current_test, expected, actual, message])

## Records emitted EventBus signals: returns a Dictionary that fills as signals fire.
func watch(sig: Signal) -> Array:
	var log: Array = []
	sig.connect(func(a = null, b = null, c = null, d = null): log.append([a, b, c, d]))
	return log
