# Data Schema

Schema version: **1** (`GameVersion.DATA_SCHEMA_VERSION`). Save version: **2**. Settings version: **1**.

## 1. Unique IDs

| Kind | Format | Example | Folder / file name |
|---|---|---|---|
| Location | `LOC_<REGION2>_<NAME>` | `LOC_UM_ECHO_STATION` | `resources/locations/loc_um_echo_station.tres` |
| Mission | `CH<1-6>_M<nn>` main, `CH<1-6>_S<nn>` optional | `CH1_M01`, `CH1_S02` | `resources/missions/ch1_m01.tres` |
| Memory fragment | `CH<1-6>_F<nn>` | `CH1_F01` | `resources/fragments/` |
| Dialogue | `DLG_<SCENE>` | `DLG_CH1_M03_CATALOGUE` | `resources/dialogue/` |
| Item | `ITEM_<NAME>` | `ITEM_ARCHIVE_CARD` | `resources/items/` |
| Clue | `CLUE_<NAME>` (no resource) | `CLUE_STATION_CLOCK` | stored in `GameState.clues` |
| Puzzle | `PZL_<NAME>` | `PZL_CH1_CLOCK_4_17` | `resources/puzzles/` |
| Ability | `ABIL_<NAME>` | `ABIL_MEMORY_SIGHT` | `resources/abilities/` |
| Character | 3 capital letters | `ALX`, `MAY`, `ARV`, `ARC`, `FCH` | `resources/characters/` |
| Audio cue | `AUD_<NAME>` | `AUD_STATION_AMBIENCE` | `resources/audio/` |
| Deduction | `DED_<NAME>` | `DED_TICKET_OWNER` | `resources/deductions/` |
| Interactable (scene node) | `INT_<LOCATION>_<NAME>` | `INT_UM_ECHO_STATION_CLOCK` | set on the node |
| Flag, spawn id, local node/objective id | `snake_case` | `ch1_started`, `default`, `reach_um_concourse` | — |

Rules:
- IDs never change after release (saves refer to them). Retire an id instead of reusing it.
- The file name is the lower-case id. `DataRegistry` reports a mismatch.
- The regular expressions live in `scripts/systems/id_rules.gd`.
- Locations, missions and fragments come from `tools/world_data.py` (single source of truth).

## 2. Resource types

All extend `GameDef` (field `id`, `kind()`, `validate()`).

### LocationDef
| Field | Type | Notes |
|---|---|---|
| name_key | String | translation key (equals the id) |
| region_id, location_type | String | e.g. `UM`, `platform` |
| first_chapter | int | |
| safe_point, hidden | bool | safe points = save and fast-travel nodes |
| status | PLANNED / GRAYBOX / BUILT | PLANNED uses the placeholder scene |
| scene_path | res:// path | `scenes/world/<region_folder>/<name>.tscn` |
| default_spawn | String | `default` |
| ambience_cue | audio id | optional |
| connections | Array[LocationConnection] | `to_location`, `route_type` (main/optional/hidden/transition), `gate_chapter`, `spawn_id`, `note` |

### MissionDef
| Field | Type | Notes |
|---|---|---|
| mission_type | MAIN / OPTIONAL | template word "Secondary" = OPTIONAL |
| chapter | 1-6 | |
| title_key, summary_key | String | |
| locations | Array[String] | location ids |
| unlock | ConditionSet | chapter is always required in addition |
| auto_start | bool | start when AVAILABLE |
| start_flags, complete_flags | Array[String] | |
| objectives | Array[ObjectiveDef] | at least one non-optional |
| reward_fragments / items / clues / abilities | Array[String] | |
| completion_dialogue | dialogue id | optional |
| respawn_location, respawn_spawn | String | checkpoint (no hard fail) |
| estimated_minutes | int | |
| authored | bool | false = generated skeleton |

### ObjectiveDef
`id` (local snake_case), `text_key`, `objective_kind` (REACH_LOCATION, FLAG, FRAGMENT, ITEM, CLUE, INTERACT, PUZZLE, DIALOGUE), `target` (id of that kind), `count` (default 1), `optional`.

### ConditionSet
`min_chapter`, `flags_all`, `flags_any`, `flags_none`, `missions_complete`, `items_all`, `clues_all`, `fragments_all`, `abilities_all`. An empty set is always met.

### DialogueDef / DialogueNode / DialogueChoice
- `DialogueDef`: `start_id`, `nodes`, `repeatable` (non-repeatable sets `dlg_done_<id>`).
- `DialogueNode`: `id` (snake_case), `speaker_id` (character id or empty), `text_key`, `next_id` (empty = end), `conditions`, `choices` (max 3), `set_flags`, `relationship_changes`, `voice_cue`.
- `DialogueChoice`: `text_key`, `next_id`, `conditions`, `set_flags`, `relationship_changes` (e.g. `{"maya_trust": 1}`), `log_choice`.

### ItemDef, FragmentDef, CharacterDef, AudioCueDef, DeductionDef, AbilityDef, PuzzleDef
| Type | Fields |
|---|---|
| ItemDef | name_key, description_key, stackable, max_stack, icon |
| FragmentDef | name_key, journal_key, location_id, fragment_kind (CORE/HIDDEN/DEEP), flashback_scene |
| CharacterDef | name_key, accent_color, scene_path, default_dialogue |
| AudioCueDef | category (MUSIC/SFX/AMBIENCE/VOICE), stream, volume_db, pitch_min/max, loop |
| DeductionDef | clue_a, clue_b, title_key, set_flags, result_clue |
| AbilityDef | name_key, description_key, unlock_chapter, input_slot (1-4), duration, cooldown, behavior (script) |
| PuzzleDef | puzzle_type, title_key, location_id, hint_keys (exactly 3), solution, set_flags, reward_clues/items/fragments |

