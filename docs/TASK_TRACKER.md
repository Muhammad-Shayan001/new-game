# Task Tracker
| ID | Task | Status |
|---|---|---|
| T-000 | Master director docs + project scaffold | READY FOR TESTING |
| T-001 | Game Design Document + gameplay systems + mission template + progression + flowchart | READY FOR TESTING (needs owner approval) |
| T-002 | Story Bible, Character Bible, outlines, dialogue sample, timeline, endings, cinematics | READY FOR TESTING (needs owner approval) |
| T-003 | Player controller + camera + touch controls | READY FOR TESTING (headless tests pass; needs device feel-testing) |
| T-007 | World/level design docs + validator | READY FOR TESTING (validator passes; needs owner approval) |
| T-008 | Technical architecture and Godot foundation (Prompt 04): 5 docs, 15 autoload systems, data-driven content, content tool, 77 tests | READY FOR TESTING (77/77 pass headless; not run in editor window or on device) |
| T-004 | Journal UI + clue linking UI (logic exists in InventoryManager) | NOT STARTED |
| T-005 | Graybox level (Echo Station): basic scene exists, needs layout and props | IN PROGRESS |
| T-006 | Android export + device test | NOT STARTED |
| T-009 | Reality Shift, Time Echo, Memory Vision, Echo Detection + puzzle engine + 5 prototype puzzles (Prompt 08) | READY FOR TESTING (133/133 pass headless; not run in editor window or on device) |
| T-009b | Echo Voice effect | NOT STARTED (stub) |
| T-010 | Cutscene runner (listens to `cutscene_requested`) + flashbacks | NOT STARTED |
| T-011 | Main menu, load screen, settings screen | NOT STARTED |
| T-012 | Co-op replication + Echo Trials | NOT STARTED (connection layer done) |
| T-013 | Author real objectives for the remaining skeleton missions (10 are hand-authored) | NOT STARTED |
| T-014 | Quest, story-state and progression systems (Prompt 09) | READY FOR TESTING (completion gate test passes headless) |
| T-015 | Journal UI: clues, linking, character info, choices, progression overview (data and logic exist) | NOT STARTED |
## Open design decisions (need owner answer)
- Ability unlocks are now proposed: Memory Sight at the end of `CH1_M02`, Reality Shift and Time Echo at the end of `CH3_M01`. Echo Voice (Ch5) is still unassigned. Please confirm or change.
- Which mission carries the `time_echo_upgraded` and `architect_revelation_seen` states in Chapter 5 is not fixed yet.
- Sample dialogue choice effects in `DLG_CH2_M02_CAFE` (maya_trust +1 for "Then why are you here?") are placeholders.
## Notes
Dialogue script covers key lines only; full script is a later production task. Generated skeleton missions only ask the player to visit locations in order.
