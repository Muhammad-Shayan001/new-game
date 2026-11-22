# AFTERLIFE.EXE — MASTER ARCHITECTURAL & DESIGN DECISION LOG
**Document Version:** 1.0.0  
**Repository Source of Truth:** `docs/DECISION_LOG.md`  
**Maintainers:** Antigravity Game & Technical Directorial Team  

---

## 1. DECISION REGISTER

### DEC-001: Mobile-First Vulkan Clustered / Forward+ Rendering
- **Date:** 2026-11-21
- **Status:** APPROVED
- **Context:** Deciding rendering method for Godot 4.x on Android with future PC scalability.
- **Decision:** Target Godot 4.3 Mobile Renderer (Vulkan Mobile Clustered) as baseline, with Forward+ capability on PC and Flagship Android.
- **Rationale:** Mobile Vulkan provides the ideal balance between high-end modern features (volumetric fog, clustered dynamic lights, screen-space reflections) and thermal efficiency on mid-range chipsets.
- **Consequences:** All shaders must be authored without expensive branching. Texture formats strictly enforce ASTC compression.

### DEC-002: Diegetic Smartphone Interface ("EchoOS v4.0")
- **Date:** 2026-11-21
- **Status:** APPROVED
- **Context:** HUD and menu presentation strategy for Gen-Z audience.
- **Decision:** Abandon floating traditional game HUDs (minimaps, health bars). All player navigation, messaging, audio logs, and settings live inside Alex's in-game 3D smartphone.
- **Rationale:** Preserves 100% immersion; turns UI interaction into a tactile physical gameplay element.
- **Consequences:** UI scenes must render cleanly both on screen overlays and within 3D in-hand viewport textures.

### DEC-003: Third-Person Kinetic Locomotion & Camera Collision Cushioning
- **Date:** 2026-11-21
- **Status:** APPROVED
- **Context:** Movement feel and camera control across mobile touchscreen and PC.
- **Decision:** Implement camera-relative movement with 3-tier speeds (Walk, Run, Sprint), velocity acceleration/deceleration smoothing, dynamic spring-arm collision avoidance, and haptic footstep cadence.
- **Rationale:** Third-person cinematic mystery requires grounded weight; avoids floaty, disorienting navigation in tight indoor corridors.
- **Consequences:** Player controller script abstracts input completely through `InputService`.

### DEC-004: Asymmetrical Co-Op ("Divergent Perception")
- **Date:** 2026-11-21
- **Status:** APPROVED
- **Context:** Integrating optional 1–4 player co-op without harming the single-player campaign.
- **Decision:** Multiplayer operates as an optional listen-server session where players possess divergent investigation abilities (Player 1 has Memory Vision; Player 2 has Reality Shift). Single-player campaign remains 100% playable offline.
- **Rationale:** Prevents co-op from being a generic clone experience; incentivizes genuine verbal communication and clue exchange.
- **Consequences:** Single-player assigns all abilities to Alex sequentially; co-op distributes roles dynamically across connected peer IDs.

### DEC-005: 4-Tier Save System with Version Migration & Backup Integrity
- **Date:** 2026-11-21
- **Status:** APPROVED
- **Context:** Save file corruption prevention on mobile battery deaths or forced app closures.
- **Decision:** SaveManager implements atomic file writing (`.tmp` $\rightarrow$ `.sav`), automated backup copies (`.bak`), SHA-256 data checksum verification, and structured schema version migrations (v1 $\rightarrow$ v2 $\rightarrow$ v3).
- **Rationale:** Guarantees player progress is never corrupted by sudden OS process termination on Android.
- **Consequences:** Save schema strictly managed in `DATA_SCHEMA.md`.

### DEC-006: Four Foreshadowed Narrative Endings
- **Date:** 2026-11-21
- **Status:** APPROVED
- **Context:** Campaign climax and player agency.
- **Decision:** Implement four distinct endings (`SAVE`, `RELEASE`, `ESCAPE`, `SECRET`) governed by tracked cumulative choices and discovered memory keys.
- **Rationale:** Ensures player investigation choices carry genuine thematic weight and high replay value.
- **Consequences:** Story flags are registered centrally in `STORY_STATE_REGISTRY.md`.
