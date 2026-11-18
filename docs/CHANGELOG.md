# Changelog
## 0.1.0: Technical architecture + player foundation (Prompts 04 and 07)
- Data-driven architecture: 15 autoload services, `EventBus`, `DataRegistry` (JSON + schema validation), `Condition`/`Effects`, localization (en, ur), versioned atomic saves with provider pattern and v1->v2 migration.
- Player controller (walk/run/sprint, acceleration, camera-relative, collision), spring-arm camera (collision, indoor presets, cinematic control), `InputRouter` with press latch, touch widgets (joystick, camera pad, buttons), interaction system (10 types), animation tree integration.
- Locations, missions and fragments generated from `tools/world_data.py` (47 locations playable as graybox); dev test arena.
- Test suite: 13 suites, 862 assertions in 118 tests, CI workflow.
- Fixed during testing: Interactables with mesh children had no collision shape; ability cooldown started after the same-frame tick; code-puzzle answers compared as text; scene manager could wedge if the game root was freed mid-transition.
- Docs: TECHNICAL_DESIGN_DOCUMENT, PROJECT_ARCHITECTURE, DATA_SCHEMA, CODING_STANDARDS, PROJECT_FOLDER_STRUCTURE, PLAYER_AND_INTERACTION_GUIDE, TESTING_AND_RUN_GUIDE, CONTENT_AUTHORING_GUIDE.
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
