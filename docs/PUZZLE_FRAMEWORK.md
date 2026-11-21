# Puzzle Framework

## What every puzzle defines
Every puzzle is a `PuzzleDef` resource (`resources/puzzles/<id lower>.tres`). `validate()` and the content validator reject a puzzle that leaves a required part empty.

| Requirement | Field(s) |
|---|---|
| Puzzle ID | `id` (`PZL_<NAME>`) |
| Required abilities | `required_abilities` (checked by `PuzzleManager.can_attempt`; a missing ability shows a gentle toast) |
| Initial state | `initial_state` (documented starting configuration) |
| Interaction rules | `puzzle_type` and the scene components that send input (Interactables, board, plates, anchors) |
| Correct solution | `solution`, or the scene rule named in `design_notes` |
| Feedback | `success_key`, `failure_key`, `feedback_cue`; defaults "Solved" and "That is not it. Take your time." No penalties, no health loss |
| Completion condition | `completion`: SOLUTION_MATCH, SCENE_EVENT or DEDUCTION, plus `set_flags` and rewards (`reward_clues/items/fragments`) |
| Reset behavior | `reset_policy`: MANUAL, ON_FAIL (wrong entry clears) or ON_LEAVE (leaving the location clears an unsolved puzzle) |
| Save behavior | `save_policy`: SOLVED_ONLY or PROGRESS (partial entry is saved and restored) |
| Accessibility | `accessibility_notes` (required), three hint tiers (required), optional skip (setting) |
| Co-op | `cooperative`, `min_players` (a Time Echo ghost replaces the missing player in solo play) |

## Runtime
```
Scene component --submit(id, value) / mark_solved(id)--> PuzzleManager --> PuzzleRuntime (per type)
                                                     \--> GameState.puzzles[id] = {solved, hints, progress}
                                                     \--> EventBus: puzzle_started / attempt_failed / hint_given / reset / solved
```
- `PuzzleRuntime` subclasses hold the logic: `PatternRuntime` (symbols in order) and `OrderingRuntime` (full arrangement, also for Memory Reconstruction). Other types are scene-driven and call `mark_solved(id)`.
- To add a built-in type: subclass `PuzzleRuntime` (`submit`, `reset`, `export_state`, `import_state`) and add one case in `PuzzleManager._make_runtime()`.
- Hints: `request_hint(id)` returns tier 1, 2, 3 (stays on 3). Accessibility option `puzzle_skip` allows `skip_puzzle(id)` only after tier 3.
- Missions follow puzzles through `ObjectiveDef.Kind.PUZZLE`.

## Reusable scene components
| Component | Script | Use |
|---|---|---|
| Symbol key | `Interactable` with `puzzle_id` + `puzzle_symbol` | dials, switches, tiles |
| Solve trigger | `Interactable.solve_puzzle` | exits and levers of scene-driven puzzles |
| Clue board | `ClueBoard` | logic puzzles: link two clues into a Deduction |
| Reconstruction board | `ReconstructionBoard` | pick a card, place it in a numbered slot |
| Pressure plate and controller | `PressurePlate`, `PlateController` | hold all plates at once (players, ghosts) |
| Condition gate | `ConditionGate` | door or barrier that follows any `ConditionSet` |
| Revealable and memory trace | `Revealable`, `MemoryTrace` | observation puzzles with Memory Sight |
| Shift anchor and object | `ShiftAnchor`, `ShiftableObject` | environmental manipulation |
| Echo site | `EchoSite` | replays and recording zones |

## Accessibility rules for puzzle design
1. No timers or reaction tests. Holds are 1 s, recording is 10 s and forgiving.
2. Nothing relies on colour alone: symbols have text names and numbers.
3. Every sound that matters has a caption. Echoes can be replayed and skipped.
4. Three hints and an optional skip. Failure never costs anything.
5. Progress survives leaving where it matters (`save_policy = PROGRESS`).
6. Reduce motion removes fades and the shift transition delay.
