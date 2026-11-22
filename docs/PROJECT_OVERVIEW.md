# AFTERLIFE.EXE — MASTER PROJECT OVERVIEW & PRODUCTION CHARTER
**Document Version:** 2.0.0 (Production Master)  
**Game Title:** AFTERLIFE.EXE  
**Target Engine:** Godot 4.3+ Mobile Vulkan Clustered / Forward+  
**Primary Platform:** Android 10+ (ARM64)  
**Future Platform:** Windows PC (Steam / Itch.io)  
**Production Budget:** High-Aesthetic Indie / Free & Open-Source Tools (Blender, Krita, Audacity, Git)  
**Game Type:** Single-Player Cinematic Supernatural Mystery (100% Offline Campaign) + Optional 1–4 Player Co-Op  

---

## 1. PROJECT DIRECTIVE & CENTRAL IDENTITY

### 1.1 The Narrative Catalyst
Alex Morgan awakens face-down in a rain-drenched alleyway in **Echo City**, an uncompiled digital purgatory masquerading as a neo-noir metropolis. Alex has no conscious recollection of who they are or how they arrived.  
A cracked smartphone illuminates nearby with a single message:

> **`[UNKNOWN_HOST]: YOU WERE NEVER SUPPOSED TO REMEMBER.`**

Alex must navigate the shifting physical architecture, evade surveillance entities known as **The Watchers**, reconstruct fragmented memories using the supernatural `Memory Vision`, manipulate spatial reality via `Reality Shift`, and uncover the ultimate conspiracy orchestrated by **The Architect**.

### 1.2 Target Experience & Gen-Z Aesthetic Appeal
1. **Neo-Noir Cyber-Gothic Atmosphere:** Rain-slicked tarmac, sodium streetlights, deep phosphor cyan reflections, analog glitch scanlines, and tactile techwear fashion.
2. **Kinetic & Tactile Juice:** Fluid third-person locomotion, camera-relative motion smoothing, footstep foley variations, and contextual Android haptic feedback.
3. **Diegetic Modern Interface:** No archaic floating HUD bars; Alex checks in-game text threads, uses a transit map on their smartphone, and inspects physical 3D clues in close-up macro view.
4. **Emotional & Intellectual Resonance:** A narrative exploring memory loss, digital souls, human grief, and moral choice across four divergent endings.

---

## 2. PRODUCTION ROLES & RESPONSIBILITIES

- **Game Director & Technical Director:** Oversees core loop coherence, architectural modularity, and integration gating.
- **Narrative Director & Screenwriter:** Authors the six-chapter storyline, branching dialogue scripts, and memory timeline lore.
- **World & Level Designer:** Architects Echo City, Underground Metro, Dreamland, and Memory Hospital.
- **3D Character & Environment Artist:** Crafts optimized PBR models (tri-budgets: 22k hero, 1.2k modular walls), materials, and rigs.
- **Gameplay & Puzzle Programmer:** Implements the kinetic player controller, signature abilities (`Memory Vision`, `Reality Shift`, `Time Echo`), and puzzle logic.
- **UI/UX Designer:** Builds the responsive landscape mobile layout, smartphone hub, and accessibility features.
- **Audio Director & Composer:** Mixes the dynamic 4-stem synthwave/lo-fi OST, binaural spatial audio, and tactile foley.
- **Mobile Performance & Release Lead:** Guarantees 30–60 FPS on mid-range Android devices via Vulkan Mobile optimizations.

---

## 3. DEVELOPMENT APPROVAL GATES & STATUS SYSTEM

Every feature and milestone strictly adheres to the status pipeline:
- `NOT STARTED`: Architectural concept phase.
- `IN PROGRESS`: Active code/asset implementation.
- `READY FOR TESTING`: Fully integrated into the test scene with zero compiler warnings.
- `APPROVED`: Verified on Android/PC test hardware against documented acceptance criteria.
- `NEEDS REVISION`: Performance or narrative defect identified.
- `BLOCKED`: Dependency on preceding milestone unsatisfied.

---

## 4. MASTER FILE SYNCHRONIZATION INDEX

The project is governed by the synchronized central document suite located in `docs/`:
- `PROJECT_OVERVIEW.md`: Master charter and governance (this document).
- `GAME_DESIGN_DOCUMENT.md`: Game mechanics, USPs, and player fantasy.
- `STORY_BIBLE.md`: Complete six-chapter narrative lore and emotional arcs.
- `CHARACTER_BIBLE.md`: Character profiles, visual design sheets, and 3D rig specs.
- `WORLD_BIBLE.md`: World regions, atmospheric lore, and environmental storytelling.
- `TECHNICAL_DESIGN_DOCUMENT.md`: Godot 4.x systems architecture and typed GDScript standards.
- `ART_DIRECTION_GUIDE.md`: Master PBR lighting, color palettes, and custom shader specs.
- `UI_UX_GUIDE.md`: Diegetic smartphone HUD, touch ergonomics, and haptics.
- `AUDIO_DIRECTION_GUIDE.md`: Bus routing, dynamic stems, and OST composition.
- `NETWORKING_DESIGN.md`: Optional 1–4 player co-op sync and RPC architecture.
- `ANDROID_PERFORMANCE_GUIDE.md`: ASTC compression, occlusion culling, and thermal budgets.
- `ASSET_REGISTER.md`: Master catalog of all 3D models, textures, audio cues, and shaders.
- `TASK_TRACKER.md`: Active production status and dependency mapping.
- `CHANGELOG.md`: Chronological build history and milestone deliverables.
