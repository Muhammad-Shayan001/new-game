# Changelog
## 0.3.0 — Next-Gen Aesthetic, Kinetic Locomotion & Master Production Upgrade
- **Visual Direction & Shaders:**
  - Implemented `wet_road_rain.gdshader`: Procedural rain ripple normals, dynamic roughness inversion, wetness albedo darkening.
  - Implemented `reality_tear_glitch.gdshader`: Real-time post-processing chromatic aberration (RGB split), digital block displacement, analog CRT scanlines for Reality Shift transitions.
  - Implemented `memory_vision.gdshader`: Fullscreen luminance desaturation, cold charcoal vignette, electric vermilion anomaly pulsation.
  - Implemented `time_echo_hologram.gdshader`: Additive transparent spatial hologram with animated scan-bands, Fresnel rim glow, and digital jitter.
- **Cinematics & Smartphone UI Systems:**
  - `CutsceneRunner` (`scripts/cinematics/cutscene_runner.gd`): Decoupled cutscene lifecycle manager handling input locks, autosave prevention, and HUD toggling.
  - `OpeningSequence` (`scenes/cinematics/opening_sequence.tscn`, `scripts/cinematics/opening_sequence.gd`): 2.39:1 CinemaScope opening sequence with real-time text fades, haptic phone buzzes, and seamless control handoff.
  - `JournalPhone` (`scenes/ui/journal_phone.tscn`, `scripts/ui/journal_phone.gd`): Diegetic smartphone OS ("EchoOS v4.0") with real-time clue logs, restored memory fragments, character dossiers, and choice timeline.
- **Chapter 1 Live Playable Locations:**
  - `concourse.tscn`: Subway concourse featuring the Archivist NPC (`ARV`), interactive branching dialogue (`DLG_CH1_M03_CATALOGUE`), turnstile clue, and dual stair/escalator transitions.
  - `metro_entrance.tscn`: Surface canopy transition scene connecting the underground to the street with transit kiosk and sodium/neon lighting.
  - `alley.tscn`: Alleyway 04 featuring the procedural wet road PBR shader, shattered smartphone clue (`INT_EC_ALLEY_PHONE`), and wall memory trace (`INT_EC_ALLEY_TRACE`).
- **Main Menu & Title Flow (`scenes/ui/main_menu.tscn`, `scripts/ui/main_menu.gd`):**
  - High-contrast cyber-noir title screen with "CONTINUE", "NEW GAME", "SETTINGS", and "CREDITS".
  - Automated state detection disabling "CONTINUE" if no valid auto-save exists.
  - Full mobile viewport layout and seamless return-to-menu from `PauseMenu`.
  - Headless/test-runner bypass allowing automated unit tests to execute cleanly without manual button prompts.
- **Kinetic Player Locomotion (`scripts/player/player.gd`):**
  - Smooth acceleration and deceleration lerping for responsive, grounded third-person movement.
  - Integrated 3-tier kinetic speed states: Walk ($2.4\text{ m/s}$), Run ($4.8\text{ m/s}$), Sprint ($7.2\text{ m/s}$).
  - Dynamic footstep foley interval generator connected to `AudioManager` with ground speed modulation.
- **Production Documentation Master Pass:**
  - `ART_DIRECTION_GUIDE.md`: Complete Gen-Z neo-noir aesthetic pillars, color harmonies, lighting setups, polygon budgets, camera behavior.
  - `UI_UX_GUIDE.md`: Diegetic smartphone ("EchoOS v4.0") interface, landscape mobile ergonomic touch zones, Android `VibrationEffect` haptic profiles, Memory Room mind-palace design, accessibility suite.
  - `AUDIO_DIRECTION_GUIDE.md`: Dynamic 4-stem music architecture, 3D spatial binaural routing, original synthwave/ambient OST themes, mobile audio codecs.
  - `ANDROID_PERFORMANCE_GUIDE.md`: Target FPS/resolution presets, ASTC compression parameters, occlusion culling, dynamic framerate capping, thermal throttling mitigation.
  - `CHARACTER_BIBLE.md`: Complete character lore, streetwear styling, 3D rig hierarchy with spring bones, 52 ARKit facial blendshapes for Alex Morgan, Maya Reed, Archivist, Architect, and Forgotten Child.
  - `STORY_BIBLE.md`: Six-chapter narrative arc, living world connection, 4 distinct endings (`ENDING_SAVE`, `ENDING_RELEASE`, `ENDING_ESCAPE`, `ENDING_SECRET`).
  - `CINEMATIC_SCRIPT.md`: Full 2.39:1 CinemaScope opening cinematic shot list, foley cues, voiceover lines, and seamless control handoff.
  - `NETWORKING_DESIGN.md`: Asymmetrical 1–4 player co-op ("Divergent Perception"), listen-server state sync, LAN auto-discovery, WebRTC room codes, offline campaign isolation.
  - `ASSET_REGISTER.md`: Complete master registry of 3D characters, props, shaders, and audio tracks.
  - `PROJECT_OVERVIEW.md`: Production charter and status gating.

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
