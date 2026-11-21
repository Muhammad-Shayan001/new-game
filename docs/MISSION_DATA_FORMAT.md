# Mission Data Format

A mission is one `MissionDef` resource: `resources/missions/<id lower>.tres`, id `CH<1-6>_M<nn>` (main) or `CH<1-6>_S<nn>` (optional). 31 missions exist; the 5 chapter-1 and chapter-2 samples plus the chapter-3 ability missions are hand-authored (`authored = true`), the rest are generated skeletons. Create new ones with `content_tool new-mission`.

## States
```
LOCKED -> AVAILABLE -> ACTIVE -> COMPLETE
                         |
                         +-> FAILED -> (recover) -> ACTIVE
```
- LOCKED -> AVAILABLE: `GameState.chapter >= chapter` and the `unlock` ConditionSet is met.
- AVAILABLE -> ACTIVE: automatically (`auto_start`) or by `MissionManager.start_mission(id)` (an Interactable `start_mission` field, dialogue, trigger).
- ACTIVE -> COMPLETE: every required objective is done.
- ACTIVE -> FAILED: a flag in `fail_flags` becomes true. Failure is soft: progress and checkpoint are kept and the player is told gently.
- FAILED -> ACTIVE: `MissionManager.recover_mission(id)`. Fail flags are cleared, the player returns to the last checkpoint (or `respawn_location`), objectives done before the checkpoint stay done.

## Fields
| Field | Meaning |
|---|---|
| `mission_type` | MAIN or OPTIONAL. A chapter ends when all its MAIN missions are complete. |
| `chapter` | 1 to 6 |
| `title_key`, `summary_key` | translation keys |
| `locations` | location ids, story order |
| `unlock` | extra ConditionSet (previous mission, ability, flag, state) |
| `auto_start` | start when AVAILABLE (default true) |
| `start_flags` | flags set when the mission starts |
| `objectives` | `Array[ObjectiveDef]` (below) |
| `complete_flags` | flags set on completion |
| `complete_states` | story states set on completion, e.g. `{"maya_trust": 1}` |
| `reward_fragments`, `reward_items`, `reward_clues`, `reward_abilities`, `reward_info` | granted on completion |
| `fail_flags`, `fail_dialogue` | soft failure trigger and an optional line |
| `respawn_location`, `respawn_spawn` | checkpoint used when no objective checkpoint exists |
| `completion_dialogue` | dialogue started after completion |
| `authored` | false = generated skeleton |

## Objectives (`ObjectiveDef`)
| Field | Meaning |
|---|---|
| `id` | local snake_case id |
| `text_key` | HUD text |
| `objective_kind` | REACH_LOCATION, FLAG, FRAGMENT, ITEM, CLUE, INTERACT, PUZZLE, DIALOGUE, TRACE, ECHO, SHIFT, INFO |
| `target` | id of that kind (location, flag, fragment, item, clue, interactable, puzzle, dialogue, `TRC_` trace, `ECH_` echo, `SHF_` zone, `INFO_`) |
| `value` | SHIFT only: the zone state to reach |
| `count` | how many times (items, repeated interactions) |
| `optional` | never blocks completion |
| `conditions` | conditional objective: only required and shown while met |
| `group` | alternative routes: of all required objectives sharing a group, one is enough |

Objectives that are already true when the mission starts count immediately. Each time an objective reaches its count, a checkpoint (location and spawn) is stored.

## Events that advance objectives
`scene_transition_finished` (REACH_LOCATION), `interaction_completed` (INTERACT), `fragment_collected`, `item_added` (adds the count), `clue_added`, `puzzle_solved`, `dialogue_finished`, `trace_discovered`, `echo_finished`, `info_revealed`, `shift_state_changed` (SHIFT), `GameState.flag_changed` (FLAG).

## Example
```
CH3_M02  Shift Anchors (MAIN, chapter 3)
  unlock:      missions_complete [CH3_M01]
  objectives:  reach LOC_DL_ANCHOR_FIELDS
               SHIFT  SHF_CH3_ANCHOR_BRIDGE -> other_side
               PUZZLE PZL_CH3_ANCHOR_BRIDGE
  rewards:     fragment CH3_F01
  respawn:     LOC_DL_ANCHOR_FIELDS
```

## Managers
| Manager | Role |
|---|---|
| `MissionManager` | state machine, rewards, failure, recovery, chapter progression |
| `ObjectiveManager` | counters, conditional and grouped objectives, checkpoints |
| `StoryState` | registered story variables (see `STORY_STATE_REGISTRY.md`) |
| `ProgressionManager` | memories, abilities, locations, character info, choices, optional discoveries, ending |

## Test missions
`tests/fixtures/mission_fixtures.gd` registers five missions at runtime (never saved to `resources/`): `CH6_S90/S91` (chain), `CH6_S92` (failure and recovery), `CH6_S93` (conditional and alternative-route objectives), `CH6_S94` (story states and rewards). `tests/unit/test_story_progression.gd` proves the completion gate: a mission starts, updates, completes, saves its progress, and unlocks the next one.
