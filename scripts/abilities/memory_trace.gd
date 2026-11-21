class_name MemoryTrace
extends Revealable
## An important memory trace: found with Echo Detection (pulse), made visible by Memory
## Sight, collected by interacting. Collecting records an optional discovery.
## Put one Interactable child (set interactable_path) with the clue/fragment effects.

@export var trace_id: String = ""

func _ready() -> void:
	super._ready()
	add_to_group("memory_traces")
	var interactable := get_node_or_null(interactable_path) as Interactable
	if interactable != null:
		interactable.interacted.connect(func(): ProgressionManager.discover_trace(trace_id))

func is_discovered() -> bool:
	return trace_id in GameState.discovered_traces
