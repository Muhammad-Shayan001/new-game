# Story State Registry

Every story variable (flag, counter, relationship) used by missions, dialogue, puzzles, echoes and conditions must be registered here. The registry is the folder `resources/story_states/` (one `StoryStateDef` per id). `StoryState` reads and writes values with validation and clamping, and `DataRegistry.validate_all()` fails if content uses a flag that is not registered. Generated from the resources; edit the `.tres` files (or `tools/story_content.gd`), not this table.

Rules:
- Ids are `snake_case` and never change after release (saves store them).
- Engine-created flags `dlg_done_<dialogue id>` and `int_done_<interactable id>` are reserved and need no registration.
- Use the canon names from `ENDING_DESIGN.md` and `GAMEPLAY_SYSTEMS.md`. `maya_trust_level` is an alias of `maya_trust`.
- Relationship states are stored in `GameState.relationships`; all others in `GameState.flags`.

| Id | Type | Range | Chapter | Ending | Set by / meaning |
|---|---|---|---|---|---|
| `alex_found_first_memory` | bool | true / false | 1 |  | Set by CH1_M01. Fragment CH1_F01 (A Name on a Ticket) was recovered. |
| `architect_revelation_seen` | bool | true / false | 5 |  | Set by the Chapter 5 mission where the Architect shows Wren alive inside the Index. |
| `archive_card_received` | bool | true / false | 1 |  | Set at the end of DLG_CH1_M03_CATALOGUE. The Archive Card opens the Forgotten Quarter. |
| `archivist_met` | bool | true / false | 1 |  | Set by DLG_CH1_M03_CATALOGUE when the Archivist first speaks. |
| `archivist_trust` | int | -3 to 3 | 1 | yes | The Archivist's trust in Alex, -3 to +3. |
| `ch1_clock_dial_unlocked` | bool | true / false | 1 |  | Set by puzzle PZL_CH1_CLOCK_DEDUCTION. The clock-room dial becomes usable. |
| `ch1_clock_solved` | bool | true / false | 1 |  | Set by puzzle PZL_CH1_CLOCK_4_17. |
| `ch1_exit_reached` | bool | true / false | 1 |  | Set by CH1_M01 when Alex reaches the Metro Entrance. |
| `ch1_started` | bool | true / false | 1 |  | Set by GameRoot when a new game starts. Unlocks CH1_M01. |
| `deep_fragments` | int | 0 to 3 | 2 | yes | Count of Deep Memory Fragments recovered, 0 to 3. Kept by MemoryManager. |
| `destroyed_index_node` | int | 0 to 3 | 5 | yes | Number of Index nodes Alex destroyed, 0 to 3. Ending variable. |
| `echo_plates_solved` | bool | true / false | 3 |  | Set by puzzle PZL_CH3_ECHO_PLATES. |
| `forgotten_mercy` | int | -3 to 3 | 4 | yes | How merciful Alex was to the Forgotten, -3 to +3. |
| `forgotten_quarter_unlocked` | bool | true / false | 1 |  | Set by CH1_M03 completion. The alley to the Forgotten Quarter opens. |
| `fragments_total` | int | 0 to 30 | 1 |  | Count of all Memory Fragments recovered, 0 to 30. Kept by ProgressionManager. |
| `kept_wren_memory` | bool | true / false | 6 | yes | Decision: Alex kept the Wren memory. Ending variable. |
| `lullaby_puzzle_solved` | bool | true / false | 6 | yes | Set by the Core lullaby puzzle. Required for the secret ending. |
| `maya_met` | bool | true / false | 2 |  | Set by DLG_CH2_M02_CAFE. Alex has talked to Maya. |
| `maya_trust` (alias: maya_trust_level) | int | -3 to 3 | 2 | yes | Maya's trust in Alex, -3 to +3. Changed by dialogue choices. |
| `metro_unlocked` | bool | true / false | 2 |  | Set by CH2_M03 completion. The Static Tunnel to the Underground Metro opens. |
| `other_side_reached` | bool | true / false | 3 |  | Set by CH3_M01 completion. Alex has crossed to the Other Side. |
| `shift_anchor_bridge_solved` | bool | true / false | 3 |  | Set by puzzle PZL_CH3_ANCHOR_BRIDGE. |
| `spared_forgotten` | bool | true / false | 4 | yes | Decision: Alex spared the Forgotten Child. Ending variable. |
| `tape_order_solved` | bool | true / false | 3 |  | Set by puzzle PZL_CH3_TAPE_ORDER. |
| `time_echo_upgraded` | bool | true / false | 5 |  | Set in Chapter 5. Time Echo can hold two ghost copies. |
| `told_maya_truth` | bool | true / false | 5 | yes | Decision: Alex told Maya the truth. Ending variable. |
| `trusted_archivist` | bool | true / false | 5 | yes | Decision: Alex trusted the Archivist. |

## Using states

```gdscript
StoryState.set_value("archivist_met", true)      # validated, emits story_state_changed
StoryState.add_value("maya_trust", 1)           # clamped to -3..3
StoryState.get_value("destroyed_index_node")    # int for INT states, bool for BOOL states
```

In data: `MissionDef.complete_states`, `DialogueNode.set_states`, `DialogueChoice.set_states`, `ConditionSet.states_min / states_max`.
