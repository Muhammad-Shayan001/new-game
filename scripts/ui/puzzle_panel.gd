extends CanvasLayer
## Generic puzzle UI for sequence/set/code puzzles defined in data (options + solution + hints).
## Opened by EventBus.puzzle_requested. Submits automatically when enough options are chosen.

var _panel: PanelContainer
var _title: Label
var _entry: Label
var _options: HFlowContainer
var _status: Label
var _puzzle_id: String = ""
var _answer: Array = []

func _ready() -> void:
	layer = 26
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(760, 420)
	_panel.visible = false
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_panel.add_child(box)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 30)
	box.add_child(_title)
	_entry = Label.new()
	_entry.add_theme_font_size_override("font_size", 28)
	box.add_child(_entry)
	_options = HFlowContainer.new()
	box.add_child(_options)
	_status = Label.new()
	box.add_child(_status)
	var row := HBoxContainer.new()
	box.add_child(row)
	for spec in [["ui.reset", _reset], ["ui.hint", _hint], ["ui.close", close_panel]]:
		var b := Button.new()
		b.text = Loc.t(spec[0])
		b.custom_minimum_size = Vector2(160, 68)
		b.pressed.connect(spec[1])
		row.add_child(b)
	EventBus.puzzle_requested.connect(open_puzzle)

func open_puzzle(id: String) -> void:
	var def := DataRegistry.get_def("puzzles", id)
	if def.is_empty():
		return
	_puzzle_id = id
	_title.text = Loc.t(str(def.get("title_key", "ui.puzzle")))
	for c in _options.get_children():
		c.queue_free()
	for o: Dictionary in def.get("options", []):
		var b := Button.new()
		b.text = Loc.t(str(o["label_key"]))
		b.custom_minimum_size = Vector2(150, 84)
		b.pressed.connect(_choose.bind(str(o["id"])))
		_options.add_child(b)
	_reset()
	if PuzzleManager.is_solved(id):
		_status.text = Loc.t("ui.puzzle_solved")
	_panel.visible = true
	InputRouter.push_lock("puzzle")

func _choose(option_id: String) -> void:
	if PuzzleManager.is_solved(_puzzle_id):
		return
	_answer.append(option_id)
	_entry.text = " > ".join(_answer)
	var need: int = DataRegistry.get_def("puzzles", _puzzle_id)["solution"].size()
	if _answer.size() >= need:
		if PuzzleManager.submit(_puzzle_id, _answer):
			_status.text = Loc.t("ui.puzzle_solved")
		else:
			_status.text = Loc.t("ui.puzzle_wrong")
			_answer = []

func _reset() -> void:
	_answer = []
	_entry.text = ""
	_status.text = ""

func _hint() -> void:
	var key := PuzzleManager.hint(_puzzle_id)
	_status.text = Loc.t(key) if key != "" else Loc.t("ui.no_more_hints")

func close_panel() -> void:
	if _panel.visible:
		_panel.visible = false
		InputRouter.pop_lock("puzzle")

func is_open() -> bool:
	return _panel.visible
