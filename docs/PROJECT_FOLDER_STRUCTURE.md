# Project Folder Structure

```
new-game/
+- project.godot                Autoloads, input-free config, translations, layer names
+- README.md
+- index.html, .nojekyll        GitHub Pages docs site (reads docs/*.md)
+- scenes/
|  +- game_root.tscn            Main scene (composition root)
|  +- camera_rig.tscn           Orbit camera
|  +- characters/               player.tscn, npc_base.tscn
|  +- world/                    placeholder_location.tscn, <region>/<location>.tscn
|  |   +- underground_metro/    echo_station.tscn (graybox)
|  +- ui/                       dialogue_box, interaction_prompt, mission_tracker,
|  |                            toast_area, touch_controls, pause_menu, fade_overlay
|  +- cinematics/               (empty: cutscene scenes will live here)
+- scripts/
|  +- autoload/                 core services: event_bus, game_state, data_registry,
|  |                            input_service, audio_manager, settings_manager,
|  |                            save_manager, scene_router, network_manager
|  +- player/                   player, camera_rig, interaction_sensor
|  +- characters/               npc_actor
|  +- world/                    location_root, spawn_point, interactable, placeholder_location, prototype_location,
|  |                            shift_anchor, shiftable_object, echo_site, pressure_plate, plate_controller,
|  |                            clue_board, reconstruction_board, condition_gate
|  +- missions/                 mission_def, objective_def, mission_manager
|  +- dialogue/                 dialogue_def, dialogue_node, dialogue_choice, dialogue_manager
|  +- puzzles/                  puzzle_def, puzzle_runtime, pattern/ordering runtimes, puzzle_manager
|  +- abilities/                ability_def, ability_behavior, ability_manager, behaviors, shift_manager,
|  |                            echo_detection, revealable, memory_trace
|  +- story/                    story_state_def, story_state, info_def, shift_zone_def
|  +- echo/                     time_echo_def (+ key/track/camera/audio/caption/clue classes), echo_ghost, time_echo_manager
|  +- data/                     shared definitions: game_def, condition_set, location_def,
|  |                            location_connection, fragment_def, item_def, character_def,
|  |                            audio_cue_def, deduction_def
|  +- systems/                  inventory_manager, memory_manager, localization, input_actions,
|  |                            id_rules, game_log, game_version, location_ids (generated)
|  +- ui/                       HUD and touch control scripts
|  +- game_root.gd
+- resources/                   data-driven content, one .tres per id (file name = lower-case id)
|  +- locations/ missions/ fragments/ dialogue/ items/ abilities/
|  +- puzzles/ characters/ audio/ deductions/
|  +- story_states/ info/ shift_zones/ echoes/
+- assets/
|  +- models/ textures/ audio/  imported art and sound (empty so far)
+- localization/                en_ui.po, en_world.po (generated), en_content.po
+- tests/
|  +- test_runner.tscn/.gd, test_case.gd
|  +- unit/                     test_*.gd (133 tests)
|  +- fixtures/                 mission_fixtures.gd (test missions)
+- tools/
|  +- world_data.py             world data source of truth + validator + generators
|  +- content_tool.gd/.tscn     generate-world, bootstrap-samples, bootstrap-story, build-scenes, new-*, validate
|  +- story_content.gd          authored story states, info, puzzles, echoes, missions
|  +- scene_builder.gd          builds the three graybox puzzle scenes
|  +- generated/world_data.json
+- docs/                        all design and technical documents
```

## Documented adaptations of the suggested structure
| Suggested | Used | Reason |
|---|---|---|
| `documentation/` | `docs/` | GitHub Pages and `index.html` already serve `docs/`; moving it would break the site |
| `scripts/player`, `systems`, `missions`, `dialogue`, `puzzles`, `abilities` | same, plus `autoload/`, `data/`, `world/`, `characters/`, `ui/` | shared definitions, scene helpers, NPCs and HUD each got a clear home; autoload entry points that are core services stay in `autoload/` |
| `resources/missions, dialogue, items` | same, plus `locations, fragments, abilities, puzzles, characters, audio, deductions` | every data kind has its own folder so the registry can validate folder against kind |
| (none) | `localization/` | translation files must be separate from code and assets |
| (none) | `tools/` | generators and the content pipeline |
| (none) | `scenes/camera_rig.tscn`, `scenes/game_root.tscn` | persistent scenes that are not part of any location |

## Where things go
| You are adding... | Put it in |
|---|---|
| A level | `scenes/world/<region_folder>/<name>.tscn` (root script extends `LocationRoot`) and set the `LocationDef` status and `scene_path` |
| A 3D model or texture | `assets/models/`, `assets/textures/` |
| A sound or music | `assets/audio/` and an `AudioCueDef` in `resources/audio/` |
| A new character | `resources/characters/` + dialogue + instance of `npc_base.tscn` |
| A story text | `localization/en_content.po` |
| A new system | `scripts/systems/` (service) or its own domain folder; register in `project.godot` only if it must be global |
| A test | `tests/unit/test_<area>.gd` |
