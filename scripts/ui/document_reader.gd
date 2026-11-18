extends CanvasLayer
## Full-screen reader for notes, documents and computer screens (EventBus.document_requested).

var _panel: PanelContainer
var _title: Label
var _body: RichTextLabel

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 120
	_panel.offset_right = -120
	_panel.offset_top = 60
	_panel.offset_bottom = -60
	_panel.visible = false
	add_child(_panel)
	var box := VBoxContainer.new()
	_panel.add_child(box)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 32)
	box.add_child(_title)
	_body = RichTextLabel.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_font_size_override("normal_font_size", int(26 * float(Settings.value("text_scale"))))
	box.add_child(_body)
	var close := Button.new()
	close.text = Loc.t("ui.close")
	close.custom_minimum_size.y = 72
	close.pressed.connect(close_reader)
	box.add_child(close)
	EventBus.document_requested.connect(open_reader)

func open_reader(title_key: String, body_key: String) -> void:
	_title.text = Loc.t(title_key)
	_body.text = Loc.t(body_key)
	_panel.visible = true
	InputRouter.push_lock("document")

func close_reader() -> void:
	_panel.visible = false
	InputRouter.pop_lock("document")

func is_open() -> bool:
	return _panel.visible
