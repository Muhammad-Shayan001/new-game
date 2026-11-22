# AFTERLIFE.EXE — CINEMATIC SCRIPT & DIRECTOR SHOT LIST
**Document Version:** 2.0.0 (Production Master)  
**Cinematic Director:** Antigravity Motion Pictures & Narrative Lab  
**Aspect Ratio:** 2.39:1 CinemaScope (Rendered dynamically in Godot 4 via Viewport overlay)  

---

## SCENE 01: THE AWAKENING (OPENING CINEMATIC)
**Duration:** 2 Minutes, 35 Seconds  
**Location:** Alleyway 04, Echo City District 1  
**Time / Weather:** Midnight / Heavy Rain, Distant Thunder, Flickering Neon  
**Music:** *"Terminal Awakening"* — Minimal sub-bass drone and isolated piano keystrokes.

---

### [SHOT 01] EXTREME CLOSE-UP — RAINDROP ON ASPHALT
- **Visual:** A single slow-motion raindrop falls into a puddle reflecting a neon billboard (`"ETERNAL PEACE // NEURO-CORP"`). As the ripple expands, the water surface jitters with digital scanlines.
- **Audio:** Crisp water impact, immediate low-pass filter hum.
- **Camera:** Static macro lens, 85mm, shallow DoF.

### [SHOT 02] WIDE LOW ANGLE — ALEX'S BODY
- **Visual:** Alex lies motionless on wet tarmac in a puddle of rainwater. The dark nylon trench coat is soaked. Rain cascades down Alex’s pale face.
- **Lighting:** Raking orange sodium streetlight cut by silhouettes of rain falling through fire escape grates.
- **Camera:** Slow upward crane tracking back, tilting down from 15° to 45°.

### [SHOT 03] CLOSE-UP — THE SHATTERED PHONE
- **Visual:** 30 centimeters from Alex's limp hand, a smartphone screen suddenly pulses with white luminescence. The glass is spider-web cracked.
- **Audio:** Sharp, vibrating phone buzz: *BZZZ-BZZZ...* (Android haptic profile fires).
- **On-Screen Display (Phone Screen):**
  ```text
  ┌──────────────────────────────────────────────────────────┐
  │ [!] NEW MESSAGE FROM UNKNOWN_HOST                        │
  │ "YOU WERE NEVER SUPPOSED TO REMEMBER."                  │
  └──────────────────────────────────────────────────────────┘
  ```

### [SHOT 04] MEDIUM SHOT — ALEX AWAKENS
- **Visual:** Alex gasps sharply, chest heaving. Fingers twitch and dig into the wet asphalt. Alex props up on one elbow, shivering violently from the cold.
- **Animation:** Mocap blend: `gasp_awake` $\rightarrow$ `prop_elbow` $\rightarrow$ `touch_temple`.
- **VFX:** A faint cyan circuit pattern flickers on Alex’s left temple.
- **Alex (V.O. / Subtitle):** *(Whispered, hoarse)*
  > "Where... am I? Everything smells like ozone and rust."

### [SHOT 05] OVER-THE-SHOULDER — THE STRANGE MESSAGE
- **Visual:** Alex crawls forward, picking up the wet phone. The screen flickers violently, glitching into green phosphor raster lines before snapping to a new line:
  ```text
  ┌──────────────────────────────────────────────────────────┐
  │ [!] SYSTEM WARNING: ANOMALY LOCATED                      │
  │ "YOU ARE DEAD. BUT YOUR STORY ISN'T OVER."              │
  │ SEEK THE SUBWAY ENTRANCE. HE IS WAITING.                │
  └──────────────────────────────────────────────────────────┘
  ```

### [SHOT 06] SEAMLESS CONTROL HANDOFF (CAMERA INTERPOLATION)
- **Visual:** Alex stands up, swaying slightly. Alex slips the phone into the trench coat pocket and looks down the alley toward the flickering neon street ahead.
- **Technical Transition:** The cinematic black letterbox bars slide vertically off-screen over 1.2 seconds. The camera smoothly orbits around Alex to take up the default third-person gameplay position (Over-The-Right-Shoulder, 52° FOV).
- **HUD Trigger:** The floating virtual joystick and interaction prompt fade in with 40% opacity.
- **Objective Banner:** `[ OBJECTIVE: INVESTIGATE THE RAIN-SOAKED STREET ]`

---

## SCENE 02: THE ARCHIVIST'S ENCOUNTER
**Location:** Abandoned Subway Station Concourse  
**Characters:** Alex Morgan, The Archivist  

### [SHOT 01] MEDIUM TWO-SHOT
- **Visual:** The Archivist stands beside an old turnstile holding a heavy leather-bound ledger. Golden digital wireframe fragments float around his left arm.
- **Archivist:**
  > "Welcome back, Number Seven. Or should I call you by the name you gave yourself before you forgot?"
- **Alex:**
  > "You know who I am? Tell me how to get out of this place."
- **Archivist:**
  > *(Chuckles softly, turning a page)*
  > "One does not simply 'leave' an archive, Alex. One is either cataloged... or deleted. Show me what you remember, and perhaps the city will allow you to pass."
- **Gameplay Trigger:** Launches the first interactive Dialogue Choice Tree with the Archivist.
