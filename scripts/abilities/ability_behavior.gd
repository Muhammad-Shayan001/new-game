class_name AbilityBehavior
extends Node
## Base class for ability effects. AbilityManager owns timing; behaviors only
## apply and remove the effect. Behaviors must not touch GameState directly.

var def: AbilityDef

func can_activate() -> bool:
	return true

func activate() -> void:
	pass

func deactivate() -> void:
	pass