## 3. Translation keys

| Text | Key |
|---|---|
| Location name | `LOC_...` (the id) |
| Mission title | `MISSION_<ID>_TITLE` |
| Objective text | `MISSION_<ID>_OBJ_<NAME>` |
| Fragment name | `FRAG_<ID>_NAME` |
| Character name | `CHR_<ID>_NAME` |
| Dialogue line | `<DIALOGUE_ID>_<NODE_ID_UPPER>`, choice `<DIALOGUE_ID>_CHOICE_<NAME>` |
| Item | `<ITEM_ID>_NAME`, `<ITEM_ID>_DESC` |
| Ability | `<ABIL_ID>_NAME`, `<ABIL_ID>_DESC` |
| Puzzle | `<PZL_ID>_TITLE`, `<PZL_ID>_HINT_1..3` |
| UI, prompts, toasts | `UI_...`, `PROMPT_...`, `TOAST_...` |

Files: `localization/en_ui.po` (hand-written), `en_world.po` (generated by `tools/world_data.py`; do not edit), `en_content.po` (hand-written; the content tool appends). Registered in `project.godot`.

## 4. Flags and relationships
- Flags are `snake_case`; values are `bool`, `int` or `String`.
- Reserved by the engine: `dlg_done_<dialogue_id>`, `int_done_<interactable_id>`, `deep_fragments` (count).
- Story decision flags from `GAMEPLAY_SYSTEMS.md`: `spared_forgotten`, `told_maya_truth`, `trusted_archivist`, `destroyed_index_node`, `kept_wren_memory`.
- Relationship keys: `maya_trust`, `archivist_trust`, `forgotten_mercy`, range -3..+3.

## 5. Save data

File: `user://saves/save_slot_<n>.json` (slot 0 = auto, 1-3 manual), plus `.bak` (previous save) and a short-lived `.tmp`.

```json
{
  "version": 2,
  "game_version": "0.1.0",
  "saved_at": 1763160000,
  "meta": { "chapter": 1, "location": "LOC_UM_ECHO_STATION", "playtime": 412 },
  "checksum": "<sha256 of state_json>",
  "state_json": "<the state below, as a JSON string with sorted keys>"
}
```

State (`GameState.to_dict()`):

| Key | Type | Meaning |
|---|---|---|
| chapter | int | 1-6 |
| flags | Dictionary | name -> bool/int/String |
| clues, memories, visited_locations, abilities, choices, deductions | Array[String] | ids |
| current_location, last_spawn_id | String | where to resume |
| mission_states | Dictionary | mission id -> 0 LOCKED, 1 AVAILABLE, 2 ACTIVE, 3 COMPLETE |
| mission_progress | Dictionary | mission id -> {objective id: count} |
| inventory | Dictionary | item id -> count |
| puzzles | Dictionary | puzzle id -> {"solved": bool, "hints": int} |
| relationships | Dictionary | key -> int |
| playtime_seconds | float | |

Not saved: player position inside a location (the player resumes at the last spawn point), camera, UI state, ability timers.

## 6. Version compatibility

| Situation | Behavior |
|---|---|
| Save version > game's `SAVE_VERSION` | Refused with a clear message; state untouched |
| Save version < `MIN_SUPPORTED_SAVE_VERSION` | Refused |
| Older supported version | Migrated step by step in `SaveManager._migrate()` |
| Missing keys | Defaults in `GameState.from_dict()` |
| Checksum mismatch or corrupt JSON | Falls back to `.bak`, else load fails (state untouched) |
| v1 legacy file (`{"version":1,"state":{}}`) | Accepted, migrated to v2 |

To change the save schema: add the field to `GameState` (`to_dict`, `from_dict`, default), bump `SAVE_VERSION`, add a migration case, add a test in `tests/unit/test_save.gd`, update section 5.

To remove or rename a content id: do not. Add a new id and keep the old one retired, or write a migration that rewrites it in the save.

## 7. Settings (`user://settings.cfg`)
| Section.key | Default | Range / values |
|---|---|---|
| audio.master / music / sfx / ambience / voice | 1.0 / 0.8 / 0.9 / 0.8 / 1.0 | 0.0-1.0 |
| video.quality | medium | low, medium, high |
| video.fov | 65 | 55-80 |
| video.fps_cap | 60 | 30, 60, 120 |
| controls.look_sensitivity | 1.0 | 0.25-3.0 |
| controls.invert_y, auto_interact, always_show_touch | false | bool |
| controls.touch_opacity | 0.6 | 0.2-1.0 |
| accessibility.subtitles | true | bool |
| accessibility.subtitle_size | 1.0 | 0.8-1.6 |
| accessibility.reduce_motion | false | bool |
| game.language | en | en |

Invalid or missing values fall back to the default. `meta/version` stores the settings version.

## 8. Generated versus authored files

| File | Owner | Regenerated? |
|---|---|---|
| `scripts/systems/location_ids.gd`, `docs/LOCATION_REGISTER.md`, `WORLD_MAP.md`, `LEVEL_FLOW_DIAGRAMS.md`, `localization/en_world.po`, `tools/generated/world_data.json` | `python3 tools/world_data.py` | yes, never edit by hand |
| `resources/locations/*`, `resources/fragments/*` | `content_tool generate-world` | updated in place; `status`, `scene_path`, `ambience_cue`, `flashback_scene` are preserved |
| `resources/missions/*` | `content_tool generate-world` creates skeletons | never overwritten; set `authored = true` when edited |
| everything else under `resources/` | hand-authored or `content_tool new-*` | no |

Pipeline after changing world data: `python3 tools/world_data.py`, then `godot --headless --path . --import`, then `godot --headless --path . res://tools/content_tool.tscn -- generate-world`, then `... -- validate`.
