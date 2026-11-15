class_name GameDef
extends Resource
## Base class of every data-driven definition stored under resources/.
## DataRegistry indexes definitions by `id`.

@export var id: String = ""

## Override: which IdRules kind this definition uses ("mission", "item", ...).
func kind() -> String:
	return ""

## Override and extend: return human-readable error strings (empty = valid).
func validate() -> Array[String]:
	var errors: Array[String] = []
	if not IdRules.is_valid(kind(), id):
		errors.append("%s: id '%s' does not match the %s ID format" % [kind(), id, kind()])
	return errors
