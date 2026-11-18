# Testing and Run Guide

## A. Run the game on a PC (fastest way to check it)
1. Install **Godot 4.3 stable** (standard version, not .NET): https://godotengine.org/download
2. Download/clone the repository (`git clone https://github.com/Muhammad-Shayan001/new-game.git`).
3. Godot → **Import** → select `project.godot` → open. First open imports resources (a few seconds).
4. Press **F5** (Play). The title screen appears.
   - **New Game** starts Chapter 1 at *Echo Station*. Walk into the glowing doors (portals) to travel between locations (all 47 are playable graybox).
   - **Test Arena (dev)** (shown in editor/debug builds) loads the test arena with the objective: lever → note → computer → door → goal.
5. Controls: **WASD** move · **mouse** look · **Shift** sprint · **E** interact · **1-4** abilities · **Q** context ability · **Esc** pause · gamepad works too.
6. **Preview the phone controls on PC:** Esc → *Touch controls* (cycles auto/on/off). With "on", the mouse acts like a finger: drag on the left half = joystick, drag on the right half = camera, click the round buttons.

Windows build (optional): Project → Export → add *Windows Desktop* → Export Project. (Needs export templates: Editor → Manage Export Templates → Download.)

## B. Run it on an Android phone
**Prerequisites** (one-time): Godot export templates (Editor → Manage Export Templates), **JDK 17**, **Android SDK** (platform-tools, build-tools 34.0.0, platform android-34, cmdline-tools, CMake 3.10.2.4988404, NDK 23.2.8568313: see Godot docs "Exporting for Android"), and a debug keystore. In Godot: *Editor → Editor Settings → Export → Android* → set Java SDK path, Android SDK path, debug keystore.
**Export preset:** Project → Export → Add → *Android*.
- Architectures: **arm64-v8a** only.
- **Resources tab → "Filters to export non-resource files": `*.json,*.cfg`** (IMPORTANT: all game data is JSON; without this the game starts with no content).
- Options → Screen: orientation landscape (already set in the project).
**Install:** enable *Developer options → USB debugging* on the phone, connect by USB, accept the prompt, then click the **Android icon (one-click deploy)** at the top right of the editor. Or export an APK and run `adb install -r afterlife.apk`.
**Without a USB cable:** export a debug APK, send it to the phone and install it (allow "install unknown apps").
If the phone does not support Vulkan, set Project Settings → Rendering → Renderer → *Compatibility* and re-export.

## C. Automated tests (no editor UI, no device)
```
godot --headless --fixed-fps 60 --path . -s res://tests/run_tests.gd            # everything
godot --headless --fixed-fps 60 --path . -s res://tests/run_tests.gd -- player  # only files matching "player"
```
Exit code 0 = all passed. `--fixed-fps 60` makes simulated time deterministic and fast. The dummy renderer prints harmless `mesh_get_surface_count` messages; ignore them.

| Suite | Covers |
|---|---|
| `test_data` | Every JSON loads; every cross-reference (location, dialogue, puzzle, item, ability, speaker) resolves; every localization key exists; connections are symmetric |
| `test_core` | Conditions, effects, inventory, fragments, puzzles/hints, abilities + cooldown, localization (incl. RTL), settings persistence, networking host/leave |
| `test_save` | Round trip of all systems, mission progress, v1→v2 migration, newer-schema refusal, corrupt-file backup recovery, provider validation |
| `test_missions` | Full 6-chapter campaign played through events (18 main missions complete in order, abilities unlock), locked missions ignore events |
| `test_dialogue` | Linear lines, choices and consequences, hidden choices, once-only, no overlapping dialogues |
| `test_scene_flow` | Enter every one of the 47 locations, portals with chapter gates (walked through physically), hidden portals need Memory Sight, autosave in safe rooms, re-entry guard, freeing the root mid-transition |
| `test_player` | Walk/run/sprint speeds, acceleration/deceleration, camera-relative movement, turning, wall/pillar collision, wall sliding, input lock, animation blend + footsteps |
| `test_camera` | Follow, orbit, pitch clamp, sensitivity, invert-Y, collision and ease-out, body hiding, indoor presets, cinematic takeover/release, shake, auto-recenter |
| `test_interaction` | Prompt, facing cone/assist, requirements with feedback, every interaction type, hold, one-shot persistence, puzzle UI chain |
| `test_touch_controls` | Joystick (dead zone, ramp, cap, second finger), look pad, simultaneous move+look, buttons (hold/toggle), pause, context ability, left-handed layout, layout fits 4 aspect ratios |
| `test_objective_playthrough` | **Completion gate:** a full multi-step objective using only stick vector + interact; save/restore mid-objective; keyboard and analogue-stick paths |
| `test_ui_flow` | Title → new game → continue → quit to title, pause menu, dialogue box, toast |
| `test_extensibility` | **Prompt 04 gate:** new character/item/puzzle/dialogue/interaction/location/mission added by data only and played through |

CI runs the same command on every push (`.github/workflows/tests.yml`).

## D. Manual Android gate checklist (required on a real device)
Test on at least: one low-end (≤ 4 GB), one mid-range, one tablet. Record device, Android version, result.

| # | Step | Expected | Pass? |
|---|---|---|---|
| 1 | Launch → title → **New Game** | Echo Station loads, objective text top-left, touch controls visible, no crash | |
| 2 | Drag left thumb | Joystick appears under the thumb, character moves relative to the camera, speed scales with how far you push | |
| 3 | Release | Character decelerates smoothly (no instant stop, no drift) | |
| 4 | Drag right side | Camera orbits smoothly, no jitter; moving and looking at the same time works | |
| 5 | Hold **Sprint** while moving | Faster; releasing returns to run | |
| 6 | Walk into a wall / pillar | Blocked, slides along it; camera never clips through geometry | |
| 7 | Approach an object | Prompt appears, Interact button glows; tap Interact | Action happens once per tap, even a very quick tap | |
| 8 | Test Arena (debug build): lever → note → computer → door → goal | Mission completes ("Test arena complete!") | |
| 9 | Pause button → Resume / Save / Quit to title → Continue | State restored (location, objective) | |
| 10 | Rotate/sleep the phone, switch apps and return | No crash, input not stuck (no phantom movement) | |
| 11 | Settings: left-handed, invert Y, sensitivity | Layout mirrors / camera reacts immediately | |
| 12 | 10-minute session | No crash; frame rate ≥ 30 fps on the low-end device (use Godot remote debugger → Monitors → FPS) | |
| 13 | Buttons reachable with thumbs on a 6" phone, none under the notch | Yes | |

Do not mark Prompt 07's Android gate APPROVED until rows 1-13 pass on a real device.
