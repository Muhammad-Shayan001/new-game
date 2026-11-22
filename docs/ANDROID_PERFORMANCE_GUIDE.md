# AFTERLIFE.EXE — ANDROID PERFORMANCE & OPTIMIZATION MASTER GUIDE
**Document Version:** 2.0.0 (Production Master)  
**Lead Mobile Optimization Engineer:** Antigravity Mobile Performance Lab  
**Target Hardware Baseline:** Mid-Range Android (Snapdragon 778G / Dimensity 900 / 6GB RAM)  
**Target High-End:** Flagship Android (Snapdragon 8 Gen 2/3 / Dimensity 9300 / 8GB-12GB RAM)  

---

## 1. PERFORMANCE BUDGETS & TARGETS

| Metric | Low Preset (Entry Mid-range) | Medium Preset (Target Baseline) | High / Ultra Preset (Flagship) |
| :--- | :--- | :--- | :--- |
| **Target Frame Rate** | 30 FPS Rock Solid | 45–60 FPS Stable | 60–90 FPS Smooth |
| **Target Resolution Scale** | 70% Native ($720\text{p}$) | 85% Native ($900\text{p}$) + FSR 1.0 | 100% Native ($1080\text{p} - 1440\text{p}$) |
| **Draw Calls Per Frame** | $\le 120$ | $\le 220$ | $\le 400$ |
| **Active Triangles / Frame** | $\le 150,000$ | $\le 350,000$ | $\le 800,000$ |
| **Max GPU Memory (VRAM)** | $\le 750\text{ MB}$ | $\le 1.2\text{ GB}$ | $\le 2.0\text{ GB}$ |
| **System RAM Footprint** | $\le 1.8\text{ GB}$ | $\le 2.4\text{ GB}$ | $\le 3.2\text{ GB}$ |
| **Max Sustained Temp** | $< 41^\circ\text{C}$ (No Throttling) | $< 42^\circ\text{C}$ | $< 43.5^\circ\text{C}$ |

---

## 2. GODOT 4 RENDERING ENGINE SETTINGS (MOBILE VULKAN)

### 2.1 Engine Configuration (`project.godot`)
```ini
[rendering]
renderer/rendering_method="mobile"
renderer/rendering_method.mobile="mobile"
textures/vram_compression/import_etc2_astc=true
anti_aliasing/quality/msaa_3d=0 ; Disabled on mobile in favor of FXAA / TAA
anti_aliasing/quality/screen_space_aa=1 ; FXAA enabled
lights_and_shadows/directional_shadow/size=1024
lights_and_shadows/positional_shadow/size=512
occlusion_culling/use_occlusion_culling=true
environment/volumetric_fog/use_filter=false
```

### 2.2 Texture Compression: ASTC (Adaptive Scalable Texture Compression)
All 3D textures must be imported using ASTC:
- **Albedo & Emissive:** `ASTC 6x6` block footprint (high visual fidelity on screen).
- **ORM (Occlusion-Roughness-Metallic) packed maps:** `ASTC 8x8` block footprint.
- **Normal Maps:** `ASTC 5x5` with normalized 2-channel RG reconstruction in shader (`vec3 normal = vec3(N.xy * 2.0 - 1.0, sqrt(1.0 - dot(N.xy, N.xy)));`).

---

## 3. CULLING & SCENE STREAMING ARCHITECTURE

1. **Occlusion Culling Mesh (Baked Portals & Occluders):**
   - Major city buildings and subway tunnels are tagged with `OccluderInstance3D` boxes.
   - Saves up to 60% rendered triangles when navigating narrow alleys or interior rooms.
2. **Camera Distance Clipping:**
   - Small props (trash, soda cans, bottles): cull at $18\text{m}$.
   - Medium props (dumpsters, benches, streetlights): cull at $45\text{m}$.
   - Large buildings: LOD transitions at $30\text{m}$ (LOD1) and $75\text{m}$ (LOD2).
3. **Asynchronous Location Streaming:**
   - When entering the Metro station, the underground scene is loaded in the background via `ResourceLoader.load_threaded_request()` while Alex walks down the descent stairs, eliminating hard loading hitches.

---

## 4. BATTERY SAVING & THERMAL MANAGEMENT

- **Dynamic Framerate Capping:**
  - 60 FPS during live gameplay.
  - Automatically drops to 30 FPS inside the Pause Menu, Case Board, or Smartphone view, reducing GPU power consumption by 35%.
- **Thermal Throttle Graceful Degradation:**
  - If the Android OS reports `THERMAL_STATUS_SEVERE` through JNI hook, the game dynamically lowers shadow resolution from 1024 to 512 and disables screen-space reflections until temperature normalizes.
