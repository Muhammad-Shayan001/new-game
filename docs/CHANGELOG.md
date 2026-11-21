# Changelog
## 0.2.0 — Signature abilities, puzzle engine, quests and progression (Prompts 08 and 09)
- Abilities: Memory Vision (`Revealable`, `MemoryTrace`, HUD feedback), Echo Detection (pulse with visual, audio and haptic cues), Reality Shift (`ShiftManager`, `ShiftZoneDef`, anchors, shiftable objects, safe transitions, saved zone states), Time Echo (`TimeEchoManager`, `TimeEchoDef` replays with camera, audio, captions and clue moments; recording ghosts that hold plates). Echo Voice remains a stub.
- Puzzle framework: `PuzzleDef` now defines required abilities, initial state, completion rule, feedback, reset and save policy, accessibility notes and co-op. New types LOGIC and OBSERVATION. Progress saving, leave-reset, hint tiers, optional skip. Components: `ClueBoard`, `ReconstructionBoard`, `PressurePlate`, `PlateController`, `ConditionGate`, `EchoSite`, `ShiftAnchor`, `ShiftableObject`.
- Five prototype puzzles in three graybox scenes (`hid_clock_room`, `anchor_fields`, `echo_gallery`), built by `tools/scene_builder.gd`.
- Quests: `ObjectiveManager` (counted, optional, conditional and alternative-route objectives, checkpoints), `MissionManager` with soft failure (`FAILED`) and checkpoint recovery, `StoryState` registry (27 registered states, alias `maya_trust_level`), `ProgressionManager` (memories, abilities, locations, character info, choices, optional discoveries, completion, ending resolution).
- Save version 3 (shift states, traces, character info, echoes, mission checkpoints); v1 and v2 saves migrate.
- New settings: `ability_duration_scale`, `puzzle_skip`, `echo_audio_cues`, `echo_visual_cues`, `echo_haptics`.
- Content validation now rejects unregistered story flags, missing accessibility notes, bad shift zones, echoes and info.
- `Area3D.priority` clash: unchanged (`interact_priority`). Test runner now awaits `after_each()` (fixed a one-frame scene leak between tests).
- 133 headless tests (was 77). Docs: ABILITY_SYSTEM, PUZZLE_FRAMEWORK, PUZZLE_DESIGN_LIBRARY, PUZZLE_TEST_PLAN, MISSION_DATA_FORMAT, STORY_STATE_REGISTRY.

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
