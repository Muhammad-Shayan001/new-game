# AFTERLIFE.EXE — Game Design Document (v1.0 DRAFT)
Status: READY FOR REVIEW

## 1. Experience
- **Genre:** third-person supernatural mystery-adventure (exploration, investigation, environmental puzzles). Combat-free; tension comes from atmosphere, pursuit sequences and puzzles.
- **Target audience:** 13+ (mature themes of loss, no gore); fans of narrative adventures (Life is Strange, Firewatch, Control-lite). Mobile-first players with 15–30 minute sessions.
- **Player fantasy:** being the one person who can *remember* in a world built to forget.
- **Main objective:** uncover who Alex is, what Echo City is, and decide the fate of the memory system.
- **Identity / USPs:** (1) memory is the progression currency, (2) two reality-bending abilities (Reality Shift, Time Echo) that solve puzzles, (3) choices tracked through six chapters into four foreshadowed endings, (4) fully playable offline, optional 1–4 co-op.
- **Emotional arc:** disorientation → curiosity → dread → grief → resolve → catharsis.
- **Difficulty philosophy:** the mystery is the challenge, not execution. No fail-state deaths; failure rewinds to the last checkpoint with hints escalating (Hint Tiers 1–3, optional).
- **Accessibility:** subtitles on by default with speaker names, adjustable text size, colorblind-safe puzzle cues (shape + color + audio), left/right-handed HUD mirroring, reduced-motion and reduced-flash options, hold-vs-tap toggle, auto-interact assist, full camera sensitivity control, puzzle skip after 3 hint tiers.

## 2. Core loop
Explore → Discover → Investigate → Use ability → Solve puzzle → Memory revelation → Unlock → Return to main story → Consequences (see GAMEPLAY_FLOWCHART.md).

## 3. Systems index
Detailed rules: **GAMEPLAY_SYSTEMS.md**. Missions: **MISSION_DESIGN_TEMPLATE.md**. Progression: **PROGRESSION_DESIGN.md**.

## 4. Structure
Six chapters, ~45–60 min each (~5–6 h main path). Chapter list and canon in STORY_BIBLE.md / CHAPTER_OUTLINES.md.

## 5. Replayability
- Hidden Memory Fragments (5 per chapter, 30 total; 3 are "Deep Fragments" needed for the Secret ending).
- Optional dialogue branches with Maya and the Archivist.
- Four endings (ENDING_DESIGN.md) driven by tracked decisions.
- Chapter Replay from the Memory Archive menu (keeps collectibles, allows decision re-tries in "Alternate Echo" mode without overwriting the main save).
- Post-game: "Echo Gallery" (concept art, cinematics, audio logs) + "Lost Echoes" bonus puzzle rooms unlocked after first ending.

## 6. Out of scope for v1.0
Combat, microtransactions, mandatory online, PvP.
