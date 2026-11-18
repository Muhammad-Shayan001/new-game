# Project Folder Structure

```
afterlife/
├── project.godot            Engine config, autoload list, display (landscape), mobile renderer
├── scenes/
│   ├── game_root.tscn       Persistent gameplay root: World + Player + HUD + overlays
│   ├── characters/          player.tscn, camera_rig.tscn (future: npc scenes)
│   ├── world/               graybox_location.tscn (generator), test_arena.tscn, hand-built locations
│   ├── ui/                  title_screen, hud, dialogue_box, pause_menu, document_reader, puzzle_panel
│   └── cinematics/          (reserved: AnimationPlayer-driven cutscenes)
├── scripts/
│   ├── systems/             Autoload services + shared libraries (event bus, data registry, save, input...)
│   ├── player/              player_controller, camera_rig, player_animator, interactor, placeholder_visual
│   ├── world/               location_root, graybox_location, location_portal, mechanism, camera_zone, game_root
│   ├── missions/            mission_manager
│   ├── dialogue/            dialogue_manager
│   ├── puzzles/             puzzle_manager
│   ├── abilities/           ability_manager + ability scripts (one per ability)
│   ├── ui/                  screen scripts; ui/components/ = reusable touch widgets
│   ├── network/             network_manager (optional co-op)
│   └── editor/              (reserved: editor plugins / tools)
├── resources/               ALL game data as JSON (see DATA_SCHEMA.md)
│   ├── characters/ items/ abilities/ puzzles/ interactions/ dialogue/
│   ├── locations/  (generated, one file per region)   missions/ fragments/ (generated)
│   ├── localization/        en.json, en_world.json (generated), en_dev.json, ur.json
│   ├── audio/               audio_registry.json (sound id -> file)
│   └── dev/                 developer-only content (test arena); loaded only in debug builds
├── assets/                  models/ textures/ audio/ ui/   (binary art; .gitkeep until art lands)
├── tests/
│   ├── run_tests.gd         headless runner
│   ├── test_case.gd         assertions + gameplay helpers (walk_to, press, place_near ...)
│   └── cases/               test_*.gd suites
├── tools/
│   ├── world_data.py        world source of truth + validator
│   └── build_content.py     generates locations/missions/fragments/en_world from world_data
├── docs/                    design + technical documents (rendered by index.html)
└── .github/workflows/       CI (runs the test suite)
```

## Adaptations from the suggested layout (with reasons)
| Suggested | Used | Reason |
|---|---|---|
| `documentation/` | `docs/` | The documentation site (`index.html`) and all cross-links already use `docs/`; renaming would break them. |
| `resources/*.tres` | `resources/*.json` | JSON is diffable, generated from world data, editable by non-programmers, and testable headless. Typed access goes through `DataRegistry` schemas. Godot `Resource` classes can be added later for editor-authored data. |
| – | `scripts/world/`, `scripts/ui/`, `scripts/network/` | Keeps location/world logic and UI out of `systems/`. |
| – | `resources/dev/` | Test content without shipping it (loaded only if `OS.is_debug_build()`). |
| – | `tools/` | Content generation and validation scripts. |

## Ownership rules
- A folder owns one concern; scripts never reach across into another feature's folder for data, they ask a manager.
- **Generated files** (`resources/locations`, `resources/missions`, `resources/fragments`, `resources/localization/en_world.json`, `docs/WORLD_MAP.md`, `docs/LOCATION_REGISTER.md`, `docs/LEVEL_FLOW_DIAGRAMS.md`) are never edited by hand: change `tools/world_data.py` and run `python3 tools/build_content.py`. CI fails if the generated files are stale.
