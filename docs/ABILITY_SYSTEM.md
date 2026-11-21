# Ability System (Prompt 08)

Four mechanics, all data-driven (`AbilityDef`) and all used in real scenes.

| Ability | Slot | Unlock | Duration / cooldown | Where it is used |
|---|---|---|---|---|
| Memory Vision (`ABIL_MEMORY_SIGHT`) | 1 | `CH1_M02` | 8 s / 6 s | Clock room (hidden writing, memory trace) |
| Reality Shift (`ABIL_REALITY_SHIFT`) | 2 | `CH3_M01` | instant / 1 s | Anchor Fields (bridge, sigil, gate) |
| Time Echo (`ABIL_TIME_ECHO`) | 3 | `CH3_M01` | instant / 0.5 s (recording max 10 s) | Echo Gallery (replay, plates) |
| Echo Voice (`ABIL_ECHO_VOICE`) | 4 | not assigned | stub | none (outside Prompt 08) |
| Echo Detection (Memory Pulse) | action `memory_pulse` | needs Memory Sight | hold 0.4 s / 3 s | Clock room (finds the trace) |

`AbilityManager` owns unlocks, timers and cooldowns. Behaviors (`AbilityBehavior` subclasses) apply the effect and decide `can_activate()`. Input: slots 1-4 = `ability_1..4` (keys 1-4, gamepad X, Y, RB, LB, touch buttons).

## Memory Vision
- `MemorySightBehavior` calls `set_revealed(bool)` on every node in the group `memory_sight_reveal`.
- `Revealable` (Node3D): hidden until revealed, fades in (instant with reduce motion). Its Interactable child (`interactable_path`) can only be used while revealed. Options: `stay_visible_once_found`.
- `MemoryTrace` extends `Revealable`: has a `trace_id` (`TRC_...`), joins the group `memory_traces`, and records an optional discovery in `ProgressionManager` when collected.
- Rules: timer and cooldown only, no energy. Accessibility `ability_duration_scale` (1.0 to 2.0) lengthens it.
- Feedback (`AbilityHud`): screen tint while active, slot text "Ready / Active 5s / Recharging 3s", activation sound cue (`AUD_ABILITY_ACTIVATE`, placeholder until audio exists).

## Echo Detection
Hold the pulse button. `EchoDetection.pulse()` finds the nearest undiscovered `MemoryTrace` within 40 m and reports distance, band (very close under 6 m, close under 18 m, far) and bearing relative to the camera (0 = ahead, +90 degrees = right).
- Visual: text such as "Close, to your right" (readable without colour or sound).
- Audio: ping `AUD_ECHO_PING`, pitch rises as you get closer.
- Haptic: short vibration on touch devices.
- Each channel can be turned off: `echo_visual_cues`, `echo_audio_cues`, `echo_haptics`.

## Reality Shift
- `ShiftZoneDef` (`SHF_...`): states (default `echo_city` and `other_side`), default state, `persistent` (saved in `GameState.shift_states`), `exclusive` (only one zone away from its default at a time), transition time.
- `ShiftAnchor` (Area3D): the only place the ability works. `target_state` empty = cycle; set = always that state.
- `ShiftableObject` (Node3D): `visible_in_states`, `solid_in_states`. Handles different object configurations, alternate routes (collision on/off) and state-specific clues (an Interactable inside is only usable in its state). It matches the saved state when the scene loads.
- `ConditionSet.shift_states` makes puzzle dependencies ("gate opens only in echo_city").
- Safe transitions: after a change the manager waits two physics frames, then moves the player to the nearest `shift_safe_points` marker (or the spawn) if they ended up inside a newly solid object. Shifting only works at anchors, so the player is never on a vanishing bridge.
- `ShiftManager.busy` prevents spamming during the transition time.

## Time Echo
1. **Replay** (`TimeEchoDef`, `ECH_...`) at an `EchoSite` with `echo_id`: timeline data for figures (`EchoTrack` + `EchoKey`), camera framing (`EchoCameraKey`, uses the camera rig override), audio cues (`EchoAudioEvent`), captions (`EchoCaption`, every sound has one) and clue moments (`EchoClueMoment`: clue, fragment, info). Conditions can require an earlier clue; `replayable` controls repeats. Input is locked while it plays; Interact skips (clue moments still fire).
2. **Recording** at an `EchoSite` with `allow_recording`: the first use records up to 10 s of the player's movement, the second use stops it and spawns a ghost that replays the walk and then stays where it ended. One ghost at a time; the Chapter 5 flag `time_echo_upgraded` allows two. Ghosts are removed when leaving the location. A `PressurePlate` counts players and ghosts, so this solves "two plates" puzzles alone (and with two players in co-op).

## Status
Implemented and tested: Memory Vision, Echo Detection, Reality Shift, Time Echo (replay and recording). Not implemented: Echo Voice (stub that refuses activation), real audio, art and animation (translucent capsules and labels stand in).
