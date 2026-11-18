# Player Controller, Camera, Input and Interaction Guide (Prompt 07)

## 1. Player controller (`scripts/player/player_controller.gd`)
`CharacterBody3D`, camera-relative, frame-rate independent. **No jumping**: the level design (LEVEL_DESIGN_DOCUMENT.md) has no jump traversal; climbs are interactions.

| Parameter | Default | Meaning |
|---|---|---|
| `walk_speed` | 1.9 m/s | gentle stick / Ctrl |
| `run_speed` | 3.9 m/s | stick ≥ 0.95 |
| `sprint_speed` | 6.0 m/s | sprint held or latched, requires movement |
| `acceleration` / `deceleration` | 20 / 26 m/s² | ramp up / ramp down (no instant stops) |
| `turn_speed` | 11 /s | exponential smoothing of the visual's yaw toward travel direction |
| `run_threshold` | 0.6 | stick magnitude where walking becomes running |
| `air_control` | 0.35 | acceleration factor when not on floor |

- Stick magnitude `m`: `m < 0.6` → `walk × (m/0.6)` (min 35 %); `0.6…0.95` blends walk→run; `≥ 0.95` run. Sprint overrides to `sprint_speed`.
- State machine: `idle / walk / run / sprint` (`movement_state_changed` signal).
- Collision: layer 3 (player) vs mask world; `move_and_slide` slides along walls; floor snap 0.35 m; max slope 50°.
- Input locks (`dialogue`, `pause`, `document`, `puzzle`, `cinematic`, `transition`) stop the player; deceleration still plays.
- `teleport(xform)` resets velocity and snaps the camera.

## 2. Camera (`camera_rig.gd`)
| Feature | Implementation |
|---|---|
| Follow | exponential smoothing (`follow_speed` 10) of a point 1.55 m above the player |
| Smooth rotation | yaw/pitch goals eased with `rotation_smoothing` 16; `reduced_motion` snaps |
| Sensitivity | `Settings.camera_sensitivity` (0.3–2.5), `invert_y` |
| Pitch limits | per preset (outdoor −65°…+25°) |
| Collision | `SpringArm3D` (sphere 0.22, margin 0.25, world layer) |
| Obstruction correction | snaps in instantly, eases out (`distance_out_speed`) so the view never pops; body mesh hidden if the camera is inside the character (< 0.7 m) |
| Indoor behaviour | presets `outdoor` (4.6 m, FOV 65) / `indoor` (2.7 m, FOV 72) / `tunnel` (3.1 m, FOV 70). Chosen by location type (`interior`, `tunnel`) and by `CameraZone` volumes (stack-based, blended) |
| Auto recenter | after 1.6 s without look input, swings behind the travel direction while moving |
| Cinematic control | `begin_cinematic(xform, fov, blend)`, `cinematic_cut`, `end_cinematic`; locks input, detaches the camera from the spring arm; `await end_cinematic()` restores |
| Shake | `add_trauma(0..1)`, disabled by reduced motion |

## 3. Input abstraction (`input_router.gd`, `input_actions.gd`)
Gameplay reads **only** `InputRouter` / action names.

| Action | Keyboard / mouse | Gamepad | Touch |
|---|---|---|---|
| move | WASD / arrows | left stick | floating joystick (left half; right half if left-handed) |
| look | mouse (captured) | right stick | drag on the camera pad |
| interact | E / F | A | Interact button (bottom right) |
| sprint | Shift | L3 | Sprint button (hold, or toggle via setting) |
| context ability | Q | L1 | Ability button (shows the ability that fits what is nearby) |
| abilities 1-4 | 1-4 | X / Y / B / R1 | – (context button) |
| pause | Esc | Start | Pause button (top) |
| journal | Tab / J | Back | – |

Touch widgets (`scripts/ui/components/`): `TouchJoystick` (dead zone 0.12, rescaled ramp, radius 90, multi-touch safe), `TouchLookPad`, `TouchButton` (≥ 104-unit hit target ≈ 59 dp on a 1280×720 canvas; pause 88 ≈ 50 dp). HUD layout is computed from viewport size and mirrors for left-handed players. On a PC the same widgets respond to the mouse when touch controls are forced on (pause menu → "Touch controls").
**Press latch:** a tap that is released before the next physics tick is still delivered (150 ms latch), so quick taps work on slow phones.

## 4. Interaction system
`Interactable` (Area3D, layer 2) + `Interactor` (Area3D on the player, radius 2.2 m). Best target = nearest within a 70° half-angle cone (`interaction_assist` setting widens to 360°). Prompt text is published through `EventBus.interaction_prompt_changed`; the HUD adds a device glyph (`[E]`, `(A)` or none for touch). Tap or hold (`hold_time`) interactions; requirement failures show a localized toast.

| Type | Behaviour | Typical data |
|---|---|---|
| `npc`, `phone` | starts dialogue | `dialogue_id` |
| `door` | travel to a location, or set a flag a `Mechanism` listens to | `target_location` / `state_flag` |
| `note`, `document` | opens reader, sets `read:<id>` | `title_key`, `text_key` |
| `computer`, `puzzle` | opens puzzle panel and/or dialogue | `puzzle_id` |
| `memory` | collects a fragment | `fragment_id` |
| `mechanism` | toggles a flag (lever, switch) | `state_flag`, `effects` |
| `pickup` | adds an item | `item_id`, `one_shot` |
| `generic` | only `effects` | anything |

All types also run `effects` and emit `EventBus.interacted(<interaction_id>)`, which is exactly what mission objectives (`event: "interacted"`) and dialogue effects use. `Mechanism` nodes (doors, gates) are driven purely by a flag.

## 5. Animation integration (`player_animator.gd`)
`AnimationTree` with a `BlendSpace1D` (idle 0 · walk 1 · run 2 · sprint 3) feeding a `OneShot` "interact" gesture. The blend position is smoothed from ground speed. Footsteps are emitted by a stride phase accumulator (`footstep` signal → `Audio.play_sfx("SFX_FOOTSTEP")`). Placeholder clips (bob + lean) are generated procedurally for the capsule.
**Using real animations:** put an `AnimationLibrary` containing clips named `idle`, `walk`, `run`, `sprint`, `interact` on the `AnimationPlayer`; the generator skips existing names. Replace the capsule by adding your model under `Player/Visual` (delete `Body`).

## 6. Test scene
`LOC_DEV_TEST_ARENA` (`scenes/world/test_arena.tscn`, `resources/dev/…`): graybox with a lever-operated door, pillars and a low wall, an indoor room (camera zone), and one interactable of each type. Mission `MSN_TEST_ARENA`: **pull the lever → read the note → solve the computer puzzle → walk through the door → reach the goal.** Start it from the title screen ("Test Arena (dev)", debug builds only).

## 7. Tuning cheat-sheet
Feels sluggish → raise `acceleration`; slides after stopping → raise `deceleration`; camera too floaty → raise `follow_speed`/`rotation_smoothing`; touch aiming too fast/slow → `InputRouter.TOUCH_LOOK_SENS` or the sensitivity setting; interaction misses → `Interactor.range_radius`, `cone_half_angle_deg`.
