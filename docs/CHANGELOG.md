# Changelog
## 0.1.0 — Technical architecture (Prompt 04)
- New: EventBus, DataRegistry, InputService, AudioManager, SettingsManager, SceneRouter, InventoryManager, MemoryManager, AbilityManager, PuzzleManager, DialogueManager, MissionManager, NetworkManager.
- GameState now saves missions, inventory, abilities, puzzles, relationships, decisions, deductions, playtime. SaveManager rewritten: 4 slots, atomic write, backup, SHA-256 checksum, version checks, v1 -> v2 migration.
- Data-driven definitions (`GameDef` resources) for missions, dialogue, items, puzzles, abilities, locations, fragments, characters, audio, deductions; `ConditionSet` rule object; ID rules; `DataRegistry.validate_all()`.
- Scenes: `game_root.tscn` replaces `main.tscn`; player, camera rig, NPC base, placeholder location, Echo Station graybox, HUD scenes, touch controls.
- Input moved into `InputService`/`InputActions` (input map is defined in code). `TouchJoystick` no longer talks to the player.
- Localization via `.po` files; `tools/world_data.py` now also writes `localization/en_world.po` and `tools/generated/world_data.json`.
- `tools/content_tool.gd`: generate 47 locations, 30 fragments, 31 mission skeletons; scaffold new content; validate.
- 77 headless tests (`tests/`). Docs: TECHNICAL_DESIGN_DOCUMENT, PROJECT_ARCHITECTURE, DATA_SCHEMA, CODING_STANDARDS, PROJECT_FOLDER_STRUCTURE.
## 0.0.3 — World and level design
- Added WORLD_BIBLE, WORLD_MAP, LEVEL_DESIGN_DOCUMENT, LOCATION_REGISTER, ENVIRONMENT_ASSET_LIST, LEVEL_FLOW_DIAGRAMS.
- Added `tools/world_data.py` (single source of truth + validator) and `scripts/systems/location_ids.gd`.
- GameState now saves `current_location` and `visited_locations`.
- Added region The Core (CR) for Chapter 6; added optional missions CH3_S03, CH4_S03; Chapter 1 now starts at LOC_UM_ECHO_STATION.
## 0.0.2 — Design + story pass
- Added GDD v1.0, gameplay systems, mission template, progression, flowchart.
- Added story bible, character bible, chapter outlines, dialogue sample, timeline, endings, cinematic script.
- Canon decisions: Wren Morgan is Alex's sister; Architect is Dr. Elias Morgan (father); Archivist is the Index's conscience; Maya Reed is a paramedic in the living world.
## 0.0.1 — Scaffold
- Project config, GameState, SaveManager, Player controller, touch joystick, graybox scene, doc set.
