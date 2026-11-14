# Chapter Outlines

Each chapter lists: Opening, Objective, Characters, Dialogue (IDs in DIALOGUE_SCRIPT.md), Main missions, Optional missions, Clues, Memory revelations, Mechanic, Emotional turn, Ending, Link.

## Chapter 1 — The Awakening
- **Opening:** Alex wakes on a bench in Echo Station; a terminal shows the message.
- **Objective:** leave the station, reach the Archive Tower.
- **Characters:** Alex, Archivist (voice, then body).
- **Dialogue:** CH1_ARV_001–008, CH1_ALX_001–006.
- **Main:** CH1_M01 Static · CH1_M02 The Empty Plaza · CH1_M03 Catalogue Desk (meet Archivist).
- **Optional:** CH1_S01 Lost Luggage tags (3) · CH1_S02 Clock that is always 4:17.
- **Clues:** ticket stub "W.M.", child's wave drawing, wet footprints.
- **Memory:** CH1_F01 "A Name on a Ticket" (Alex's first flashback: a yellow raincoat).
- **Mechanic:** movement, interaction, Memory Sight.
- **Turning point:** Alex's name is the only card in the Archive that is blank.
- **Ending:** the Archivist hands Alex a card: "Find what was removed."
- **Link:** the card points to the Forgotten Quarter.

## Chapter 2 — The Forgotten
- **Opening:** the Forgotten Quarter, streets with a missing seat at every table.
- **Objective:** find who erased you; survive the Forgotten.
- **Characters:** Alex, Maya (echo), Archivist, Forgotten.
- **Dialogue:** CH2_MAY_001–010, CH2_ARV_001–004.
- **Main:** CH2_M01 Faceless Crowd · CH2_M02 Maya's Café · CH2_M03 The Seat Without a Name.
- **Optional:** CH2_S01 Calm the Whispering Man · CH2_S02 Rebuild the Wedding Photo.
- **Clues:** water sound in static, Maya's bracelet, the unfilled chair.
- **Memory:** CH2_F01 "Maya's Laugh", CH2_F02 "The Lake (blurred)".
- **Mechanic:** Memory Reconstruction puzzles, stealth-free evasion of Forgotten.
- **Decision:** `spared_forgotten` (calm vs. repel the Whispering Man).
- **Turning point:** Maya says she is not from this city.
- **Ending:** a door appears showing a wall of static; Maya: "Don't go in alone."
- **Link:** The Other Side.

## Chapter 3 — The Other Side
- **Opening:** raw memory layer, geometry unstable.
- **Objective:** find the Archive's root and learn how the city is edited.
- **Characters:** Alex, Archivist, Maya (voice), Forgotten Child (glimpse).
- **Dialogue:** CH3_ARV_001–008, CH3_ALX_001–004.
- **Main:** CH3_M01 Crossing · CH3_M02 Shift Anchors · CH3_M03 The Crib Room.
- **Optional:** CH3_S01 Time Echo Gallery · CH3_S02 The Hum.
- **Clues:** crib mobile, car headlight flash, nursery wallpaper matching Alex's coat lining.
- **Memory:** CH3_F01 "Eight Years Old", CH3_F02 "Sister" (name still blank).
- **Mechanic:** **Reality Shift** and **Time Echo** introduced.
- **Turning point:** Alex realizes they had a sibling.
- **Ending:** the child's lullaby echoes; an alarm tone like a hospital monitor.
- **Link:** the signal leads to the living world.

## Chapter 4 — The Living
- **Opening:** a thin bridge between Echo City and a hospital room.
- **Objective:** understand the link to the living world.
- **Characters:** Alex, Maya (real signal), Architect (voice).
- **Dialogue:** CH4_MAY_001–010, CH4_ARC_001–004.
- **Main:** CH4_M01 Hospital Echo · CH4_M02 The Crash · CH4_M03 What Maya Knows.
- **Optional:** CH4_S01 Read Maya's journal · CH4_S02 Voicemail Archive.
- **Clues:** coma chart (Alex), father's tuning fork, lake photo.
- **Memory:** CH4_F01 "The Drive", CH4_F02 "Wren's Name".
- **Mechanic:** mixed Shift/Echo puzzles, Maya assist actions.
- **Decision:** `told_maya_truth` (tell Maya Alex remembers Wren).
- **Turning point:** Alex remembers Wren's death and blames themself.
- **Ending:** the Architect speaks Alex's name for the first time.
- **Link:** invitation to the Architect's Atrium.

## Chapter 5 — The Architect
- **Opening:** the Atrium, a cathedral of stored memories.
- **Objective:** confront the Architect, choose how to treat the Index.
- **Characters:** Alex, Architect, Archivist, Maya.
- **Dialogue:** CH5_ARC_001–012, CH5_ARV_001–006.
- **Main:** CH5_M01 The Atrium · CH5_M02 The Argument · CH5_M03 Three Nodes.
- **Optional:** CH5_S01 Elias's recordings · CH5_S02 The Unsent Letter.
- **Clues:** lab logs, Index schematics, the Archivist's hidden "Instruction 0".
- **Memory:** CH5_F01 "The Lake (clear)", CH5_F02 "Elias's Promise".
- **Mechanic:** Echo Voice; second Time Echo upgrade.
- **Decisions:** `trusted_archivist`, `destroyed_index_node` (0–3 nodes), `kept_wren_memory`.
- **Turning point:** the Architect shows Wren alive inside the Index.
- **Ending:** the Atrium floor collapses; Alex falls toward the core.
- **Link:** the core, where the Forgotten Child waits.

## Chapter 6 — The Last Memory
- **Opening:** the Core, a quiet shoreline made of static.
- **Objective:** reach Wren and decide the ending.
- **Characters:** Alex, Wren, Architect, Archivist, Maya.
- **Dialogue:** CH6_FCH_001–008, CH6_ARC_001–006.
- **Main:** CH6_M01 The Shore · CH6_M02 The Lullaby · CH6_M03 The Last Memory.
- **Optional:** CH6_S01 Deep Fragment trio (secret ending).
- **Memory:** CH6_F01 "The Day at the Lake" (full truth).
- **Mechanic:** all abilities in one set-piece.
- **Turning point:** Wren asks Alex to choose.
- **Ending:** one of four endings (ENDING_DESIGN.md).
- **Link:** credits, post-game unlocks.

## Location mapping (Prompt 03 update, v1.1)
Every mission now uses `LOC_*` IDs. See LEVEL_FLOW_DIAGRAMS.md (mission-to-location matrix) and LOCATION_REGISTER.md.

Changes from v1.0 caused by the world design:
- Chapter 1 starts at `LOC_UM_ECHO_STATION` (Underground Metro); "Echo Station" is the Metro platform. CH1_M02 now routes through the Safe Room (`LOC_EC_SAFE_ROOM`) as the save tutorial.
- Chapter 2 ends at the Hartwell Hotel (`LOC_EC_ABANDONED_BLDG`) whose basement stair opens the Static Tunnel (`LOC_UM_TUNNEL_STATIC`).
- Chapter 3 = Underground Metro Line 0 then Dreamland (the Other Side). Added optional **CH3_S03 The Maintenance Log**.
- Chapter 4 = Memory Hospital and Black Forest (crash site). Added optional **CH4_S03 Totem Hollow**.
- Chapter 5 = Sunken District (Old City Hall and the Atrium). Chapter 6 = The Core (new region, `CR`).
- Deep Fragments (`CH2_F05`, `CH4_F05`, `CH5_F05`) are hidden collectibles; CH6_S01 uses them. Collectibles missed before the Ch5 collapse are recoverable through Chapter Replay.
