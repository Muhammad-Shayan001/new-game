extends Node
## Runs every tests/unit/test_*.gd. Exit code 0 = all passed, 1 = failures.
##   godot --headless --path . res://tests/test_runner.tscn
## Optional filter:  ... -- test_missions

const WATCHDOG_SECONDS := 240.0

func _ready() -> void:
	get_tree().create_timer(WATCHDOG_SECONDS).timeout.connect(func():
		printerr("TIMEOUT: a test never finished")
		get_tree().quit(2))
	SceneRouter.fade_time = 0.0
	var filter := ""
	var user_args := OS.get_cmdline_user_args()
	if not user_args.is_empty():
		filter = user_args[0]
	var files := DirAccess.get_files_at("res://tests/unit")
	files.sort()
	var total := 0
	var failed := 0
	for file in files:
		if not file.begins_with("test_") or not file.ends_with(".gd"):
			continue
		if filter != "" and not file.contains(filter):
			continue
		var script := load("res://tests/unit/" + file) as GDScript
		if script == null or not script.can_instantiate():
			printerr("FAIL  %s does not compile" % file)
			total += 1
			failed += 1
			continue
		var suite: TestCase = script.new()
		add_child(suite)
		for method in suite.get_method_list():
			if not str(method["name"]).begins_with("test_"):
				continue
			suite.current_test = "%s.%s" % [file.get_basename(), method["name"]]
			suite.before_each()
			var before := suite.failures.size()
			await suite.call(method["name"])
			await suite.after_each()
			total += 1
			if suite.failures.size() > before:
				failed += 1
				print("FAIL  " + suite.current_test)
			else:
				print("ok    " + suite.current_test)
		for f in suite.failures:
			printerr("  -> " + f)
		suite.queue_free()
	print("\n%d tests, %d failed" % [total, failed])
	get_tree().quit(1 if failed > 0 else 0)
