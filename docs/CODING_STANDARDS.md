# Coding Standards (GDScript, Godot 4.3)

## Naming
| Thing | Convention | Example |
|---|---|---|
| Files, folders | `snake_case` | `player_controller.gd` |
| Classes (`class_name`) | `PascalCase` | `PlayerController` |
| Autoloads | `PascalCase` singleton name | `SceneManager`, `EventBus` |
| Functions, variables | `snake_case`; private = leading `_` | `_update_state()` |
| Constants, enums | `UPPER_SNAKE_CASE` | `LATCH_MS` |
| Signals | `snake_case`, **past tense** | `location_entered`, `fragment_collected` |
| Content IDs | `UPPER_SNAKE` with prefix (see DATA_SCHEMA.md) | `LOC_EC_PARK`, `ITEM_ARCHIVE_CARD`, `CH1_M01` |
| Groups | `snake_case` | `memory_sight_target` |
| Input actions | `snake_case` | `interact`, `move_forward` |

## Rules
1. **Static typing everywhere** (`var x: int`, `-> void`). `:=` only when the type is obvious. The project treats inferred-Variant as an error, so this is enforced by the compiler.
2. **One responsibility per script.** No script over ~350 lines; split before that. Managers own state, UI scripts own widgets, nothing owns both.
3. **No hard-coded node paths into other systems** (`get_node("/root/...")`). Use autoload names, groups, exported `NodePath`s, or signals.
4. **Communication:** managers announce through `EventBus` signals (payload = IDs, never nodes). Direct calls go *down* (parent to child, caller to autoload service), never up.
5. **Gameplay never reads devices.** Use `InputRouter` / action names. No `OS.has_feature("android")` branches inside gameplay logic (platform differences live in `InputRouter`, HUD layout and `Settings`).
6. **Data over code.** New content = new JSON. Behaviour that varies per item goes in `Condition`/`Effects`, not in `if id == "X"` branches.
7. **Frame-rate independence.** Smoothing uses `1 - exp(-k * delta)`; movement uses `delta`. No per-frame constants.
8. **Physics in `_physics_process`, visuals in `_process`.** Camera follows in `_process` (smooth), body moves in physics.
9. **Coroutines:** a function that `await`s says so in its doc comment; callers `await` it or deliberately `.call()` it. Anything long-running must tolerate the scene being freed (`is_instance_valid`).
10. **Don't allocate in hot paths** (no `Array.filter` with lambdas per frame on large sets; reuse buffers). Mobile target: 30 fps on mid-range Android.
11. **Comments explain why**, not what. Public functions and classes get a `##` doc comment.

## Error handling
- Bad data or failed I/O: `Log.error(tag, msg)` and return `false` / empty value. **Never crash and never leave a manager in a half state** (see `SceneManager._abort_transition`).
- Recoverable oddities (unknown condition key, missing localization): `Log.warn` once; conditions fail *closed*.
- Programmer errors in tests: assertions in `tests/`, not `assert()` in shipping code.
- Every public registry/manager function that can fail returns `bool` or a result the caller can test.

## Signals vs calls
| Situation | Use |
|---|---|
| "Something happened" (UI, missions, audio react) | `EventBus` signal |
| "Do this now" to a service | direct method call on the autoload |
| Child → parent notification | local signal on the child |
| Data-driven reaction | `Effects.run([...])` |

## Git
Small commits, imperative subject, one concern each. Generated files are committed alongside their source change. CI must be green.
