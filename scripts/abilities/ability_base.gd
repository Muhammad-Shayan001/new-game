class_name AbilityBase
extends RefCounted
## Base class for supernatural abilities. Subclasses override the hooks.
## Abilities are instantiated from def["script"] by AbilityManager; they hold no global state.

var def: Dictionary = {}
var tree: SceneTree

func setup(ability_def: Dictionary, scene_tree: SceneTree) -> void:
	def = ability_def
	tree = scene_tree

func on_activate() -> void:
	pass

func on_tick(_delta: float) -> void:
	pass

func on_end() -> void:
	pass
