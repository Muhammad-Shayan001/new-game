# Gameplay Systems

## Movement
Walk/run via analog (speed scales with stick deflection: walk <0.6, run ≥0.6), context jump/climb on marked ledges only, crouch under marked gaps. Base speed 4.5 m/s. Gravity 9.8. No fall damage; fall-out-of-bounds respawns at last safe point.

## Camera
Third-person orbit, right-side drag to rotate, auto-recentre when moving, collision spring-arm, FOV 65 (settings 55–80), cinematic framing zones trigger fixed/dolly cameras with smooth blend (0.6 s).

## Exploration
Hub-and-spoke districts per chapter, soft gating by memory/ability, landmarks visible from afar, compass-less (uses Memory Pulse hint: hold button to emit a pulse showing nearest unexplored point of interest).

## Interaction
One context button. Interactables expose `prompt_text`, `hold_time`, `requires_flag`. Priority: story > clue > pickup > ambient. Range 2 m, facing cone 70°. Auto-interact option.

## Investigation / Clues
Clues are objects/text/audio. Examining adds to the Journal. Combining two clues in the Journal (Link) can create a Deduction that unlocks a dialogue option or door code. Wrong links only give a gentle "doesn't fit" response.

## Puzzle solving
Types: Pattern/Symbol, Light & Mirror, Sound Echo, Memory Reconstruction (arrange scenes in order), Reality Shift Swap, Time Echo Loop. Every puzzle has 3 hint tiers and a solved-state flag saved in GameState.

## Memory collection
Memory Fragments are glowing orbs/objects. Collecting plays a 10–30 s first-person flashback. Types: Core (story, mandatory), Hidden (optional), Deep (3 total, secret ending). Stored in `GameState.memories`.

## Supernatural abilities
| Ability | Unlock | Function | Limits |
|---|---|---|---|
| Memory Sight | Ch1 | Reveals echoes, hidden writing, clue glow | 8 s, 6 s cooldown |
| Reality Shift | Ch3 | Swap a marked area between Echo City and the Other Side; objects differ | Only at Shift Anchors; 1 area at a time |
| Time Echo | Ch3 | Record 10 s of your actions and replay as a ghost to hold switches/open timing doors | 1 echo (2 after Ch5 upgrade) |
| Echo Voice | Ch5 | Speak a remembered name to calm Forgotten / open sealed doors | Needs relevant Memory |
Abilities have no energy grinding; limits are timer/cooldown only.

## NPC interactions
Dialogue wheel of up to 3 options + optional "Remember" prompts available only if the right memory/clue is owned. Relationship values: `maya_trust`, `archivist_trust`, `forgotten_mercy`. Range −3..+3 each.

## Mission progression
Missions follow MISSION_DESIGN_TEMPLATE.md. States: Locked → Available → Active → Complete. Chapter ends when all Main missions complete.

## Checkpoints
Autosave on mission step, room transition, memory pickup, and every 3 minutes of play (only in safe state). Manual save from pause. 3 manual slots + 1 auto slot.

## Player progression
See PROGRESSION_DESIGN.md. No XP; progression = abilities, access, deductions, memory completion.

## Story decisions
Tracked as flags (see ENDING_DESIGN.md): `spared_forgotten`, `told_maya_truth`, `trusted_archivist`, `destroyed_index_node` (ch5), `kept_wren_memory`, `deep_fragments` count. Decisions are logged to the Journal "Choices" tab so players see what the game remembers.

## Endings
Four: Save, Release, Escape, Secret. Rules in ENDING_DESIGN.md.

## Co-op (optional)
1–4 players, host-authoritative. Co-op adds a separate "Echo Trials" set of puzzle rooms (shared Reality Shift states, split-role puzzles). The campaign is never gated by co-op.
