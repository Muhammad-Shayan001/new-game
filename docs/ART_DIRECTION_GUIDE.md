# AFTERLIFE.EXE — ART DIRECTION & VISUAL DESIGN GUIDE
**Document Version:** 2.0.0 (Production Master)  
**Lead Art Director & Environment Lead:** Antigravity Production Studio  
**Target Engine:** Godot 4.3+ Mobile Vulkan Clustered / Forward+  
**Target Mood:** Neo-Noir Cyber-Gothic, Analog Glitch-Horror, Rain-Drenched Melancholy, Vapor-Phosphor High Contrast  

---

## 1. CORE VISUAL PILLARS ("GEN-Z CULT AESTHETIC")

### 1.1 The "Digital Purgatory" Philosophy
Echo City is not just a dark city; it is an uncompiled reality. It balances photorealistic urban grit (damp tarmac, peeling street wheatpaste, neon store signage) with surreal computational rot:
- **Photorealism at Ground Level:** Real-world materials—brushed wet stainless steel, wet bitumen, condensation on double-glazed phone booths, cracked tempered smartphone glass.
- **Digital Anomalies in the Periphery:** The horizon doesn't just fade into fog; it dissolves into wireframe tessellation, chromatic fringing, and flickering voxel artifacts when Alex’s mental stability drops.
- **Cinematic Framing:** Wide 2.39:1 anamorphic crop during dialogue and cutscenes, dynamic Dutch tilts during psychological shifts, and shallow depth of field (DoF) focusing on Alex's expressive reactions.

### 1.2 Signature Color Palettes

| Zone / Context | Primary (60%) | Secondary (30%) | Accent / High Energy (10%) | Emotional Resonance |
| :--- | :--- | :--- | :--- | :--- |
| **Echo City (Night Rain)** | Deep Obsidian Asphalt `#0A0D12` | Sodium Streetlight `#E5A93C` | Phosphor Cyan Neon `#00F0FF` | Isolation, longing, cold urban reality |
| **Memory Vision** | Monochrome Grayscale `#1A1A1E` | Muted Indigo `#2C3E6B` | Electric Vermilion UV `#FF2A55` | Hidden truth, psychological awakening |
| **The Under-Code (Reality Shift)**| Glitch Violet `#1F0E3D` | Acid Wireframe Lime `#39FF14`| Corrupted Magenta `#E0067A` | Computational decay, the Architect's presence |
| **Metro / Underground** | Grimy Concrete Gray `#2B2D2F`| Rust Oxide `#8B3A1C` | Flickering Fluorescent Amber `#FFA726` | Claustrophobia, forgotten histories |
| **Dreamland** | Ethereal Pearl White `#E8EAF6`| Twilight Periwinkle `#7986CB`| Radiant Solar Gold `#FFD54F` | False peace, grief, nostalgic illusion |

---

## 2. ADVANCED LIGHTING & ATMOSPHERE PIPELINE

### 2.1 Lighting Architecture for Mobile Vulkan
1. **Clustered Lighting Optimization:**
   - Maximum 12 active OmniLights / SpotLights per cluster bucket on Android.
   - Attenuation curves tuned with aggressive linear roll-off to avoid expensive multi-light overlaps on low-end chipsets.
2. **Volumetric Fog & Light Shafts:**
   - Godot 4 `VolumetricFog` enabled with half-resolution bilateral upsampling for mobile.
   - Fog density: `0.015`, Albedo: `Color(0.12, 0.16, 0.22)`, Anisotropy: `0.45` (forward-scattering creates moody halos around sodium streetlights and car headlamps).
3. **Wet Surface Reflections:**
   - Screen-Space Roughness & Reflections (SSR) enabled for High/PC presets.
   - For Mobile Mid-range: Dual-pass planar reflection probes for large puddles and rain-slicked asphalt roads, saving up to 45% GPU fill-rate.

---

## 3. MASTER SHADER PIPELINE

