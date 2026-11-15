class_name IdRules
extends RefCounted
## Unique ID formats for every kind of game data. See docs/DATA_SCHEMA.md.
## File name of a resource = lower-case ID (e.g. CH1_M01 -> ch1_m01.tres).

const PATTERNS := {
	"location": "^LOC_[A-Z]{2}_[A-Z0-9_]+$",
	"mission": "^CH[1-6]_[MS][0-9]{2}$",
	"fragment": "^CH[1-6]_F[0-9]{2}$",
	"dialogue": "^DLG_[A-Z0-9_]+$",
	"item": "^ITEM_[A-Z0-9_]+$",
	"clue": "^CLUE_[A-Z0-9_]+$",
	"puzzle": "^PZL_[A-Z0-9_]+$",
	"ability": "^ABIL_[A-Z0-9_]+$",
	"character": "^[A-Z]{3}$",
	"audio": "^AUD_[A-Z0-9_]+$",
	"deduction": "^DED_[A-Z0-9_]+$",
	"interactable": "^INT_[A-Z0-9_]+$",
	"flag": "^[a-z][a-z0-9_]*$",
	"spawn": "^[a-z][a-z0-9_]*$",
	"node": "^[a-z][a-z0-9_]*$",
}

static var _cache: Dictionary = {}

static func is_valid(kind: String, id: String) -> bool:
	if not PATTERNS.has(kind):
		return false
	if not _cache.has(kind):
		var rx := RegEx.new()
		rx.compile(PATTERNS[kind])
		_cache[kind] = rx
	return (_cache[kind] as RegEx).search(id) != null

static func file_stem(id: String) -> String:
	return id.to_lower()
