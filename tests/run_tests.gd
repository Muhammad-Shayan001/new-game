extends SceneTree
## Headless test runner. Usage (from the project root):
##   godot --headless --fixed-fps 60 --path . -s res://tests/run_tests.gd [-- filter]
## Runs every tests/cases/test_*.gd; each public method named test_* is one test (may await).
## Exit code 0 = all passed, 1 = failures.

const CASES_DIR := "res://tests/cases"
var passed := 0
var failed := 0
var failures: PackedStringArray = PackedStringArray()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var filter := ""
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		filter = args[0]
	var files := Array(DirAccess.get_files_at(CASES_DIR))
	files.sort()
	for f: String in files:
		if not f.begins_with("test_") or not f.ends_with(".gd"):
			continue
		if filter != "" and not f.contains(filter):
			continue
		var script: GDScript = load(CASES_DIR + "/" + f)
		if script == null:
			failed += 1
			failures.append("%s: failed to load" % f)
			continue
		for method in script.get_script_method_list():
			var m: String = method["name"]
			if not m.begins_with("test_"):
				continue
			var inst = script.new()
			inst.tree = self
			await inst.before_each()
			inst.current = "%s::%s" % [f, m]
			await inst.call(m)
			await inst.after_each()
			passed += inst.passes
			failed += inst.fails.size()
			failures.append_array(inst.fails)
			var status := "PASS" if inst.fails.is_empty() else "FAIL"
			print("[%s] %s::%s (%d checks)" % [status, f.trim_suffix(".gd"), m, inst.passes + inst.fails.size()])
			for line in inst.fails:
				print("      " + line)

	print("\n==== %d checks passed, %d failed ====" % [passed, failed])
	quit(1 if failed > 0 else 0)
