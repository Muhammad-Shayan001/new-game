# AFTERLIFE.EXE — UI/UX & DIEGETIC INTERFACE DESIGN GUIDE
**Document Version:** 2.0.0 (Production Master)  
**Lead UI/UX Designer:** Antigravity Mobile Experience Lab  
**Target Platform:** Mobile-First Touchscreen (Android 10+) & Future Gamepad / PC KBM  

---

## 1. DESIGN PHILOSOPHY: ZERO IMMERSION BREAK

Gen-Z players reject cluttered, archaic HUDs with oversized buttons, health bars, and arbitrary floating mini-maps.  
In **AFTERLIFE.EXE**, all interfaces are either **diegetic (existing in-world)** or **minimalist spatial overlays**.

### The Smartphone as the Central Hub ("EchoOS v4.0")
Alex’s shattered smartphone functions as the game's menu, journal, map, and clue database:
1. **Physical Animation:** Swiping down with two fingers or tapping the phone icon smoothly raises Alex’s left hand holding the phone in real-time 3D, blurring the background environment.
2. **Phone Apps:**
   - **`MESSAGES`:** Real-time chat threads from mysterious sender `[UNKNOWN_HOST]`, Maya Reed, and corrupted system pings.
   - **`MAPS.EXE`:** A minimalist vector transit map of Echo City showing discovered subway lines and safe havens.
   - **`MEMORY_VAULT`:** Audio memo recordings, scanned polaroids, and encrypted memory fragments that can be decrypted via mini-games.
   - **`SETTINGS.SYS`:** Audio balance, graphics scaler, subtitle sizing, and touch calibration.

---

## 2. TOUCHSCREEN ERGONOMICS & INTERACTION ZONES

### 2.1 Landscape Ergonomic Heatmap (Thumb Comfort Zones)

```
+-----------------------------------------------------------------------------------------+
| [SAFE: Notch/Camera Island]                                                             |
|                                                                                         |
|  [LEFT THUMB PRIMARY]                                           [RIGHT THUMB PRIMARY]   |
|   - Dynamic Floating Joystick                                    - Contextual Action    |
|   - Tap anywhere in left 40%                                     - Ability Radial Wheel |
|                                                                                         |
|                                   [NEUTRAL TOUCH ZONE]                                  |
|                                  Camera Swipe & Orbit                                   |
|                                                                                         |
|  [CORNER SHORTCUT]                                              [CORNER SHORTCUT]       |
|   - Crouch / Stealth Tap                                         - Phone / Menu Pullup  |
+-----------------------------------------------------------------------------------------+
```

### 2.2 Control Specifications
1. **Dynamic Floating Joystick:**
   - Spawns at exact touch-down coordinates within the left quadrant.
   - Deflection `< 50%`: Precise stealth walk ($2.2\text{ m/s}$).
   - Deflection $\ge 50\%$: Dynamic jog ($4.5\text{ m/s}$).
   - Double-tap edge or dedicated Sprint toggle: Adrenaline sprint ($7.2\text{ m/s}$) with camera FOV kick.
2. **Contextual Interaction Button:**
   - Appears dynamically with a smooth scale-in animation when `Player.interaction_ray` detects an interactable object (`layer_3: interactable`).
   - Displays clear verb prompts: `[ INSPECT ]`, `[ TALK ]`, `[ HACK ]`, `[ SHIFT ]`.
3. **Radial Ability Selector:**
   - Press-and-hold the Supernatural glyph on the right thumb area expands a 4-way slow-motion selection wheel:
     - **North:** `Memory Vision`
     - **East:** `Reality Shift`
     - **South:** `Echo Detection`
     - **West:** `Time Echo`

---

## 3. ADVANCED HAPTIC VIBRATION PROFILES (ANDROID)

Haptics are synchronized with gameplay events via Android `VibrationEffect` API:

| In-Game Event | Waveform Pattern | Amplitude & Frequency | Psychological Intent |
| :--- | :--- | :--- | :--- |
| **Phone Notification** | Double click: `[40ms, 80ms, 40ms]` | Sharp, crisp ($180\text{Hz}$) | Familiar, real-world smartphone sensation |
| **Supernatural Anomaly**| Sine pulse: `[120ms fade-in, 60ms dip]`| Low frequency ($70\text{Hz}$) rumble | Unsettling, organic dread (pulsing heartbeat) |
| **Lock / Dial Click** | Micro tick: `[15ms]` | Ultra-high ($240\text{Hz}$) | Mechanical tactile satisfaction |
| **Reality Shift Pulse** | Sawtooth explosion: `[250ms high, 100ms fade]`| Max amplitude ($120\text{Hz}$) | Jarring sensory shock of space ripping open |

---

## 4. THE MEMORY ROOM (THE MIND PALACE)

Accessed when Alex rests at safe rooms or touches a Memory Resonance Nexus.
- **Visuals:** An endless minimalist gallery floating in black void with gentle water ripples beneath Alex's feet.
- **The Case Wall:** Red yarn connections dynamically link discovered suspects, memory fragments, and audio logs.
- **Timeline Reconstruction:** Players drag and drop collected memory clips into chronological order. When solved correctly, an exclusive cinematic flashback unlocks, revealing pivotal story lore.

---

## 5. ACCESSIBILITY & CUSTOMIZATION SUITE

1. **Subtitles & Closed Captions:**
   - 4 size presets: Small ($16\text{pt}$), Medium ($22\text{pt}$), Large ($28\text{pt}$), High-Visibility ($34\text{pt}$ with high-contrast black box backing).
   - Speaker name color coding (Alex: `#00F0FF`, Maya: `#FFD54F`, Archivist: `#B39DDB`, Unknown: `#FF2A55`).
   - Sound effect captions with directional indicators (e.g., `[Footsteps echoing behind you ➔]`).
2. **Touch Target Customization:**
   - Adjustable UI scale ($80\%$ to $130\%$).
   - Left-handed mode flips joystick and action buttons.
   - Touch sensitivity slider for camera pan inertia.
3. **Colorblind Filters:**
   - Built-in screen shaders for Protanopia, Deuteranopia, and Tritanopia, ensuring memory vision clues remain distinct across all vision profiles.
