# Project Architecture

## Principles
1. **Data-driven**: content lives in JSON; code provides *systems* (missions, dialogue, interactions, puzzles, abilities...). Adding content never edits code.
2. **Loose coupling through one bus**: systems announce facts on `EventBus`; UI and other systems react. Nothing about UI exists inside managers.
3. **Small services, no god script**: 15 single-purpose autoloads plus scene-local scripts.
4. **Device-agnostic gameplay**: touch, keyboard, mouse and gamepad all feed `InputRouter`.
5. **Safe by default**: bad data is rejected at load; transitions cannot wedge; saves are atomic and versioned.

## Layers
```
 UI scenes (hud, dialogue_box, pause_menu, puzzle_panel, document_reader, title)
        │ listen / call services                      ▲ EventBus signals
 ───────┼─────────────────────────────────────────────┼──────────────
 Scene layer:  GameRoot ─ World(location scene) ─ Player ─ CameraRig/Interactor/Animator
        │ interact / enter                            │
 ───────┼─────────────────────────────────────────────┼──────────────
 Content systems (autoloads): MissionManager  DialogueManager  PuzzleManager  AbilityManager
                              InventoryManager  MemoryManager
 Shared logic (static):       Condition (read state)   Effects (change state)
 Core services (autoloads):   EventBus  DataRegistry  GameState  SaveManager  SceneManager
                              InputRouter  Settings  Loc  Audio  Net
```

## Autoloads (load order matters: top depends on nothing below it)
| Autoload | Responsibility | Persists? |
|---|---|---|
| `EventBus` | Global signals (IDs as payload) | – |
| `DataRegistry` | Load + validate JSON; `get_def(kind,id)`; runtime `register_def` | – |
| `Settings` | Player preferences (`user://settings.cfg`) | file |
| `Loc` | Translation tables, placeholders, RTL flag | – |
| `GameState` | Chapter, flags, relationships, decisions, location, playtime | save |
| `InventoryManager` | Items and clues | save |
| `MemoryManager` | 30 memory fragments (Core / Hidden / Deep) | save |
| `PuzzleManager` | Puzzle validation, hints, solved set | save |
| `AbilityManager` | Unlock, activate, duration, cooldown, context pick | save |
| `MissionManager` | Mission states + objectives from events | save |
| `DialogueManager` | Runs dialogue graphs | – (flags in GameState) |
| `SaveManager` | Versioned atomic saves, providers, migrations | files |
| `InputRouter` | Device abstraction, locks, press latch | – |
| `Audio` | Buses, music, SFX registry | – |
| `SceneManager` | Fades, threaded loading, location swaps, new/continue/quit | – |
| `Net` | Optional ENet co-op (host-authoritative) | – |

## Scene ownership
- `GameRoot` (persistent) owns: `World` (container), `Player`, `HUD`, `DialogueBox`, `PauseMenu`, `DocumentReader`, `PuzzlePanel`.
- A **location scene** owns only its own geometry/props and extends `LocationRoot`. `SceneManager` creates it, adds it to `World`, calls `setup_location(def)`, teleports the player to a spawn `Marker3D` (`default` or `from_<LOC_ID>`), and frees it on exit.
- The **player** is never inside a location scene; it survives transitions (state, camera, HUD stay alive).
- Locations without a hand-built scene use `graybox_location.gd`, generated from data (floor, bounds, portals, fragment pickups, interactions).

## Event flow example: "pull the lever, door opens, mission advances"
`Interactor` picks `INT_TEST_LEVER` → `Interactable.interact()` → `Condition.check(requires)` → type behaviour + `Effects.run(effects)` (`set_flag test_door_open`) → `GameState` emits `flag_changed` → `Mechanism` (watching that flag) slides open; `EventBus.interacted("INT_TEST_LEVER")` → `MissionManager` completes the objective → `mission_state_changed` / `objective_completed` → HUD refreshes. Nothing in that chain knows about the others.

## Safe scene transitions
`go_to_location` (coroutine): reject if busy → validate def and game root → lock input → fade out → free old location → threaded-load new scene (fallback to graybox) → instantiate, `setup_location`, spawn → autosave if safe room → unlock → `location_entered` → fade in. If the GameRoot disappears mid-way it aborts cleanly (tested).

## Extending the game (see CONTENT_AUTHORING_GUIDE.md)
| I want to add | I touch |
|---|---|
| Character, item, puzzle, dialogue, interaction, mission | JSON in `resources/` (+ strings in `en.json`) |
| Location | one entry in `tools/world_data.py` → `build_content.py` (or a JSON file + optional scene) |
| A new ability | JSON + one `AbilityBase` subclass |
| A new interaction *type* | new `match` arm in `Interactable._run_type_behaviour` (or use `generic` + `effects`) |
| A new saveable system | implement 3 methods + `register_provider` |
| A new condition/effect op | one `match` arm in `Condition` / `Effects` |
