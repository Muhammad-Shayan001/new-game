class_name Localization
extends RefCounted
## All player-visible text is a translation key resolved with tr()/Localization.t().
## Translations are .po files in res://localization, registered in project.godot.
## To add a language: copy en_*.po to <locale>_*.po, translate, add it to project settings
## and to SettingsManager.SCHEMA["game"]["language"].

const DEFAULT_LOCALE := "en"

static func set_locale(locale: String) -> void:
	TranslationServer.set_locale(locale)

static func current_locale() -> String:
	return TranslationServer.get_locale()

## Translates a key. A missing translation is logged once and the key is returned,
## so gaps are visible but never crash the game.
static var _reported: Dictionary = {}
static func t(key: String) -> String:
	var text := TranslationServer.translate(key)
	if text == key and key != "" and not _reported.has(key):
		_reported[key] = true
		GameLog.warn("Localization", "missing translation '%s'" % key)
	return text
