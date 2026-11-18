# Task Tracker
| ID | Task | Status |
|---|---|---|
| T-000 | Master director docs + project scaffold | APPROVED (superseded by T-004) |
| T-001 | Game design documents | READY FOR TESTING (needs owner approval) |
| T-002 | Story, characters, chapters, endings, dialogue sample, cinematics | READY FOR TESTING (needs owner approval) |
| T-007 | World/level design + validator + generated data | READY FOR TESTING (validator passes) |
| T-004 | Technical architecture + working Godot foundation (Prompt 04) | READY FOR TESTING: all automated gates pass (see TESTING_AND_RUN_GUIDE.md) |
| T-003 | Player controller, camera, input, interaction, animation integration, test scene (Prompt 07) | READY FOR TESTING in simulation. **Android gate NOT closed: needs the manual device checklist (TESTING_AND_RUN_GUIDE.md section D)** |
| T-005 | Real character art/animation integration | NOT STARTED |
| T-006 | Android export + on-device performance profiling | NOT STARTED (guide written) |
| T-008 | Hand-built location scenes replacing graybox (Ch1 first) | NOT STARTED |
| T-009 | Co-op replication | NOT STARTED |
| T-010 | Full dialogue script and localization (en complete, ur) | NOT STARTED |

## Known limitations
- Never run on a physical Android device or profiled; all device claims are simulated.
- Placeholder capsule character with procedural animation; no art or audio assets.
- Headless tests use the dummy renderer: shaders/lighting/GPU cost are untested.
- Networking is a skeleton (no replication).
- Only Chapter 1-2 dialogue is authored in data.
