# Build and Test Guide
## Setup
1. Install Godot 4.3+ and open `project.godot` (or run `godot --headless --path . --import` once).
2. Optional: Python 3 for `tools/world_data.py`.

## Automated checks (run before every commit)
```
python3 tools/world_data.py                                              # world data valid
godot --headless --path . res://tests/test_runner.tscn                  # all tests; one suite: add  -- test_missions
godot --headless --path . res://tools/content_tool.tscn -- validate     # content valid: "0 problem(s)"
```
The headless renderer prints `mesh_get_surface_count ... "m" is null` for meshes. This is harmless noise from the dummy renderer. The test `test_broken_scene_keeps_current_location` intentionally prints a scene parse error.

## Rebuilding the authored content and scenes (only if you want to reset them)
```
godot --headless --path . res://tools/content_tool.tscn -- bootstrap-story
godot --headless --path . res://tools/content_tool.tscn -- build-scenes
godot --headless --path . res://tools/content_tool.tscn -- generate-world
```
These overwrite the files listed in `DATA_SCHEMA.md` section 8. Do not run them after editing those files by hand.

## Regenerating content after changing world data
```
python3 tools/world_data.py
godot --headless --path . --import
godot --headless --path . res://tools/content_tool.tscn -- generate-world
godot --headless --path . res://tools/content_tool.tscn -- validate
```

## Manual play test (editor)
1. Press F5. You start at Echo Station with the tracker showing "Static".
2. WASD move, E interact, right mouse drag or arrow keys look, Esc pause, 1-4 abilities.
3. Walk to the marker ahead (the clock) and press E: "Clue added". Walk to the marker on the right and press E: you move to the Concourse. Every other location is a placeholder with doors to its neighbours.

## Android export
1. Install JDK 17 and the Android SDK, set paths in Editor Settings, add an Android export preset (do not commit `export_presets.cfg`).
2. Enable USB debugging, deploy to a device.
3. Check on device: launches, touch stick and buttons work together with camera drag, save/continue, pause, 10 minute session without a crash.

## Status
Automated: 133/133 passing headless on Godot 4.3. Editor window and Android device: not yet tested.
