# Technical Design Document (v0.1.0 — Prompt 04)

Godot 4.3+, GDScript, Mobile renderer. Targets: Android first, PC second. One shared code base; no platform-specific gameplay code.

## 1. Goals and principles

| Principle | What it means in this project |
|---|---|
| Data-driven | Missions, dialogue, items, puzzles, abilities, locations, fragments and characters are `.tres` resources. Gameplay scripts read them; they never contain story data. |
| Modular | One small script per responsibility. No script owns "the whole game". Systems talk through `EventBus`, not through each other's internals. |
| Safe | Every failure path logs through `GameLog`, leaves the game in a playable state, and has a test. |
| Offline-first | The campaign never needs a network. Co-op is an optional layer. |
| Platform-neutral | Gameplay reads `InputService` only. Keyboard, mouse, gamepad and touch produce the same actions. |
| Testable | Every system runs headless. `tests/` holds 77 automated tests that boot the real game scene. |

**Completion gate (met):** a developer can add a character, mission, location or puzzle by adding data. See section 7 and `tests/unit/test_content_gate.gd`.

## 2. System map

| System | File(s) | Responsibility | Main signals / API |
|---|---|---|---|
| Event bus | `scripts/autoload/event_bus.gd` | Global signal hub | all cross-system signals |
| Game state | `scripts/autoload/game_state.gd` | All saved data, save schema | `flag_changed`, `memory_unlocked`, `to_dict/from_dict` |
| Data registry | `scripts/autoload/data_registry.gd` | Loads and validates every `GameDef` by id | `get_mission(id)`, `validate_all()` |
| Scene router | `scripts/autoload/scene_router.gd` | Safe location transitions | `change_location(id, spawn)` |
| Player | `scripts/player/player.gd` | Third-person movement | reads `InputService` |
| Camera | `scripts/player/camera_rig.gd` | Orbit camera, collision, cinematic override | `push_override`, `pop_override` |
| Interaction | `scripts/world/interactable.gd`, `scripts/player/interaction_sensor.gd` | Prompts, hold-to-use, effects from data | `interaction_completed` |
| Missions | `scripts/missions/` | State machine, objectives, rewards, chapter flow | `mission_*` |
| Dialogue | `scripts/dialogue/` | Runs `DialogueDef`, choices, relationships | `dialogue_*` |
| Inventory | `scripts/systems/inventory_manager.gd` | Items, clues, clue linking | `item_added`, `clue_added`, `deduction_made` |
| Puzzles | `scripts/puzzles/` | Pattern/ordering logic, hints, solved state | `puzzle_*` |
| Memory fragments | `scripts/systems/memory_manager.gd` | Core / Hidden / Deep fragments | `fragment_collected` |
| Abilities | `scripts/abilities/` | Unlocks, timers, cooldowns, effects | `ability_*` |
| Audio | `scripts/autoload/audio_manager.gd` | Buses, music crossfade, cue playback, ducking | `play_cue(id)` |
| UI | `scripts/ui/`, `scenes/ui/` | HUD, dialogue box, prompt, toasts, pause, touch controls | listens to `EventBus` |
| Saving | `scripts/autoload/save_manager.gd` | Versioned, checksummed, atomic saves | `save_game`, `load_game` |
| Settings | `scripts/autoload/settings_manager.gd` | Validated user settings | `settings_changed` |
| Localization | `scripts/systems/localization.gd`, `localization/*.po` | Translation keys, locale | `Localization.t(key)` |
| Networking | `scripts/autoload/network_manager.gd` | Optional ENet co-op connection layer | `network_state_changed` |
| Input | `scripts/autoload/input_service.gd`, `scripts/systems/input_actions.gd` | Input abstraction and locking | `get_move_vector()`, `push_lock()` |

## 3. Boot sequence

1. Godot creates the autoloads in this order: `EventBus`, `DataRegistry`, `GameState`, `InputService`, `AudioManager`, `SettingsManager`, `SaveManager`, `SceneRouter`, `InventoryManager`, `MemoryManager`, `AbilityManager`, `PuzzleManager`, `DialogueManager`, `MissionManager`, `NetworkManager`.
   - `EventBus` is first because everything emits through it.
   - `DataRegistry` loads all definitions in `_ready()`.
   - `AudioManager` is created before `SettingsManager` so saved volumes can be applied to existing buses.
2. `scenes/game_root.tscn` is the main scene. `GameRoot` registers its `World` node with `SceneRouter`, then tries `SaveManager.load_game(AUTO_SLOT)`. If there is no usable autosave it calls `start_new_game()`.
3. `SceneRouter.change_location()` loads the location, `GameRoot` places the player on the spawn point and snaps the camera, `MissionManager` counts the arrival.

## 4. Systems in detail

### 4.1 Game state
`GameState` stores flags, clues, memories, location, missions (state and progress), inventory, abilities, puzzles, relationships, decisions, deductions and playtime. It owns data and the save schema, not rules. Rules live in the managers. Flag values may only be `bool`, `int` or `String`. After JSON loading, whole-number floats are converted back to ints so a saved `deep_fragments = 2` stays an int.

