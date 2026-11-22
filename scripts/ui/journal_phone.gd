class_name JournalPhone
extends Control

## Diegetic Smartphone & Investigation Journal ("EchoOS v4.0")
## Displays discovered clues, memory fragments, character dossiers, and choice logs.
## Accessible via Tab / J / Gamepad Back or the on-screen phone shortcut.

@onready var _panel: PanelContainer = $CenterContainer/PhoneContainer
@onready var _clues_list: VBoxContainer = $CenterContainer/PhoneContainer/VBox/TabContent/CluesScroll/CluesList
@onready var _memories_list: VBoxContainer = $CenterContainer/PhoneContainer/VBox/TabContent/MemoriesScroll/MemoriesList
@onready var _dossier_list: VBoxContainer = $CenterContainer/PhoneContainer/VBox/TabContent/DossierScroll/DossierList
@onready var _choices_list: VBoxContainer = $CenterContainer/PhoneContainer/VBox/TabContent/ChoicesScroll/ChoicesList
@onready var _tabs: HBoxContainer = $CenterContainer/PhoneContainer/VBox/NavBar
@onready var _close_btn: Button = $CenterContainer/PhoneContainer/VBox/TopBar/CloseButton

var _is_open: bool = false
var _active_tab: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_close_btn.pressed.connect(close)
	_setup_nav_buttons()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.JOURNAL) and not DialogueManager.is_active():
		toggle()
		get_viewport().set_input_as_handled()
	elif _is_open and event.is_action_pressed(InputActions.PAUSE):
		close()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	if _is_open:
		close()
	else:
		open()

func open() -> void:
	if _is_open:
		return
	_is_open = true
	visible = true
	InputService.push_lock("journal")
	AudioManager.play_cue("sfx_phone_buzz")
	refresh_all()

func close() -> void:
	if not _is_open:
		return
	_is_open = false
	visible = false
	InputService.pop_lock("journal")

func _setup_nav_buttons() -> void:
	var buttons: Array = _tabs.get_children()
	for i in buttons.size():
		var btn: Button = buttons[i] as Button
		if btn != null:
			btn.pressed.connect(func(): _select_tab(i))
	_select_tab(0)

func _select_tab(index: int) -> void:
	_active_tab = index
	var tab_containers: Array = [
		$CenterContainer/PhoneContainer/VBox/TabContent/CluesScroll,
		$CenterContainer/PhoneContainer/VBox/TabContent/MemoriesScroll,
		$CenterContainer/PhoneContainer/VBox/TabContent/DossierScroll,
		$CenterContainer/PhoneContainer/VBox/TabContent/ChoicesScroll
	]
	for i in tab_containers.size():
		(tab_containers[i] as Control).visible = (i == index)
	
	var nav_btns: Array = _tabs.get_children()
	for i in nav_btns.size():
		var b: Button = nav_btns[i] as Button
		if b != null:
			b.modulate = Color(0.0, 0.94, 1.0, 1.0) if i == index else Color(0.7, 0.7, 0.75, 0.8)

func refresh_all() -> void:
	_refresh_clues()
	_refresh_memories()
	_refresh_dossier()
	_refresh_choices()

func _refresh_clues() -> void:
	for c in _clues_list.get_children():
		c.queue_free()
	
	if GameState.clues.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No clues logged. Investigate the environment."
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65, 0.8))
		_clues_list.add_child(empty_lbl)
		return

	for clue_id in GameState.clues:
		var item := PanelContainer.new()
		var vb := VBoxContainer.new()
		var title := Label.new()
		title.text = "[!] %s" % clue_id.replace("CLUE_", "").replace("_", " ")
		title.add_theme_color_override("font_color", Color(0.0, 0.94, 1.0, 1.0))
		title.add_theme_font_size_override("font_size", 14)
		
		var desc := Label.new()
		desc.text = "Discovered clue in active district. Registered to EchoOS database."
		desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 0.9))
		desc.add_theme_font_size_override("font_size", 12)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		
		vb.add_child(title)
		vb.add_child(desc)
		item.add_child(vb)
		_clues_list.add_child(item)

func _refresh_memories() -> void:
	for c in _memories_list.get_children():
		c.queue_free()

	if GameState.memories.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No memory fragments restored. Use Memory Vision."
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65, 0.8))
		_memories_list.add_child(empty_lbl)
		return

	for mem_id in GameState.memories:
		var item := PanelContainer.new()
		var vb := VBoxContainer.new()
		var title := Label.new()
		title.text = "[MEMORY FRAGMENT] %s" % mem_id
		title.add_theme_color_override("font_color", Color(1.0, 0.2, 0.4, 1.0))
		title.add_theme_font_size_override("font_size", 14)
		
		var status := Label.new()
		status.text = "Restored Neural Trace // Status: DECRYPTED"
		status.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, 0.85))
		status.add_theme_font_size_override("font_size", 12)
		
		vb.add_child(title)
		vb.add_child(status)
		item.add_child(vb)
		_memories_list.add_child(item)

func _refresh_dossier() -> void:
	for c in _dossier_list.get_children():
		c.queue_free()

	var profiles: Array = [
		{"name": "ALEX MORGAN", "role": "Awakened Anomaly / System Engineer", "color": Color(0.0, 0.94, 1.0)},
		{"name": "THE ARCHIVIST", "role": "Keeper of Deleted Records", "color": Color(0.85, 0.85, 0.7)},
		{"name": "MAYA REED", "role": "Signal Technician / Living Tether", "color": Color(1.0, 0.8, 0.3)}
	]

	for p in profiles:
		var item := PanelContainer.new()
		var vb := VBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = p["name"]
		name_lbl.add_theme_color_override("font_color", p["color"])
		name_lbl.add_theme_font_size_override("font_size", 15)
		
		var role_lbl := Label.new()
		role_lbl.text = p["role"]
		role_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, 0.85))
		role_lbl.add_theme_font_size_override("font_size", 12)
		
		vb.add_child(name_lbl)
		vb.add_child(role_lbl)
		item.add_child(vb)
		_dossier_list.add_child(item)

func _refresh_choices() -> void:
	for c in _choices_list.get_children():
		c.queue_free()

	if GameState.choices.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No recorded moral or narrative choices."
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65, 0.8))
		_choices_list.add_child(empty_lbl)
		return

	for choice_entry in GameState.choices:
		var item := PanelContainer.new()
		var lbl := Label.new()
		lbl.text = "[DECISION] %s" % choice_entry
		lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, 0.9))
		lbl.add_theme_font_size_override("font_size", 13)
		item.add_child(lbl)
		_choices_list.add_child(item)
