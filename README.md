# AFTERLIFE.EXE
Third-person supernatural mystery for Android (Godot 4.3, GDScript). Offline campaign, optional co-op later.

## Try it
1. Install **Godot 4.3 stable**, open `project.godot`, press **F5**.
2. **New Game** (Chapter 1) or **Test Arena (dev)**. Controls: WASD, mouse, Shift sprint, E interact, Esc pause. On a PC, Esc -> *Touch controls* previews the phone controls.
3. Phone: see `docs/TESTING_AND_RUN_GUIDE.md` (Android export steps and the device test checklist).

## Test it
```
godot --headless --fixed-fps 60 --path . -s res://tests/run_tests.gd
```
## Docs
Everything is in `docs/` (start with `TECHNICAL_DESIGN_DOCUMENT.md`, `PROJECT_ARCHITECTURE.md`, `CONTENT_AUTHORING_GUIDE.md`). Rendered locally by opening `index.html` through any static server.

## Status
Design, story and world docs: draft. Code: architecture and player foundation implemented and tested in simulation (862 assertions in 118 tests); **not yet verified on a physical Android device**; graybox visuals, no art/audio.
