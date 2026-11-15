# AFTERLIFE.EXE
Godot 4.x third-person supernatural mystery (Android first, PC later).

- Design docs site (GitHub Pages): https://muhammad-shayan001.github.io/new-game/
- Docs source: `docs/` (start with `TECHNICAL_DESIGN_DOCUMENT.md` and `PROJECT_ARCHITECTURE.md`)
- Project: open `project.godot` in Godot 4.3+ (run once, or `godot --headless --path . --import`, so script classes are registered)

## Quick commands
```
python3 tools/world_data.py                                                  # validate world data, regenerate docs, ids, translations
godot --headless --path . res://tests/test_runner.tscn                      # 77 automated tests (exit code 0 = pass)
godot --headless --path . res://tools/content_tool.tscn -- validate         # check all content
godot --headless --path . res://tools/content_tool.tscn -- new-mission CH1_S08 "Title" optional LOC_EC_PARK
```

## Status (v0.1.0)
Design, story and world docs are complete (draft). The technical foundation is built and tested headless: game state, scene transitions, player, camera, interactions, missions, dialogue, inventory, puzzles, memory fragments, abilities (Memory Sight working, three stubs), audio, UI, saving, settings, localization, optional networking layer. The game boots into a graybox Echo Station and every one of the 47 locations is reachable through placeholder scenes. Not yet verified in the editor window or on an Android device. See `docs/TECHNICAL_DESIGN_DOCUMENT.md`, section 9.
