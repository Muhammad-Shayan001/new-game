# AFTERLIFE.EXE — CHARACTER BIBLE & 3D ASSET SPECIFICATION
**Document Version:** 2.0.0 (Production Master)  
**Lead Narrative Director & 3D Character Artist:** Antigravity Character Studio  

---

## 1. ALEX MORGAN (THE PROTAGONIST)

### 1.1 Psychological Profile & Identity
- **Age:** 23
- **Role:** The Awakened Anomaly / Memory Diver
- **Voice/Personality:** Guarded, observant, dry wit under pressure, emotionally wounded but resilient. Alex speaks with quiet determination rather than theatrical heroics.
- **Visual Design & Gen-Z Aesthetic:**
  - Modern techwear/streetwear silhouette: Oversized dark slate waterproof trench coat with neon-lined interior seams, distressed black knit sweater, tactical cargo trousers, weathered waterproof boots.
  - Face: Androgynous, tired hazel eyes, dark wavy hair undercut with damp strands falling over forehead, a faint holographic scar across the left temple that pulses cyan when using `Memory Vision`.
  - Accessory: A cracked smartphone in a rugged lanyard case worn across the chest.

### 1.2 3D Character Specifications
- **Base Triangle Budget:** 22,000 Triangles (LOD0).
- **Skeleton / Rig:** Humanoid hierarchy with 64 deformation bones:
  - Full finger articulation for inspecting tactile clues and smartphone operation.
  - 4 spring bones for coat tails and 2 spring bones for hair physics.
- **Facial Blendshapes (ARKit Standard):**
  - 52 blendshapes supporting micro-expressions: brow raise, squint, jaw clench, subtle eye darting, speaking phonemes (`A`, `O`, `E`, `M`, `L`).
- **Signature Animations:**
  - `idle_rain_shiver`: Shifts weight between feet, glances down at glowing phone screen.
  - `inspect_clue`: Smoothly reaches out right hand, holds item up to eye level, turns it slowly.
  - `ability_channel`: Closes eyes, fingers tap left temple as holographic scar lights up.

---

## 2. MAYA REED (THE GROUNDING TETHER)

### 2.1 Psychological Profile & Lore
- **Age:** 24
- **Role:** Survivor, Former Metro Signal Technician, Alex’s lost connection.
- **Personality:** Pragmatic, tech-savvy, emotionally cautious, harborer of immense guilt over the catastrophe that created Echo City.
- **Visual Design:**
  - High-visibility retro-industrial jacket covered in DIY reflective tape patches, fingerless wool gloves, military-surplus backpack packed with radio transmitters and antenna gear.
  - Short auburn bob, sharp brown eyes, grease smudge across the cheekbone.
- **3D Specifications:** 16,500 Triangles; 2048x2048 PBR maps; custom radio backpack rig with physics antenna jiggle.

---

## 3. THE ARCHIVIST (THE AMBIGUOUS GUIDE)

### 3.1 Psychological Profile & Lore
- **Age:** Unknown (Appears late 40s)
- **Role:** Keeper of the Forgotten Archives, Curator of Deleted Realities.
- **Personality:** Enigmatic, courteous, speaking in cryptic metaphors about data conservation and human memory as volatile cache.
- **Visual Design:**
  - Severe, tailored 19th-century charcoal overcoat interwoven with fiber-optic threading. Half of his face appears normal; the other half dissolves into subtle golden wireframe polygons that reassemble like clockwork.
  - Speaks with a resonance filter that layers two voices—one warm, one digital.
- **3D Specifications:** 18,000 Triangles; animated emissive wireframe shader applied to left facial quadrant.

---

## 4. THE ARCHITECT (THE SYSTEM CREATOR / ANTAGONIST)

### 4.1 Psychological Profile & Lore
- **Role:** The Core Administrator of the Purgatory Simulation.
- **Motivation:** Believes humanity’s greatest agony is unresolved grief and traumatic memory. Echo City was designed as an eternal loop where human minds could forget pain—by forgetting everything. Alex’s reawakening threatens to collapse the system.
- **Visual Design:**
  - A shifting, towering silhouette whose form alternates between a sleek corporate executive in a white tailored coat and a colossal polygonal entity composed of floating glass monitors and neon server racks.

---

## 5. THE FORGOTTEN CHILD (THE CATALYST)

### 5.1 Psychological Profile & Lore
- **Role:** The original seed memory from which Echo City sprouted.
- **Visual Design:**
  - A small, translucent child holding an antique brass birdcage. Leaves luminous puddles where they walk. Does not speak with words; communicates through audio radio static and shifting graffiti drawings on city walls.
- **3D Specifications:** 8,000 Triangles; ethereal Fresnel alpha transparency shader.

---

## 6. SUPERNATURAL ENTITY CATALOG (AI ANOMALIES)

1. **The Watcher:** Tall, slender shadow entity with three camera-shutter eyes that tracks the player from rooftops. Freezes when Alex stares directly at them.
2. **The Echo:** A flickering digital ghost of a past citizen trapped in an emotional loop (screaming, running, looking for lost keys).
3. **The Mimic:** An anomaly disguised as ordinary street props (a neon sign, a public bench, a trash receptacle) that unfurls into a glitching spider-like threat when approached.
