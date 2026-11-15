extends Node
## Global signal hub. Systems talk through these signals and never hold direct
## references to each other. Conventions (see CODING_STANDARDS.md):
##  - past tense = something happened (mission_completed); *_requested = ask for work.
##  - payloads are IDs and primitives, never nodes (location_ready is the one exception).
##  - state OWNERS (GameState) keep their own signals; the bus carries gameplay events.

# Scene transitions
signal scene_transition_started(from_location: String, to_location: String)
signal scene_transition_finished(location_id: String)
signal scene_transition_failed(to_location: String, reason: String)
signal location_ready(location_id: String, root: Node)

# Input
signal input_device_changed(device: String) # "keyboard_mouse" | "gamepad" | "touch"
signal input_lock_changed(locked: bool)

# Interaction
signal interaction_prompt_changed(visible: bool, prompt_key: String)
signal interaction_hold_progress(ratio: float)
signal interaction_completed(interactable_id: String)

# Story progress
signal chapter_changed(chapter: int)
signal mission_state_changed(mission_id: String, state: int)
signal mission_objective_progress(mission_id: String, objective_id: String, current: int, required: int)
signal mission_completed(mission_id: String)

# Dialogue
signal dialogue_started(dialogue_id: String)
signal dialogue_line_shown(speaker_id: String, text_key: String)
signal dialogue_choices_presented(choices: Array) # Array of {"index": int, "text_key": String}
signal dialogue_finished(dialogue_id: String)

# Collections
signal item_added(item_id: String, count: int)
signal item_removed(item_id: String, count: int)
signal clue_added(clue_id: String)
signal deduction_made(deduction_id: String)
signal fragment_collected(fragment_id: String)

# Abilities and puzzles
signal ability_unlocked(ability_id: String)
signal ability_activated(ability_id: String)
signal ability_ended(ability_id: String)
signal puzzle_started(puzzle_id: String)
signal puzzle_hint_given(puzzle_id: String, tier: int, hint_key: String)
signal puzzle_attempt_failed(puzzle_id: String)
signal puzzle_solved(puzzle_id: String)

# Persistence and settings
signal autosave_requested(reason: String)
signal save_finished(slot: int, ok: bool)
signal load_finished(slot: int, ok: bool)
signal settings_changed(section: String, key: String, value: Variant)

# Cinematics (a CutsceneRunner listens; flashbacks and cinematics are scenes)
signal cutscene_requested(scene_path: String)

# UI
signal toast_requested(text_key: String, kind: String) # kind: info | reward | warning
signal pause_requested(paused: bool)

# Networking (optional co-op)
signal network_state_changed(state: int)
signal network_peer_joined(peer_id: int)
signal network_peer_left(peer_id: int)
