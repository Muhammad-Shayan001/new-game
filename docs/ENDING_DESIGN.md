# Ending Design

## Tracked variables
| Variable | Range | Set by |
|---|---|---|
| `spared_forgotten` | bool | CH2 Whispering Man |
| `told_maya_truth` | bool | CH4 |
| `maya_trust` | −3..+3 | optional dialogue |
| `archivist_trust` | −3..+3 | CH1, CH3, CH5 choices |
| `forgotten_mercy` | −3..+3 | encounters with Forgotten |
| `destroyed_index_node` | 0–3 | CH5 Three Nodes |
| `kept_wren_memory` | bool | CH5 decision |
| `deep_fragments` | 0–3 | hidden fragments CH2, CH4, CH5 |
| `fragments_total` | 0–30 | all fragments |

## Endings
### 1. SAVE — "Keep the Light On"
Alex keeps the Index running, stabilizes it, and wakes while Wren and Echo City persist.
- **Requires:** `destroyed_index_node` = 0, `archivist_trust` ≥ 0, `kept_wren_memory` = true.
- **Foreshadowing:** Architect's sympathetic speeches, nursery warmth, Archivist's "preservation is also love".
- **Outcome:** bittersweet. Echo City becomes a shared mourning space; consequences shown for Maya, the Forgotten (spared if `spared_forgotten`).

### 2. RELEASE — "Let Go"
Alex lets Wren go and shuts the Index down; Echo City dissolves; Alex wakes.
- **Requires:** `destroyed_index_node` ≥ 2, `told_maya_truth` = true.
- **Foreshadowing:** Archivist's "Instruction 0", the lullaby's final line changing key.
- **Outcome:** grief and peace. The Architect says goodbye; Maya is at the bedside.

### 3. ESCAPE — "Forget Me"
Alex leaves alone, accepting the Architect's offer to forget; wakes with fragments of memory only.
- **Requires:** `maya_trust` ≤ 0 or `archivist_trust` ≤ −2, and `forgotten_mercy` ≤ 0.
- **Foreshadowing:** the blank card, repeated "stop remembering" warnings.
- **Outcome:** tragic. Alex wakes but loses Wren permanently; the Index continues.

### 4. SECRET — "Remember Everything"
Alex remembers all of Wren, her death, and their father, then sings the lullaby; Wren walks out of the Index as a *memory*, not a prisoner. The Architect forgives himself.
- **Requires:** `deep_fragments` = 3, `archivist_trust` ≥ 2, `maya_trust` ≥ 2, `spared_forgotten` = true, `destroyed_index_node` = 1 (only the Control Node), and the Time Echo lullaby puzzle solved at the Core.
- **Foreshadowing:** each Deep Fragment contains one line of the lullaby; the unfilled chair (Ch2) is filled at the end.
- **Outcome:** hopeful. Alex wakes with full memory; Wren's memory lives on.

## Resolution order
At CH6_M03, evaluate: Secret → Release → Save → Escape (first match wins); default fallback is Escape.

## Anti-meaningless-choice rule
Each decision must change at least one visible line, scene, or ending eligibility; the Journal "Choices" tab lists them.
