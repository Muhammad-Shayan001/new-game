# Test Documentation (Prompts 08 and 09)

## Automated tests
Run all: `godot --headless --path . res://tests/test_runner.tscn` (exit code 0 = pass). One suite: add `-- test_prototypes`. Current result: **133 tests, 0 failed**. The runner awaits `after_each()` so a finished scene can never leak into the next test.

| Suite | Tests | Covers |
|---|---|---|
| `test_core` | 9 | ids, registry, validation, conditions, state round trip |
| `test_save` | 10 | save, backup, tamper, versions, v1 and v2 migration, slots |
| `test_missions` | 8 | mission events, rewards, counted objectives, chapter flow |
| `test_dialogue` | 7 | dialogue, choices, conditions, info reveal |
| `test_collections` | 10 | inventory, clues, fragments, puzzles, hints, abilities |
| `test_world` | 12 | scene router, placeholder doors, interactables, NPCs |
| `test_platform` | 13 | settings, input, networking |
| `test_content_gate` | 1 | add location, character, dialogue, puzzle, mission with data only |
| `test_game_root` | 8 | boot, walking, doors, pause, respawn, camera override, continue |
| `test_story_progression` | 16 | story-state registry, chains, failure and recovery, conditional and grouped objectives, rewards, progression, ending, real chapter 1 |
| `test_abilities_unit` | 30 | Memory Vision, Echo Detection, Reality Shift, Time Echo, puzzle framework, components |
| `test_prototypes` | 9 | playthroughs of the three puzzle scenes with real physics |

## Prompt 08 completion gate: evidence
| Requirement | Test |
|---|---|
| Every ability used in a real gameplay situation | `test_clock_room_uses_memory_sight_pulse_logic_and_sequence`, `test_anchor_fields_use_reality_shift_to_cross_and_exit`, `test_gallery_time_echo_replay_then_memory_reconstruction`, `test_gallery_plates_are_solved_alone_with_an_echo_ghost`, `test_every_ability_is_used_in_a_real_gameplay_situation` |
| Each prototype has a clear solution and completion state | the same playthroughs assert `PuzzleManager.is_solved(...)`, the set flags and the rewards |
| Visual state changes, hidden visibility, clue discovery, cooldown, feedback | `test_hidden_object_visibility_and_interaction`, `test_found_writing_can_stay_visible`, `test_ability_feedback_hud_and_rules`, `test_memory_trace_records_an_optional_discovery` |
| Reality Shift: configurations, routes, clues, dependencies, safe transitions, saving | `test_shiftable_objects_follow_the_zone_and_the_save`, `test_conditions_can_require_a_shift_state`, `test_reality_shift_moves_the_player_out_of_a_new_solid_object`, `test_reality_shift_zone_state_is_restored_from_a_save`, `test_only_one_zone_away_from_default` |
| Time Echo: timeline, playback, camera, audio, clues | `test_echo_playback_captions_clues_and_cleanup`, `test_echo_conditions_and_single_view`, `test_recording_creates_a_ghost_that_replays_and_stays` |
| Echo Detection visual and audio feedback | `test_pulse_points_to_the_nearest_undiscovered_trace`, `test_echo_detection_feedback_text_is_readable_without_sound` |
| Puzzle definitions complete, varied, accessible, resettable, saved | `test_every_puzzle_definition_is_complete`, `test_puzzle_variety`, `test_manual_reset_and_leave_reset`, `test_puzzle_progress_is_saved_when_the_definition_says_so`, `test_skip_puzzle_accessibility_option` |

## Prompt 09 completion gate: evidence
`test_mission_chain_start_update_complete_save_unlock` (a mission starts, updates, completes, saves its progress mid-way, reloads, completes, and unlocks the next one), `test_failure_is_soft_and_recoverable_from_checkpoint`, `test_alternative_routes_and_conditional_objectives`, `test_completion_applies_states_rewards_and_info`, `test_real_chapter_one_is_playable_to_the_end`, `test_registry_knows_canon_states`, `test_progression_snapshot_tracks_everything`, `test_ending_resolution_follows_the_ending_design`.

## Manual test script (editor, about 15 minutes)
Prepare: there is no debug console yet. Either play the missions (`CH1_M02` grants Memory Sight, `CH3_M01` grants Reality Shift and Time Echo; every location is reachable through placeholder doors), or temporarily add `AbilityManager.unlock("ABIL_MEMORY_SIGHT")` (and the other two ids) to `GameRoot.start_new_game()` while testing, and remove it afterwards.

1. **Clock room.** Go to the Clock Room. Nothing is visible. Hold the pulse button (F): text says how close and which way. Press 1: screen tints, writing and the note appear. Examine the writing. Examine the note. Visit Echo Station and examine the clock first if you did not. At the clue board press E: the dial unlocks. Press 4, 1, 7. Expect "Solved" and a fragment.
2. **Anchor Fields.** Stand on Anchor A, press 2: a bridge appears. Cross, examine the sigil, stand on Anchor B, press 2: the bridge vanishes and the gate opens. Use the exit. Press 2 away from an anchor: "needs a Shift Anchor".
3. **Echo Gallery.** At the Echo Site press 3: a replay with captions and a moving camera. Press E during it to skip. Place the cards in order circle, square, triangle. In the record zone press 3, run to plate A, press 3 again, then stand on plate B for a second.
4. **Accessibility.** Settings: reduce motion (no fades), ability duration scale 2.0, echo audio off (text still shows the direction), puzzle skip on (after three hints a puzzle can be skipped).
5. **Save.** Shift the bridge, save, quit, continue: the bridge is still there. Fail a mission (not in the shipped content; use the fixtures), recover.

## Known gaps
Not tested on a device or in the editor window. Audio cues have no streams yet (they log one warning). Visuals are graybox. Echo Voice is a stub.
