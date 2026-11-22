# AFTERLIFE.EXE — MASTER ASSET REGISTER & CATALOG
**Document Version:** 2.0.0 (Production Master)  
**Lead Asset Manager:** Antigravity Production Studio  

---

## 1. 3D CHARACTERS & RIGS

| Asset ID | Character / Entity | Polycount (LOD0) | Texture Maps | Rig Type | File Location |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `chr_alex_morgan` | Alex Morgan (Hero) | 22,000 Tris | 2048x2048 PBR (Albedo/ORM/Norm/Emiss) | Humanoid + 6 Spring Bones | `res://assets/models/characters/alex_morgan.glb` |
| `chr_maya_reed` | Maya Reed | 16,500 Tris | 2048x2048 PBR | Humanoid + Antenna Jiggle | `res://assets/models/characters/maya_reed.glb` |
| `chr_archivist` | The Archivist | 18,000 Tris | 2048x2048 PBR + Wireframe Alpha | Humanoid + Left Face Mesh | `res://assets/models/characters/archivist.glb` |
| `chr_architect` | The Architect | 25,000 Tris | 2048x2048 Shifting Hologram | Multi-jointed Core Rig | `res://assets/models/characters/architect.glb` |
| `chr_forgotten_child`| The Forgotten Child| 8,000 Tris | 1024x1024 Alpha Fresnel | Stylized Child Rig | `res://assets/models/characters/forgotten_child.glb` |
| `ent_watcher` | The Watcher | 9,500 Tris | 1024x1024 Shadow Emissive | Slender Stalker Rig | `res://assets/models/entities/watcher.glb` |
| `ent_mimic` | The Mimic | 7,200 Tris | 1024x1024 Prop $\rightarrow$ Spider | Morph Rig | `res://assets/models/entities/mimic.glb` |

---

## 2. MODULAR ENVIRONMENT KITS & HERO PROPS

| Asset ID | Category / Name | Triangles | Material / Texture Type | File Location |
| :--- | :--- | :--- | :--- | :--- |
| `env_city_wall_trim` | Modular Brick & Concrete Facades | 1,200 Tris | 1024x1024 Trim Sheet (Wet PBR) | `res://assets/models/environment/city_walls.glb` |
| `env_phone_booth` | Vintage Glass Phone Booth (Hero Prop) | 3,800 Tris | 1024x1024 Glass Condensation | `res://assets/models/props/phone_booth.glb` |
| `env_metro_turnstile`| Subway Turnstile & Card Reader | 2,400 Tris | 1024x1024 Brushed Steel | `res://assets/models/props/metro_turnstile.glb` |
| `env_street_lamp_01` | Sodium Vapor Curved Lamp Post | 950 Tris | 512x512 PBR + Emissive Bulb | `res://assets/models/props/street_lamp.glb` |
| `env_broken_car_01` | Corrupted Sedan Prop | 4,200 Tris | 1024x1024 Wet Painted Metal | `res://assets/models/props/broken_car.glb` |

---

## 3. MASTER SHADERS

| Shader ID | Target Surface / Role | Technique & Optimization | File Location |
| :--- | :--- | :--- | :--- |
| `sh_wet_road` | Roads, Sidewalks, Puddles | PBR Dynamic Roughness Inversion, Normal Ripples | `res://assets/shaders/wet_road_rain.gdshader` |
| `sh_reality_tear` | Reality Shift & Screen Glitch | Chromatic Aberration, Scanlines, Block Displacement | `res://assets/shaders/reality_tear_glitch.gdshader` |
| `sh_memory_vision`| Memory Vision Post-Process | Fullscreen Desaturation + Selective UV Emission | `res://assets/shaders/memory_vision.gdshader` |
| `sh_time_echo` | Past Silhouette Playback | Hologram Fresnel Glow, Moving Scan-Bands | `res://assets/shaders/time_echo_hologram.gdshader` |

---

## 4. MASTER AUDIO REGISTER

| Track / Sound ID | Category | Bus Route | Length / Format | Description |
| :--- | :--- | :--- | :--- | :--- |
| `mus_theme_terminal`| Music | `Music` | 3:45 / OGG Vorbis | Main Theme: Melancholic analog synth & cello |
| `mus_ambient_rain` | Ambience | `Ambience` | Seamless Loop / OGG | Spatial 3D Rain falling on metal & concrete |
| `sfx_foley_footstep_wet`| SFX / Foley | `SFX` | 0.4s / WAV | Rubber soles on wet asphalt (5 velocity layers) |
| `sfx_ability_shift` | SFX / Supernatural| `SFX` | 1.2s / WAV | Sub-bass drop followed by digital spatial tear |
| `sfx_phone_buzz` | SFX / UI | `SFX` | 0.8s / WAV | Authentic smartphone vibration rattle |
