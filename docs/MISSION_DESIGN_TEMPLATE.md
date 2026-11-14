# Mission Design Template
All `Location` fields must use IDs from LOCATION_REGISTER.md.
Copy for each mission. All fields required.

```
Mission ID:            CH#_M## (e.g. CH1_M01)
Mission name:
Type:                  Main | Secondary
Chapter:
Location:
Story purpose:
Starting conditions:   (flags required, player position, time/weather)
Main objective:
Secondary objectives:
Required interactions:
Puzzle requirements:   (puzzle ID, type, hint tiers)
Character involvement: (speaker IDs)
Completion conditions: (flags set / items / locations)
Failure recovery:      (checkpoint, reset rules, no hard fail)
Rewards:               (memory fragment, ability, clue, access)
Unlock conditions:     (which mission/flag opens it)
Testing criteria:      (pass/fail checklist, edge cases, device targets)
Estimated duration:
```

## Example — CH1_M01 "Static"
- Type: Main · Chapter 1 · Location: `LOC_UM_ECHO_STATION` → `LOC_UM_CONCOURSE` → `LOC_EC_METRO_ENTRANCE`
- Purpose: teach movement, camera, interaction.
- Start: Alex wakes on bench; flag `ch1_started`.
- Main objective: Reach the station exit.
- Secondary: Find 3 lost-luggage tags (clues).
- Interactions: broken terminal (E), turnstile.
- Puzzle: none (tutorial).
- Characters: ARV (voice over speakers).
- Completion: `ch1_exit_reached` = true.
- Failure recovery: none required; out-of-bounds respawn at bench.
- Rewards: Memory Fragment CH1_F01 "A Name on a Ticket".
- Unlock: `ch1_started`.
- Testing: movement at walk/run thresholds, camera collision, interact prompt appears at 2 m, save/load mid-mission.
