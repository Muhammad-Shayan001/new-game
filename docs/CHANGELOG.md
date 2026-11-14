# Changelog
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
