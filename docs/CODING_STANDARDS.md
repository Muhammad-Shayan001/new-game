# Coding Standards

## GDScript style
- Godot 4.3, static typing wherever the type is known (`var x: int`, `func f(a: String) -> bool`). Use `:=` only when the type is obvious.
- Indent with **tabs**. 100 columns where practical.
- `snake_case` for variables, functions, files, signals. `PascalCase` for `class_name`. `UPPER_SNAKE` for constants and enum values. Private members start with `_`.
- One responsibility per script. If a script passes about 300 lines or needs a "manager of managers", split it.
- File order: `class_name`, `extends`, doc comment (`##`), signals, enums, constants, exports, public vars, private vars, lifecycle, public methods, private methods.
- Do not shadow native properties. Example: `Area3D` already has `priority`, so `Interactable` uses `interact_priority`.
- Do not name members like built-in functions or classes.

## Naming
| Thing | Convention | Example |
|---|---|---|
| Script file | snake_case | `mission_manager.gd` |
| Scene file | snake_case | `npc_base.tscn` |
| Resource class | `<Thing>Def` | `MissionDef` |
| Resource file | lower-case id | `ch1_m01.tres` |
| Autoload | PascalCase service name | `SceneRouter` |
| Signal | past tense, or `*_requested` | `mission_completed`, `autosave_requested` |
| Node in scene | PascalCase | `StationClock` |
| Translation key | UPPER_SNAKE | `MISSION_CH1_M01_TITLE` |
| Test | `test_<behavior>` | `test_chapter_advances_when_all_main_missions_complete` |

## Architecture rules
1. **Data, not code.** Story content (text, ids, rewards, conditions) belongs in resources and `.po` files, never in scripts.
2. **No global side doors.** Systems communicate through `EventBus` signals or the public methods of managers. Never reach into another script's `_private` members (tests are the only exception).
3. **State lives in `GameState`.** Managers keep no saved data of their own. Runtime-only caches (timers, active puzzle entries) must have a `reset_runtime()`.
4. **Scenes own presentation, resources own meaning.** Location scripts extend `LocationRoot` and stay tiny.
5. **Autoloads are services.** Do not add an autoload for something that belongs to one level.
6. **Platform neutrality.** No `OS.get_name()`, `OS.has_feature("android")` or key/touch checks in gameplay code. Use `InputActions` and `InputService`. UI visibility by device is the only allowed device logic, and it reads `InputService.device`.
7. **Polled input for actions.** Use `Input.is_action_just_pressed` in `_process` or `_physics_process`. Touch buttons call `Input.action_press`, which does not create `InputEvent`s, so `_unhandled_input` would miss them.
8. **Never hard-code ids as strings in scripts** when a constant exists (`LocationIDs`). Content ids in scripts are allowed only in tests and tools.

## Signals
- Declare new cross-system signals in `EventBus` with typed parameters.
- Payloads are ids and primitives. Do not pass nodes (exception: `location_ready`).
- Connect in `_ready()`. Use lambdas only for one-line forwarding. Disconnect or free the listener with its owner.
- Emit after state is consistent, not before.

## Error handling
- Use `GameLog.warn` for recoverable problems and `GameLog.error` for bugs or bad data. Do not use bare `print` or `push_error` in game code.
- A bad id returns `false` / `null` and logs. It must not crash and must not half-apply a change.
- Check results of file and network calls. Never ignore an `Error`.
- Validate data at the boundary: `DataRegistry.validate_all()` for content, `SettingsManager._sanitize` for settings, checksum and version for saves.

## Mobile performance rules
- No allocations in per-frame code paths where avoidable (cache arrays and node refs).
- Do not call `get_node` or group queries every frame; cache in `@onready` or on signals.
- Use groups only for broadcast effects (`memory_sight_reveal`).
- Keep real-time shadows and transparent overdraw low (see `ANDROID_PERFORMANCE_GUIDE.md`).
- Load scenes with `SceneRouter` (threaded). No synchronous loads of large scenes during play.

## Content workflow
1. Change `tools/world_data.py` for world, mission or fragment structure, then run the pipeline in `DATA_SCHEMA.md` section 8.
2. Use `content_tool.gd new-*` for new content, then edit the `.tres` in the editor.
3. Always finish with `content_tool validate`. It must print `0 problem(s)`.

## Testing
- Every new system or rule gets a test in `tests/unit/`. Every bug fix gets a regression test.
- Tests may not depend on each other. `TestCase.before_each()` resets the world.
- Run all tests before every commit: `godot --headless --path . res://tests/test_runner.tscn` (exit code 0 = pass).
- Tests must assert behavior (state, signals), not implementation details.

## Git
- Small commits with a clear message: `Area: what and why`. Never commit `.godot/`, export presets with keys, or tokens.
- Do not edit generated files by hand.
- Update `CHANGELOG.md`, `TASK_TRACKER.md` and the affected docs in the same commit as the code.

## Review checklist
- [ ] No story text or ids hard-coded in gameplay scripts
- [ ] No raw input or platform checks in gameplay
- [ ] New ids follow `DATA_SCHEMA.md`; `validate` prints 0 problems
- [ ] New state is in `GameState`, saved, defaulted, and covered by a save test
- [ ] Failure paths log and leave a playable state
- [ ] Tests added and the full suite passes
- [ ] Docs and changelog updated
