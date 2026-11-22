class_name OpeningSequence
extends Control

## Opening Cinematic for AFTERLIFE.EXE
## Implements CinemaScope letterboxing, mystery message sequence, and seamless handoff.

signal finished

@onready var _subtitle_label: Label = $CenterContainer/SubtitleLabel
@onready var _prompt_label: Label = $BottomBar/PromptLabel
@onready var _skip_button: Button = $TopBar/SkipButton

var _lines: Array[String] = [
	"Echo City. Permanent Dusk. 04:17 AM.",
	"[UNKNOWN HOST]: YOU WERE NEVER SUPPOSED TO REMEMBER.",
	"YOU ARE DEAD. BUT YOUR STORY ISN'T OVER.",
	"Seek the Subway Concourse. He is waiting."
]

var _current_index: int = 0
var _text_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_skip_button.pressed.connect(_finish_sequence)
	_display_current_line()

func _input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		_advance_line()
		get_viewport().set_input_as_handled()

func _advance_line() -> void:
	_current_index += 1
	if _current_index >= _lines.size():
		_finish_sequence()
	else:
		_display_current_line()

func _display_current_line() -> void:
	if _current_index >= _lines.size():
		return

	AudioManager.play_cue("sfx_phone_buzz")
	var line: String = _lines[_current_index]
	_subtitle_label.text = line
	_subtitle_label.modulate.a = 0.0

	if _text_tween != null and _text_tween.is_valid():
		_text_tween.kill()

	_text_tween = create_tween()
	_text_tween.tween_property(_subtitle_label, "modulate:a", 1.0, 0.45)

func _finish_sequence() -> void:
	if _text_tween != null and _text_tween.is_valid():
		_text_tween.kill()
	AudioManager.play_cue("sfx_ability_shift")
	finished.emit()
