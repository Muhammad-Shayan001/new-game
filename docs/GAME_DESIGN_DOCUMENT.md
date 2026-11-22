# AFTERLIFE.EXE — MASTER GAME DESIGN DOCUMENT (GDD)
**Document Version:** 2.0.0 (Production Master)  
**Lead Game Designer:** Antigravity Game Design Studio  
**Target Engine:** Godot 4.3+ Mobile Vulkan Clustered / Forward+  
**Primary Platform:** Android 10+ (Landscape Mobile) | **Secondary Platform:** Windows PC  
**Genre:** Cinematic Third-Person Supernatural Mystery Adventure  

---

## 1. EXECUTIVE SUMMARY & EXPERIENCE VISION

### 1.1 The Player Fantasy
The player embodies **Alex Morgan**, waking with retro-amnesia in a rain-soaked digital purgatory known as **Echo City**. The core fantasy is being the solitary awake consciousness in an uncompiled digital metropolis designed to sanitize and erase human grief. Through supernatural perception (`Memory Vision`, `Reality Shift`, and `Time Echo`), the player reconstructs deleted memories, investigates environmental mysteries, and unravels the moral conflict between blissful digital forgetting and painful human truth.

### 1.2 Core Pillars
1. **Intimate Cinematic Investigation:** Every clue, note, and environmental detail matters. The game avoids generic waypoint-chasing in favor of diegetic exploration, visual landmarks, and environmental breadcrumbing.
2. **Tactile Supernatural Mechanics:** Abilities are physicalized investigation tools, not combat superpowers. They allow players to shift space, view holographic temporal echoes, and reveal hidden layers of memory.
3. **Emotional Agency & Meaningful Consequences:** Player dialogue choices and discovered memory keys culminate in four logically foreshadowed endings (`SAVE`, `RELEASE`, `ESCAPE`, `SECRET`).
4. **Mobile Ergonomics Without Compromise:** Grounded, responsive third-person locomotion, dynamic camera collision cushions, and tactile Android haptics calibrated specifically for landscape touchscreens.

---

## 2. THE CORE GAMEPLAY LOOP

```
+-----------------------------------------------------------------------------------+
|                              PRIMARY INVESTIGATION LOOP                           |
|                                                                                   |
|  [EXPLORE]  ----->  [DISCOVER]  ----->  [INVESTIGATE]  ----->  [SUPERNATURAL]     |
|   Navigate           Notice damp        Inspect 3D            Activate Vision /   |
|   Atmosphere         anomaly / prop     clue / audio          Shift / Time Echo   |
|       ^                                                               |           |
|       |                                                               v           |
|  [CONSEQUENCE] <--  [REVELATION] <----  [UNLOCK]  <---------  [SOLVE PUZZLE]      |
|   Story branch &     Memory recovered,   New district /        Reconstruct state, |
|   Ending flags       Dialogue update     Subway opens          Overcome barrier   |
+-----------------------------------------------------------------------------------+
```

---

## 3. GAMEPLAY SYSTEMS ARCHITECTURE

### 3.1 Third-Person Locomotion
- **Speeds:** Walk ($2.4\text{ m/s}$), Jog/Run ($4.8\text{ m/s}$), Sprint ($7.2\text{ m/s}$).
- **Kinetic Physics:** Camera-relative movement, smooth velocity acceleration ($14.0\text{ m/s}^2$) and deceleration ($18.0\text{ m/s}^2$), responsive angular turning ($12.0\text{ rad/s}$), and procedural footstep foley modulation.
- **Collision & Gravity:** $9.8\text{ m/s}^2$ downward pull, zero-slip slope clamping up to $45^\circ$, and automatic out-of-bounds respawn safety.

### 3.2 Dynamic Third-Person Camera Rig
- **Exploration Mode:** Over-the-right-shoulder, 2.8m spring arm, 52° FOV, vertical offset +1.4m.
- **Narrow Interior Mode:** Dynamically pulls in to 1.8m, widens FOV to 62° to prevent clipping.
- **Macro Inspection Mode:** Seamless dolly-in to full-screen 3D inspect view for tactile evidence examination.
- **Collision Cushioning:** Raycast & shape-cast collision probes adjust spring arm length smoothly to avoid wall penetration.

### 3.3 Supernatural Investigation Abilities
1. **Memory Vision:** Desaturates physical reality to charcoal slate, exposing glowing electric vermilion memory imprints, UV text, and forgotten footsteps.
2. **Reality Shift:** Transitions active physical zones into alternate computational states (The Under-Code / Past Reality), opening alternate routes and altering object configurations.
3. **Time Echo:** Holographic replay of past events using transparent scan-raster silhouettes, allowing players to scrub time and discover hidden combinations and actions.
4. **Echo Detection:** Frequency-based directional pulse providing visual, audio, and haptic feedback when approaching concealed memory anomalies.

### 3.4 Puzzle Design Framework
- **Categories:** Observation, Memory Reconstruction, Pressure Sequence, Spatial Reality Manipulation, and Logic Dials.
- **Design Standard:** Every puzzle is governed by a strict `PuzzleDef` schema with explicit initial states, interaction rules, completion feedback, hint escalation (Tiers 1–3), and automatic save-state persistence.

---

## 4. MISSION & PROGRESSION DESIGN

- **Narrative-Driven Progression:** Progress is measured in unlocked memory fragments, revealed character dossiers, and narrative trust states rather than grinding levels or stats.
- **Data-Driven Missions:** Authored via `MissionDef` resources supporting mandatory objectives, optional investigative discoveries, checkpoint recovery, and branching story flags.
- **Checkpoint System:** Automatic checkpoint triggers after pivotal story interactions, puzzle solutions, and district transitions.

---

## 5. ACCESSIBILITY & INCLUSIVITY

- **Visual:** Subtitles enabled by default with speaker color-coding, adjustable text sizing (16pt to 34pt), high-contrast text boxes, and colorblind-safe memory cues (shape + color + sound).
- **Physical/Motor:** Left/right-handed virtual stick mirroring, touch target scaling (80% to 130%), adjustable camera sensitivity, and optional puzzle skip after viewing all hint tiers.
- **Auditory:** Full closed captions with directional sound indicators, dedicated master/music/SFX/voice volume sliders, and tactile haptic alternatives for audio cues.

---

## 6. PLATFORM INPUT ABSTRACTION

All gameplay systems read strictly from `InputService` and `InputActions`. The platform-agnostic design ensures identical behavior across:
- **Android Touch:** Dynamic floating virtual joystick, contextual action buttons, and camera swipe surfaces.
- **Gamepad:** Xbox / PlayStation / Razer Kishi Bluetooth gamepads with auto-detected input glyphs.
- **PC:** Keyboard (WASD) and Mouse look with raw input capture.
