class_name SettingsMenu
extends Control
## Full settings panel for AFTERLIFE.EXE.
## Controls: Graphics Quality, FOV, FPS Cap, all volume channels,
## Look Sensitivity, Invert Y, Subtitles, Touch Opacity.

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
	_master_sl.value_changed.connect(func(v): _on_volume_changed("master_volume", v))
	_music_sl.value_changed.connect(func(v): _on_volume_changed("music_volume", v))
	_sfx_sl.value_changed.connect(func(v): _on_volume_changed("sfx_volume", v))
	_voice_sl.value_changed.connect(func(v): _on_volume_changed("voice_volume", v))
	_amb_sl.value_changed.connect(func(v): _on_volume_changed("ambient_volume", v))
	_sens_slider.value_changed.connect(_on_sensitivity_changed)
	_invert_y.toggled.connect(func(v): SettingsManager.set_value("gameplay", "invert_y", v))
	_subtitles.toggled.connect(func(v): SettingsManager.set_value("accessibility", "subtitles_enabled", v))
	_sub_size_opt.item_selected.connect(_on_sub_size_changed)
	_touch_opacity.value_changed.connect(func(v): SettingsManager.set_value("ui", "touch_opacity", v / 100.0))

func _load_from_settings() -> void:
	# Graphics
	var q: int = SettingsManager.get_value("graphics", "quality_preset", 1)
	_quality_opt.selected = clamp(q, 0, 2)
	# FOV
	var fov: float = SettingsManager.get_value("graphics", "fov", 75.0)
	_fov_slider.value = fov
	_fov_label.text = str(int(fov)) + "°"
	# FPS cap
	var fps_map := {30: 0, 60: 1, 90: 2, 0: 3}
	var cap: int = SettingsManager.get_value("graphics", "fps_cap", 60)
	_fps_opt.selected = fps_map.get(cap, 1)
	# Volumes (stored 0-1, displayed 0-100)
	_master_sl.value = SettingsManager.get_value("audio", "master_volume", 1.0) * 100.0
	_music_sl.value  = SettingsManager.get_value("audio", "music_volume",  0.8) * 100.0
	_sfx_sl.value    = SettingsManager.get_value("audio", "sfx_volume",    1.0) * 100.0
	_voice_sl.value  = SettingsManager.get_value("audio", "voice_volume",  1.0) * 100.0
	_amb_sl.value    = SettingsManager.get_value("audio", "ambient_volume", 0.9) * 100.0
	# Sensitivity
	var sens: float = SettingsManager.get_value("gameplay", "look_sensitivity", 1.0)
	_sens_slider.value = sens * 100.0
	_sens_label.text = "%.1f" % sens
	# Toggles
	_invert_y.button_pressed = SettingsManager.get_value("gameplay", "invert_y", false)
	_subtitles.button_pressed = SettingsManager.get_value("accessibility", "subtitles_enabled", true)
	var size_map := {"small": 0, "medium": 1, "large": 2}
	var sz: String = SettingsManager.get_value("accessibility", "subtitle_size", "medium")
	_sub_size_opt.selected = size_map.get(sz, 1)
	_touch_opacity.value = SettingsManager.get_value("ui", "touch_opacity", 0.8) * 100.0

func _on_quality_changed(idx: int) -> void:
	SettingsManager.set_value("graphics", "quality_preset", idx)
	EventBus.graphics_quality_changed.emit(idx)

func _on_fov_changed(value: float) -> void:
	SettingsManager.set_value("graphics", "fov", value)
	_fov_label.text = str(int(value)) + "°"
	EventBus.fov_changed.emit(value)

func _on_fps_changed(idx: int) -> void:
	var fps_values := [30, 60, 90, 0]
	var cap: int = fps_values[idx]
	SettingsManager.set_value("graphics", "fps_cap", cap)
	Engine.max_fps = cap

func _on_volume_changed(key: String, value: float) -> void:
	SettingsManager.set_value("audio", key, value / 100.0)
	AudioManager.apply_volumes()

func _on_sensitivity_changed(value: float) -> void:
	var normalized: float = value / 100.0
	SettingsManager.set_value("gameplay", "look_sensitivity", normalized)
	_sens_label.text = "%.1f" % normalized

func _on_sub_size_changed(idx: int) -> void:
	var sizes := ["small", "medium", "large"]
	SettingsManager.set_value("accessibility", "subtitle_size", sizes[idx])

func _on_close() -> void:
	SettingsManager.save()
	closed.emit()
	queue_free()
