# Puzzle Design Library

Five playable prototypes in three graybox scenes, each with a different solution pattern. Locations: `LOC_EC_HID_CLOCK_ROOM`, `LOC_DL_ANCHOR_FIELDS`, `LOC_DL_ECHO_GALLERY`.

## Prototype 1: The Stopped Clock (Memory Vision)
Two linked puzzles in the hidden clock room (optional mission `CH1_S02`). Needs `ABIL_MEMORY_SIGHT`.

**1a Observation + logic: `PZL_CH1_CLOCK_DEDUCTION`** (type LOGIC, completion DEDUCTION)
- Initial state: clue board locked, dial locked.
- Rules: with Memory Sight, reveal the hidden wall writing "THE HOUR IS A PROMISE: 4 . 1 . 7" and examine it (clue `CLUE_CLOCK_WALL_WRITING`). The station clock in Echo Station gives `CLUE_STATION_CLOCK`. Use the clue board: it links both clues into `DED_STUCK_AT_417`.
- Solution: link the two clues. Completion: the deduction exists, flag `ch1_clock_dial_unlocked` is set, the dial lock opens.
- Feedback: "Solved", toast "Clues don't fit" when a clue is missing, hints 1 to 3.
- Reset: manual. Save: solved only.
- Optional discovery: the clockmaker's note (`TRC_CH1_CLOCKMAKER_NOTE`) is found with the pulse and Memory Sight.

**1b Sequence: `PZL_CH1_CLOCK_4_17`** (type PATTERN)
- Initial state: dial with keys 1, 2, 4, 7, 9 (digit and notches shown), locked until 1a.
- Rules: press keys one at a time. Solution: 4, 1, 7. A wrong key clears the entry (reset on fail). Progress is saved.
- Completion: three correct keys. Reward: fragment `CH1_F05` (The Clockmaker), flag `ch1_clock_solved`.

## Prototype 2: The Missing Bridge (Reality Shift)
`PZL_CH3_ANCHOR_BRIDGE` (type REALITY_SWAP, completion SCENE_EVENT) in `CH3_M02`. Needs `ABIL_REALITY_SHIFT`. Zone `SHF_CH3_ANCHOR_BRIDGE`.
- Initial state: state `echo_city`: a gap between two platforms, no bridge, no sigil, exit sealed.
- Rules and dependencies:
  1. At Anchor A use Reality Shift: state `other_side`. A bridge appears and a sigil becomes visible on the far platform.
  2. Cross, examine the sigil (clue `CLUE_ANCHOR_SIGIL`, exists only in `other_side`).
  3. At Anchor B use Reality Shift: state `echo_city`. The gate opens only with the sigil clue and `echo_city`.
  4. Use the exit.
- Solution: shift, cross, read the sigil, shift back, exit. Completion: exit used with both conditions met; flag `shift_anchor_bridge_solved`; a permanent bridge appears so nobody is stranded.
- Feedback: hints, "Needs a Shift Anchor" toast, state shown by the scene. Reset: manual. Save: the zone state is saved; the puzzle is solved-only.
- Safe transitions: the player is moved out of a newly solid object. Falling off respawns at the last spawn point.

## Prototype 3: The Reel Order (Time Echo replay + Memory Reconstruction)
`PZL_CH3_TAPE_ORDER` (type MEMORY_RECON) in optional mission `CH3_S01`. Needs `ABIL_TIME_ECHO`.
- Initial state: three reel cards in scrambled places, three empty numbered slots.
- Rules: at the Echo Site use Time Echo to watch `ECH_CH3_TAPE_LOADING`: a figure loads the circle, square and triangle reels in order, with captions and clicks, and the player learns `CLUE_TAPE_ORDER`. Pick a card, place it in a slot. When all slots are full the arrangement is checked; a wrong one clears the slots.
- Solution: circle, square, triangle. Completion: correct arrangement; reward fragment `CH3_F04` (Echo of a Birthday); flag `tape_order_solved`.
- Accessibility: captions for every sound, replay and skip, card and slot names as text.

## Prototype 4: Two Plates, One Person (Time Echo recording, co-op ready)
`PZL_CH3_ECHO_PLATES` (type TIME_ECHO, cooperative, min players 2) in `CH3_S01`. Needs `ABIL_TIME_ECHO`.
- Initial state: two plates far apart, a record zone.
- Rules: both plates must be held at the same time for 1 s. Alone: in the record zone use Time Echo, walk onto plate A, use it again; a ghost replays the walk and stays on plate A. Then stand on plate B. In co-op: two players each hold a plate.
- Completion: both plates held for 1 s; flag `echo_plates_solved`. Reset policy: leaving the location resets an unsolved puzzle and removes ghosts.

## Variety matrix
| Puzzle | Type | Skill | Solution pattern |
|---|---|---|---|
| Clock deduction | Logic discovery | combine evidence | link two clues from different places |
| Clock dial | Sequence | remember a code | enter 4-1-7 |
| Missing bridge | Environmental manipulation | change the world state | shift, cross, read, shift back |
| Reel order | Memory reconstruction | recall an event | arrange three cards |
| Two plates | Cooperative / time | use a recording | hold two places at once |
| Hidden writing and note | Observation | find what is hidden | Memory Sight + pulse |

## Ideas not yet built
Light and Mirror (rotate mirrors to reach a sensor), Sound Echo (match a heard rhythm, always with a visual pattern), Time Echo loop with a moving platform, a two-zone Reality Shift puzzle that uses the exclusive rule, a lullaby pattern puzzle for the Core (ending flag `lullaby_puzzle_solved`).
