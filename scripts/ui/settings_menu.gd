class_name SettingsMenu
extends Control
## Settings panel for AFTERLIFE.EXE.
## Fully aligned with SettingsManager SCHEMA.

signal closed

# ── Node references ──────────────────────────────────────────────────────────
@onready var _quality_opt: OptionButton  = $Panel/Scroll/VBox/GraphicsQuality/OptionButton
@onready var _fov_slider: HSlider        = $Panel/Scroll/VBox/FOV/HSlider
@onready var _fov_label: Label           = $Panel/Scroll/VBox/FOV/Value
@onready var _fps_opt: OptionButton      = $Panel/Scroll/VBox/FPSCap/OptionButton
@onready var _master_sl: HSlider         = $Panel/Scroll/VBox/MasterVol/HSlider
@onready var _music_sl: HSlider          = $Panel/Scroll/VBox/MusicVol/HSlider
@onready var _sfx_sl: HSlider            = $Panel/Scroll/VBox/SFXVol/HSlider
@onready var _voice_sl: HSlider          = $Panel/Scroll/VBox/VoiceVol/HSlider
@onready var _amb_sl: HSlider            = $Panel/Scroll/VBox/AmbVol/HSlider
@onready var _sens_slider: HSlider       = $Panel/Scroll/VBox/Sensitivity/HSlider
@onready var _sens_label: Label          = $Panel/Scroll/VBox/Sensitivity/Value
@onready var _invert_y: CheckButton      = $Panel/Scroll/VBox/InvertY/CheckButton
@onready var _subtitles: CheckButton     = $Panel/Scroll/VBox/Subtitles/CheckButton
@onready var _sub_size_opt: OptionButton = $Panel/Scroll/VBox/SubtitleSize/OptionButton
@onready var _touch_opacity: HSlider     = $Panel/Scroll/VBox/TouchOpacity/HSlider
@onready var _close_btn: Button          = $Panel/CloseButton

func _ready() -> void:
	_load_from_settings()
	_close_btn.pressed.connect(_on_close)
	_quality_opt.item_selected.connect(_on_quality_changed)
	_fov_slider.value_changed.connect(_on_fov_changed)
	_fps_opt.item_selected.connect(_on_fps_changed)
	_master_sl.value_changed.connect(func(v): _on_volume_changed("master", v))
	_music_sl.value_changed.connect(func(v): _on_volume_changed("music", v))
	_sfx_sl.value_changed.connect(func(v): _on_volume_changed("sfx", v))
	_voice_sl.value_changed.connect(func(v): _on_volume_changed("voice", v))
	_amb_sl.value_changed.connect(func(v): _on_volume_changed("ambience", v))
	_sens_slider.value_changed.connect(_on_sensitivity_changed)
	_invert_y.toggled.connect(func(v): SettingsManager.set_value("controls", "invert_y", v))
	_subtitles.toggled.connect(func(v): SettingsManager.set_value("accessibility", "subtitles", v))
	_sub_size_opt.item_selected.connect(_on_sub_size_changed)
	_touch_opacity.value_changed.connect(func(v): SettingsManager.set_value("controls", "touch_opacity", v / 100.0))

func _load_from_settings() -> void:
	# Video / Quality
	var quality_str: String = str(SettingsManager.get_value("video", "quality"))
	var q_map := {"low": 0, "medium": 1, "high": 2}
	_quality_opt.selected = q_map.get(quality_str, 1)

	# FOV
	var fov_val = SettingsManager.get_value("video", "fov")
	var fov: float = float(fov_val) if fov_val != null else 65.0
	_fov_slider.value = fov
	_fov_label.text = str(int(fov)) + "°"

	# FPS cap
	var fps_cap: int = int(SettingsManager.get_value("video", "fps_cap"))
	var fps_idx_map := {30: 0, 60: 1, 120: 2}
	_fps_opt.selected = fps_idx_map.get(fps_cap, 1)

	# Audio Volumes (stored 0.0 - 1.0, slider 0 - 100)
	_master_sl.value = float(SettingsManager.get_value("audio", "master")) * 100.0
	_music_sl.value  = float(SettingsManager.get_value("audio", "music")) * 100.0
	_sfx_sl.value    = float(SettingsManager.get_value("audio", "sfx")) * 100.0
	_voice_sl.value  = float(SettingsManager.get_value("audio", "voice")) * 100.0
	_amb_sl.value    = float(SettingsManager.get_value("audio", "ambience")) * 100.0

	# Controls / Sensitivity
	var sens: float = float(SettingsManager.get_value("controls", "look_sensitivity"))
	_sens_slider.value = sens * 100.0
	_sens_label.text = "%.1f" % sens

	# Toggles
	_invert_y.button_pressed = bool(SettingsManager.get_value("controls", "invert_y"))
	_subtitles.button_pressed = bool(SettingsManager.get_value("accessibility", "subtitles"))

	var sub_scale: float = float(SettingsManager.get_value("accessibility", "subtitle_size"))
	if sub_scale <= 0.85:
		_sub_size_opt.selected = 0
	elif sub_scale >= 1.3:
		_sub_size_opt.selected = 2
	else:
		_sub_size_opt.selected = 1

	_touch_opacity.value = float(SettingsManager.get_value("controls", "touch_opacity")) * 100.0

func _on_quality_changed(idx: int) -> void:
	var q_names := ["low", "medium", "high"]
	SettingsManager.set_value("video", "quality", q_names[clampi(idx, 0, 2)])
	EventBus.graphics_quality_changed.emit(idx)

func _on_fov_changed(value: float) -> void:
	SettingsManager.set_value("video", "fov", value)
	_fov_label.text = str(int(value)) + "°"
	EventBus.fov_changed.emit(value)

func _on_fps_changed(idx: int) -> void:
	var fps_values := [30, 60, 120, 60]
	var cap: int = fps_values[clampi(idx, 0, 2)]
	SettingsManager.set_value("video", "fps_cap", cap)

func _on_volume_changed(key: String, value: float) -> void:
	SettingsManager.set_value("audio", key, clampf(value / 100.0, 0.0, 1.0))

func _on_sensitivity_changed(value: float) -> void:
	var normalized: float = clampf(value / 100.0, 0.25, 3.0)
	SettingsManager.set_value("controls", "look_sensitivity", normalized)
	_sens_label.text = "%.1f" % normalized

func _on_sub_size_changed(idx: int) -> void:
	var sizes := [0.85, 1.0, 1.4]
	SettingsManager.set_value("accessibility", "subtitle_size", sizes[clampi(idx, 0, 2)])

func _on_close() -> void:
	SettingsManager.save_settings()
	closed.emit()
	queue_free()
