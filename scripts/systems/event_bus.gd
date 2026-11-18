extends Node
## Global signal hub. Systems never call each other for notifications; they emit here.
## Naming: <subject>_<past_tense_verb>. Payloads are IDs (String), never node references.

# Scene / world
signal scene_transition_started(location_id: String)
signal scene_transition_finished(location_id: String)
signal location_entered(location_id: String)
signal location_exited(location_id: String)

# State
signal flag_changed(flag: String, value: Variant)
signal relationship_changed(key: String, value: int)
signal chapter_changed(chapter: int)

# Content systems
signal item_added(item_id: String)
signal item_removed(item_id: String)
signal fragment_collected(fragment_id: String)
signal mission_state_changed(mission_id: String, state: String)
signal objective_completed(mission_id: String, objective_id: String)
signal dialogue_started(dialogue_id: String)
signal dialogue_line_shown(node_id: String, speaker_id: String, text: String)
signal dialogue_choices_shown(choices: Array)
signal dialogue_finished(dialogue_id: String)
signal puzzle_solved(puzzle_id: String)
signal puzzle_failed(puzzle_id: String)
signal puzzle_hint_given(puzzle_id: String, hint_key: String)
signal ability_unlocked(ability_id: String)
signal ability_activated(ability_id: String)
signal ability_ended(ability_id: String)
signal ability_cooldown_changed(ability_id: String, remaining: float)
signal interacted(interaction_id: String)

# UI
signal interaction_prompt_changed(prompt: String)
signal toast_requested(text: String)
signal pause_requested
signal document_requested(title_key: String, body_key: String)
signal puzzle_requested(puzzle_id: String)
signal interaction_hold_progress(ratio: float)

# Platform / services
signal settings_changed(key: String, value: Variant)
signal game_saved(slot: int)
signal game_loaded(slot: int)
signal input_device_changed(kind: String)
signal network_state_changed(state: String)