### 4.2 Scene transitions
`SceneRouter.change_location(location_id, spawn_id)` runs: fade out, threaded load (20 s timeout), swap, fade in.
- Only one transition at a time. A second request is refused and logged.
- A load failure keeps the current location, fades back in, emits `scene_transition_failed`, and unlocks input.
- Input is locked and autosave is blocked during the transition.
- Locations without a scene use `scenes/world/placeholder_location.tscn`, which shows the location name and builds a door for every open route. The whole world graph is therefore walkable before any level art exists.
- After every successful transition `autosave_requested("room_transition")` is emitted.

### 4.3 Player control
`Player` (`CharacterBody3D`) reads only `InputService.get_move_vector()`. Walk below 60% stick deflection (2.2 m/s), run above (4.5 m/s). Movement is relative to the camera yaw. Falling below `kill_height` respawns at the last spawn point. No fall damage.

### 4.4 Camera
`CameraRig` = yaw node, pitch node, `SpringArm3D` (wall collision), `Camera3D`. Look input comes from mouse drag, right-half touch drag and the right stick. It auto-recentres behind the player after 1.5 s of movement without look input (disabled by "reduce motion"). FOV, sensitivity and invert-Y come from settings. `push_override(node, blend)` and `pop_override(blend)` give cinematic framing with a smooth blend.

### 4.5 Interactions
`Interactable` (`Area3D`) is configured only by exported data: prompt key, priority (`AMBIENT < PICKUP < CLUE < STORY`), hold time, `ConditionSet`, `once`, and effects (flags, clue, item, fragment, mission, dialogue, puzzle symbol, sound, travel). `InteractionSensor` on the player picks the best candidate within 2 m and a 70 degree facing cone: highest priority first, then nearest. Auto-interact (setting) only applies to pickups and ambient objects with no hold time.

### 4.6 Missions
`MissionDef` follows `MISSION_DESIGN_TEMPLATE.md`. States: `LOCKED -> AVAILABLE -> ACTIVE -> COMPLETE`. A mission unlocks when `GameState.chapter >= chapter` and its `ConditionSet` is met, and starts automatically if `auto_start`. Objectives (`ObjectiveDef`) complete from events: reach location, flag, fragment, item (with counts), clue, interact, puzzle, dialogue. Objectives that are already true when a mission starts count immediately. Completion applies flags, rewards (abilities, items, clues, fragments), plays the closing dialogue, autosaves, and advances the chapter when all `MAIN` missions of the chapter are complete. There is no hard fail: `respawn_location` and `respawn_spawn` define the checkpoint.

### 4.7 Dialogue
`DialogueDef` holds `DialogueNode`s (speaker, translation key, next node, conditions, flags, relationship changes, voice cue) and up to 3 `DialogueChoice`s each. Choices can be hidden by `ConditionSet` (for the "Remember" prompts that need a memory). Relationship values are clamped to -3..+3. `DialogueManager` has no UI: `DialogueBox` listens to the bus and calls `advance()` and `choose(i)`. Gameplay input is locked while a dialogue runs.

### 4.8 Inventory and clues
Items are `ItemDef` resources (stackable with `max_stack`). Clues are plain `CLUE_*` ids stored in `GameState`. `link_clues(a, b)` looks up a `DeductionDef` for the pair in either order; a wrong link only shows a gentle toast.

### 4.9 Puzzles
`PuzzleDef` has a type, a solution, three hint keys, and rewards. Built-in logic exists for `PATTERN` (symbols in order) and `ORDERING` / `MEMORY_RECON` (full arrangement). Puzzles with their own scene logic (light and mirror, sound echo, reality swap, time echo) call `PuzzleManager.mark_solved(id)`. Solved state and hint tier are saved. New types: add a `PuzzleRuntime` subclass and one `match` case in `PuzzleManager._make_runtime()`.

### 4.10 Memory fragments
`FragmentDef` (Core / Hidden / Deep). `MemoryManager.collect(id)` stores the fragment, increments the `deep_fragments` flag for Deep ones, shows a toast, requests an autosave, and emits `cutscene_requested` when the fragment has a flashback scene.

### 4.11 Abilities
`AbilityDef` names a behavior script (`AbilityBehavior` subclass). `AbilityManager` owns unlocks, duration and cooldown timers (no energy system). Input slots 1-4 map to `ability_1..ability_4`. Memory Sight is implemented (it calls `set_revealed(bool)` on every node in the group `memory_sight_reveal`). Reality Shift, Time Echo and Echo Voice are interface-complete stubs that refuse activation until their tasks are done.

### 4.12 Audio
Gameplay asks for cue ids. `AudioCueDef` maps an id to a stream, bus and volume. Buses: Master, Music, SFX, Ambience, Voice. Music crossfades between two players; one-shots use a pool of 8; music ducks by 8 dB during dialogue. A cue without a stream logs once and is skipped, so content can be wired before audio exists.

### 4.13 UI
HUD scenes: `DialogueBox`, `InteractionPrompt`, `MissionTracker`, `ToastArea`, `TouchControls` (joystick + action buttons), `PauseMenu`. They only listen to the bus and call manager methods. Version 0.1 builds each layout in code inside the scene's script, so layouts can be replaced by editor-authored scenes without touching any system.

