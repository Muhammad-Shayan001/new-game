extends LocationRoot
## Stand-in for locations that have no scene yet (LocationDef.status == PLANNED).
## Shows the location name and builds a door for every open route, so the whole
## world graph can be walked and every mission tested before any art exists.

@onready var _label: Label3D = $Title

func setup(id: String, spawn: String) -> void:
	super.setup(id, spawn)
	var def := DataRegistry.get_location(id)
	_label.text = "%s\n(%s)" % [Localization.t(def.name_key), id] if def != null else id
	build_route_doors(9.0)