### 3.1 `wet_road_rain.gdshader` (Dynamic PBR Wetness)
- **Features:** Screen-space ripple normal maps, dynamic roughness inversion (rough concrete becomes mirror-like when wet), animated water stream normals along vertical curbs.
- **Parameters:** `rain_intensity` (0.0 - 1.0), `puddle_scale` (Vector2), `specular_boost` (1.4).

### 3.2 `reality_tear_glitch.gdshader` (Analog Glitch & Reality Shift)
- **Features:** Dual-axis screen tear, RGB split chromatic aberration (shifts red +3px, blue -3px), matrix data-tile displacement, dynamic horizontal scanlines driven by `TIME`.
- **Trigger:** Fires on `EventBus.reality_shift_triggered` with an ease-out sine wave over 0.6 seconds.

### 3.3 `memory_vision.gdshader` (Specter Optics Post-Processing)
- **Features:** Fullscreen post-process that computes luminance `dot(color.rgb, vec3(0.299, 0.587, 0.114))`, tinting the world in desaturated cold charcoal while passing through objects rendered on `VisualLayer 4` (Memory Clues) with glowing emissive fresnel rims.

### 3.4 `time_echo_hologram.gdshader` (Past Silhouette Playback)
- **Features:** Transparent additive fresnel glow, animated horizontal scan-raster bands, vertex noise jitter simulating a degraded 3D digital recording.

---

## 4. ASSET SPECIFICATIONS & POLYGON BUDGETS

| Asset Class | Max Triangle Count | LOD0 / LOD1 / LOD2 | Texture Maps & Sizes | Material Limits |
| :--- | :--- | :--- | :--- | :--- |
| **Alex Morgan (Hero)** | 22,000 Tris | 22k / 11k / 4k | 2048x2048 (Albedo, ORM, Normal, Emissive) | 2 Materials (Body + Hair/Trench) |
| **Supporting Cast (Maya, Archivist)** | 16,000 Tris | 16k / 8k / 3k | 2048x2048 (Albedo, ORM, Normal) | 2 Materials |
| **Hero Street Props (Phone Booth, Car)**| 4,000 Tris | 4k / 1.8k / 600 | 1024x1024 (PBR Packed ORM) | 1 Material |
| **Modular Architecture (Wall, Facade)** | 1,200 Tris | 1.2k / 400 / Billboard | 1024x1024 (Trim Sheet / Tileable) | 1 Shared Atlas Material |
| **Small Clues (Phone, Cassette, Keycard)**| 800 Tris | Single LOD | 512x512 | 1 Material |

---

## 5. CINEMATOGRAPHY & CAMERA DIRECTIVES

### 5.1 Dynamic Camera Behaviors
- **Normal Exploration:** Third-person over-the-shoulder, 52° FOV, spring arm length 2.8m, vertical offset +1.4m, horizontal offset +0.45m (cinematic right-shoulder frame).
- **Narrow Interiors (Alex's Apartment / Alleys):** Spring arm tightens dynamically to 1.8m, FOV broadens to 62° to prevent claustrophobic camera clipping.
- **Memory Vision Active:** Camera FOV pulls back to 68° with slight Dutch roll (+2.5°), simulating an unsettling distortion of physical space.
- **Inspection View:** Camera cuts to a dedicated Macro-3D viewport with interactive mouse/touch orbit around the examined clue.

---

## 6. VISUAL EFFECTS (VFX) CATALOG

1. **`vfx_rain_particles.tscn`:** GPU particle system using screen-space oriented stretch quads. Splashes generate miniature concentric ring particle bursts on ground collision.
2. **`vfx_steam_vent.tscn`:** Soft alpha-blended smoke billboard particles with curl noise turbulence, rising from metro sewer grates.
3. **`vfx_data_mote.tscn`:** Floating luminous digital embers in The Under-Code that react to player proximity via basic compute collision.
4. **`vfx_ghost_trails.tscn`:** Ribbon mesh trail attached to Alex’s hands during ability execution, leaving a brief after-image.