### 4.14 Saving
Format: JSON envelope with `version`, `saved_at`, `meta` (chapter, location, playtime), a SHA-256 `checksum`, and the state stored as a string (`state_json`) so the checksum is exact. Writes go to a temp file, the old file is copied to `.bak`, then the new file is moved into place. Loading falls back to `.bak` if the main file is missing, corrupt or tampered. Newer-than-supported versions are refused. Old versions are migrated step by step. Slots: 0 = auto, 1-3 = manual. Autosave triggers: mission step/completion, room transition, memory pickup, every 3 minutes; never while `autosave_blocks > 0`.

### 4.15 Settings
`user://settings.cfg` (ConfigFile). Every key has a default and a valid range or choice list; invalid or hand-edited values fall back safely. Changes apply immediately (bus volumes, quality scale, FPS cap, locale) and emit `settings_changed`.

### 4.16 Localization
All player-visible text is a translation key resolved with `Localization.t(key)`. `.po` files in `localization/`: `en_ui.po` (hand-written), `en_world.po` (generated), `en_content.po` (hand-written and tool-appended). A missing key logs once and shows the key, never crashes. `DataRegistry.validate_all()` fails on any missing key used by content.

### 4.17 Networking
Optional co-op, 1-4 players, host-authoritative, Godot ENet. `NetworkManager` provides host, join, leave, state signals and `is_authority()` (always true offline, so gameplay is written once for both modes). Rule: only the authority changes shared state; clients send requests. **Not yet built:** state replication and the Echo Trials rooms.

## 5. Android and PC compatibility
- All input goes through `InputActions` constants and `InputService`. Touch controls feed the same actions (`Input.action_press`) and the same stick vector.
- `TouchJoystick` and `TouchActionButton` track their own touch indices, so movement, buttons and camera drag work at the same time. A finger claimed by a control never rotates the camera.
- The device is detected from the last input (`keyboard_mouse`, `gamepad`, `touch`). Touch controls show for touch, or always if the setting is on.
- Mobile renderer, 30 fps baseline, quality presets scale 3D resolution (0.67 / 0.85 / 1.0). See `ANDROID_PERFORMANCE_GUIDE.md`.
- No `OS.get_name()` checks exist in gameplay code.

## 6. Error handling
- `GameLog.warn/error` for every recoverable problem; counters let tests assert on them.
- Unknown ids return `false` or `null` and log; they never crash.
- `DataRegistry.validate_all()` checks ids, file names, dangling references, hint counts, choice limits and translations.
- Saves: atomic write, backup, checksum, version checks. Scene loads: timeout and fallback.

## 7. Adding content without touching systems
Scaffolding (run `godot --headless --path . --import` once first):

```
godot --headless --path . res://tools/content_tool.tscn -- new-character BKR "Baker"
godot --headless --path . res://tools/content_tool.tscn -- new-location LOC_EC_BAKERY "Bakery"
godot --headless --path . res://tools/content_tool.tscn -- new-dialogue DLG_BAKER_HELLO BKR "First line"
godot --headless --path . res://tools/content_tool.tscn -- new-puzzle PZL_CH1_OVEN "The Oven" a,b,c
godot --headless --path . res://tools/content_tool.tscn -- new-mission CH1_S08 "Bake Something" optional LOC_EC_BAKERY
godot --headless --path . res://tools/content_tool.tscn -- validate
```

| To add a... | You add | You change |
|---|---|---|
| Character | `CharacterDef` + dialogue + an instance of `scenes/characters/npc_base.tscn` with `character_id` | nothing |
| Mission | `MissionDef` (objectives point at existing ids) | nothing |
| Location | `LocationDef` (+ optional scene whose root uses `LocationRoot`, with a `SpawnPoint` named `default`) | nothing (placeholder scene works meanwhile) |
| Puzzle | `PuzzleDef` + `Interactable`s that send symbols | nothing for pattern/ordering; one `match` case for a new built-in type |
| Item / clue / deduction / ability | matching `.tres` | nothing (new ability effects add one `AbilityBehavior` script) |

## 8. Testing
`godot --headless --path . res://tests/test_runner.tscn` runs 77 tests in about a minute: core data, saves (corruption, tampering, versions, migration), missions, dialogue, inventory, puzzles, abilities, settings, input, networking, scene transitions (including a broken scene file), interaction through the real physics engine, the full game scene (boot, walking, doors, pause, respawn, camera override, continue) and the content gate.

## 9. Not done yet (honest status)
- Nothing has been run in the Godot editor window or on an Android device. All verification is headless on Godot 4.3.
- Reality Shift, Time Echo, Echo Voice effects; Memory Pulse effect (the action exists).
- Cutscene runner (the `cutscene_requested` signal exists), Journal UI, settings screen, main menu, load screen.
- Editor-authored UI layouts, art, audio, animation.
- Networking state replication and Echo Trials.
- Which mission grants each ability is a design decision still to confirm (see `TASK_TRACKER.md`).
