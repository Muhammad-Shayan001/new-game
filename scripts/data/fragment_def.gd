class_name FragmentDef
extends GameDef
## A Memory Fragment (30 total: Core, Hidden, Deep).

enum Kind { CORE, HIDDEN, DEEP }

@export var name_key: String = ""
@export var journal_key: String = ""
@export var location_id: String = ""
@export var fragment_kind: Kind = Kind.CORE
## Optional first-person flashback scene (10-30 s).
@export_file("*.tscn") var flashback_scene: String = ""

func kind() -> String:
	return "fragment"

func validate() -> Array[String]:
	var errors := super.validate()
	if not IdRules.is_valid("location", location_id):
		errors.append("%s: location_id '%s' is not a location id" % [id, location_id])
	return errors
