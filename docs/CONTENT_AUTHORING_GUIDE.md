# Content Authoring Guide: add content without touching code

Every recipe below is covered by `tests/cases/test_extensibility.gd`. After editing, run the tests (TESTING_AND_RUN_GUIDE.md §C); they will tell you about broken references and missing localization keys.

## Add a character
1. `resources/characters/GRD.json`: `{"id":"GRD","name_key":"char.GRD","role":"npc"}`
2. `resources/localization/en.json`: `"char.GRD": "Guard"`
3. Use `"speaker":"GRD"` in dialogue nodes. (Scenes: an NPC is an `npc` interaction; a visual model can be added to the location scene later.)

## Add an item
`resources/items/ITEM_RED_KEY.json` → `{"id":"ITEM_RED_KEY","name_key":"item.ITEM_RED_KEY","kind":"key","stackable":false}` + strings. Grant with the effect `{"do":"add_item","id":"ITEM_RED_KEY"}`; require with `{"has_item":"ITEM_RED_KEY"}`.

## Add a puzzle
`resources/puzzles/PZL_EC_09.json`: `type` = `sequence` / `set` / `code`, `solution`, `options` (for the UI), `hints` (localization keys), `on_solved` (effects, e.g. grant the key). Attach it to an object with an interaction of type `computer` or `puzzle` and `"puzzle_id"`.

## Add dialogue
`resources/dialogue/DLG_CH2_GUARD.json`: nodes with `speaker`, `text_key`, `next`, optional `choices` (with `requires`/`effects`) and `branch`. Text goes in `en.json` under `dlg.<NODE_ID>`. Attach to an NPC interaction (`"dialogue_id"`) or start it from any effect (`{"do":"start_dialogue","id":"DLG_..."}`).

## Add an interaction (door, note, lever, phone, memory object...)
`resources/interactions/INT_EC_GATE.json`: `id`, `type`, `location`, `position`, plus the type's fields (see DATA_SCHEMA.md). Use `requires` + `locked_key` for locked things, `visible_if` / `hide_when` to show/hide by state, `effects` for rewards. The same ID can be used as a mission objective (`{"event":"interacted","arg":"INT_EC_GATE"}`).
In a hand-built scene: add an `Interactable` node, set `interaction_id`; add a `Mechanism` node (set `watch_flag`) for something that physically opens.

## Add a mission
`resources/missions/CH2_extra.json` (hand-written missions live beside the generated `CH#.json`; never edit generated files): `id`, `name_key`, `chapter`, `type`, `location`, `unlock_requires` (Condition), `objectives` (events or conditions), `on_complete` (effects). HUD, saves and unlocks work automatically.

## Add a location
**Campaign location:** add a row to `L` and its edges to `E` in `tools/world_data.py`, give it missions/fragments if needed, run `python3 tools/build_content.py` (validates reachability and regenerates JSON + docs). It is immediately playable as a graybox with portals, fragment pickups and any interactions whose `"location"` matches.
**Hand-built scene:** create `scenes/world/<name>.tscn` whose root script extends `LocationRoot`, add `Marker3D` spawns in group `spawn` (`default`, `from_<LOC_ID>`), then set `"scene"` in the location's JSON entry (generated entries: add an override in `build_content.py`).
**Quick/dev location:** one JSON file in `resources/locations/` (or `resources/dev/locations/`).

## Add an ability
JSON in `resources/abilities/` + a script extending `AbilityBase` (`on_activate`, `on_tick`, `on_end`). Targets opt in by joining the ability's `context_group`.

## Add a language
`resources/localization/<lang>.json` + add the code to `Loc.LANGUAGES` (and `RTL_LANGUAGES` if needed).

## Checklist before committing
1. Tests green. 2. `python3 tools/build_content.py` leaves no diff. 3. New player-facing text is in `en.json`. 4. New IDs follow DATA_SCHEMA.md patterns.
