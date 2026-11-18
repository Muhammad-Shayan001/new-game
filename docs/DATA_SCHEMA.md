# Data Schema (v1.0)

All content is JSON under `res://resources/<kind>/`. A file contains either **one definition** (an object with `id`) or **many** (`{"entries": [ ... ]}`). `DataRegistry` loads everything at startup, validates required fields and types, rejects duplicates, and exposes errors (`DataRegistry.errors`). The test suite fails if any file is invalid or any cross-reference is broken.

## Unique IDs
| Kind | Pattern | Example |
|---|---|---|
| Location | `LOC_<REGION>_<NAME>` (`HID` = hidden) | `LOC_EC_ARCHIVE_TOWER` |
| Mission | `CH#_M##` main, `CH#_S##` secondary | `CH3_M02` |
| Fragment | `CH#_F##` | `CH2_F05` |
| Item | `ITEM_<NAME>` | `ITEM_ARCHIVE_CARD` |
| Ability | `ABL_<NAME>` | `ABL_REALITY_SHIFT` |
| Puzzle | `PZL_<REGION>_##` | `PZL_EC_01` |
| Interaction | `INT_<REGION>_<NAME>` | `INT_EC_ARCHIVIST` |
| Dialogue | `DLG_CH#_<NAME>` | `DLG_CH1_CATALOGUE` |
| Dialogue node | `CH#_<SPEAKER>_###` | `CH1_ARV_001` |
| Character | 3 letters | `ALX MAY ARV ARC FCH` |
| Localization key | `<namespace>.<ID or name>` | `loc.LOC_EC_PARK`, `dlg.CH1_ARV_001`, `prompt.talk` |
| Flag | `snake_case` (system-generated: `seen:<dlg>`, `read:<int>`, `consumed:<int>`) | `maya_trust`, `found_child_drawing` |

IDs are permanent: they appear in saves. Renaming an ID requires a save migration.

## Kinds

### locations (generated from `tools/world_data.py`)
`id, name_key, region, type (exterior|interior|street|platform|tunnel), chapter, safe, hidden, connections[{to, route (main|optional|hidden|transition), gate_chapter}]`, optional `scene` (path to a hand-built scene; otherwise the graybox is generated).

### missions (generated for the campaign; hand-written for extras)
```
id, name_key, chapter, type ("Main"|"Secondary"), location, priority (int, optional),
unlock_requires: Condition, auto_start (bool),
objectives: [{ id, text_key, args_keys:{placeholder: loc_key}, optional (bool),
               complete_when: { event, arg } | { condition: Condition } }],
on_start: [Effect], on_complete: [Effect]
```
Objective events: `location_entered`, `interacted`, `item_added`, `fragment_collected`, `dialogue_finished`, `puzzle_solved`, `flag_set`. States: `LOCKED → AVAILABLE → ACTIVE → COMPLETE`.

### dialogue
```
id, start, once (bool), requires: Condition, scene, location,
nodes: { <node_id>: { speaker (character id), text_key, next,
                       effects: [Effect],
                       choices: [{ text_key, requires: Condition, effects: [Effect], next }],
                       branch: [{ if: Condition, next }] } }
```
A node without `text_key` is silent (effects/branch only). Choices whose `requires` fails are hidden.

### interactions
```
id, type (npc|phone|door|note|document|computer|puzzle|memory|mechanism|pickup|generic),
location, position [x,y,z]      (graybox placement; hand-built scenes use the node's transform)
prompt_key, locked_key, requires: Condition, visible_if: Condition, hide_when: Condition,
one_shot (bool), hold_time (seconds), effects: [Effect],
type fields: dialogue_id | puzzle_id | fragment_id | item_id | title_key+text_key | target_location+spawn | state_flag
```
The interaction ID is the SAME ID used by mission objectives (`event: interacted`).

### puzzles
`id, type (sequence|set|code), solution[], options[{id,label_key}], title_key, hints[loc keys (tiered)], on_solved:[Effect]`.

### items
`id, name_key, desc_key, kind (clue|key|memory|tool), stackable`.

### abilities
`id, name_key, slot (1-4), duration, cooldown, script (res:// path to an AbilityBase subclass), context_group`.

### fragments (generated)
`id, name_key, location, kind (Core|Hidden|Deep), chapter, on_collect:[Effect]`.

### characters
`id, name_key, role`.

## Conditions
Dictionary, all keys must pass; `{}` always passes; unknown keys fail closed (and log).
`all:[..] any:[..] not:{..} flag:"f" flag_equals:["f",v] chapter_gte:n rel_gte:["k",n] rel_lte:["k",n] mission:["ID","STATE"] has_item:"ID" has_fragment:"ID" deep_fragments_gte:n visited:"LOC" ability:"ID" puzzle_solved:"ID"`

## Effects
`{"do": op, ...}` with ops: `set_flag{flag,value} adjust_rel{key,delta} set_chapter{value} add_item{id,count} remove_item{id,count} collect_fragment{id} unlock_ability{id} start_dialogue{id} start_mission{id} complete_objective{mission,objective} goto_location{id,spawn} play_sfx{id} play_music{id} solve_puzzle{id} toast{key} autosave log_decision{id,text_key}`.

## Save data (schema version 2)
```
{ "schema_version": 2, "game_version": "0.1.0", "saved_at": <unix>, "slot": n,
  "summary": { chapter, location, playtime_seconds },
  "systems": { "game_state": {chapter, flags, relationships, decisions, current_location, visited_locations, playtime_seconds},
               "inventory": {items}, "memory": {collected}, "puzzles": {solved, hints_used},
               "abilities": {unlocked}, "missions": {states, objectives_done} } }
```
Slots: 0 autosave, 1-3 manual. Files: `user://saves/slot_N.json` (+ `.bak` of the previous save, written atomically via `.tmp`).
- **Providers:** any system with `save_data() / load_data(d) / reset_data()` registers with `SaveManager.register_provider(key, self)`; no SaveManager edit needed.
- **Compatibility:** a save with a *newer* schema is refused. Older schemas are upgraded by `SaveManager.migrate` one step at a time (`_migrate_N_to_N+1`); v1 → v2 is implemented and tested. Unknown system keys are ignored with a warning; missing systems reset to defaults. Never delete a field a migration still needs.
- **Content changes:** removing a mission/item/location ID that old saves reference is safe (ignored on load); renaming one needs a migration.

## Settings (`user://settings.cfg`, separate from saves)
`master/music/sfx/voice/ambient_volume, language, subtitles, text_scale, camera_sensitivity, invert_y, left_handed, reduced_motion, quality, touch_controls (auto|on|off), sprint_toggle, memory_pulse, hint_tier_max, interaction_assist`.

## Localization
Flat JSON `{key: text}`; files named `<lang>*.json` merge. Placeholders use `{name}`. Lookup order: current language → English → the key itself (logged once). Languages: `en`, `ur` (RTL; requires a font with Arabic glyphs, Godot falls back to system fonts).
