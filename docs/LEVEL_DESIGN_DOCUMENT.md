# Level Design Document (v1.0 DRAFT)

Companion files: WORLD_MAP.md (master map), LOCATION_REGISTER.md (all IDs), LEVEL_FLOW_DIAGRAMS.md (per-chapter routes), ENVIRONMENT_ASSET_LIST.md, WORLD_BIBLE.md.
All location IDs (`LOC_*`) are identical in missions, dialogue scene references, cinematics and save data.

## 1. Level-flow principles (guiding without UI markers)
1. **Light leads.** Warmest, brightest practical light marks the next objective; dead ends are cool and dim.
2. **Landmarks.** Each region has one skyline landmark visible from its start (Archive Tower, Line 0 train, the floating Crib, the hospital sign, the lake glimmer, the sunken dome, the pier).
3. **Sound.** Objective areas carry a distinct audio signature (Archivist's index-card shuffle, Maya's café radio, the lullaby hum). Volume and panning rise as the player approaches. Hints are 3D positional audio.
4. **Composition.** Roads, rails, lamp posts, power lines and floor patterns converge toward the objective; side routes are narrower and lower.
5. **Story objects.** Important objects have unique silhouettes and a faint Memory Sight shimmer; chalk waves always point toward the next story beat.
6. **Path design.** Wide-narrow-wide rhythm: a calm exploration space, a tension corridor, a reveal space. No more than 2 decision forks before a landmark confirms direction.
7. **Minimal UI.** No waypoint markers on the main path. Optional **Memory Pulse** (hold) shows a soft directional ripple to the nearest unexplored point of interest; it is available to all players and can be turned off in Settings.
8. **No dead softlocks.** Every area has a return route; out-of-bounds respawns at the last safe point.
9. **Point-of-no-return warning.** Before the Ch5 collapse (CH5_M03 completion) the Archivist warns "this place will not remain"; players may leave to collect missing items. Collectibles can also be recovered through Chapter Replay.

## 2. Standard area template (all regions)
Every region below specifies: Layout, Entry/Exit, Main routes, Optional routes, Landmarks, Important objects, NPC locations, Puzzle locations, Mission connections, Lighting, Weather, Environmental storytelling, Audio, Navigation requirements, Performance.

Common performance baseline (Android mid-range target: Snapdragon 680-class, 4 GB RAM, 30 fps; high-tier 60 fps): ≤ 150 draw calls, ≤ 300k visible triangles, textures ≤ 350 MB, ≤ 3 real-time shadow casters (1 directional + 2 spot), baked lightmaps/probes, occlusion culling zones per sub-area, scene streaming at region transitions. Region-specific limits are noted per region. "Low" preset halves shadow distance, disables fog volumetrics, and swaps to simpler materials.

---
## 3. ECHO CITY (region `EC`, Ch1–2)
- **Layout:** a linear "main street" spine running north-south (~420 m) with the **Metro Entrance** at the south end and the **Archive Tower** at the north. Branches: west = Morgan Court Apartments (with basement Safe Room and rooftop), east = Quick-Mart, then Lantern Park; from Ch2 a side **Narrow Alley** opens off the plaza into the **Forgotten Quarter** (Maya's Café, Hartwell Hotel). Hidden locations: Rooftop Garden, Clockwork Room, Sealed Playground. Scale: ~300 × 500 m playable.
- **Entry/Exit:** in from `LOC_UM_CONCOURSE` via escalator (Ch1); out through the Hartwell Hotel basement to `LOC_UM_TUNNEL_STATIC` (Ch2 end).
- **Main routes:** METRO_ENTRANCE → MAIN_STREET → APT_BLDG → (SAFE_ROOM) → ALEX_APT → MAIN_STREET → ARCHIVE_TOWER (Ch1). MAIN_STREET → ALLEY → FORGOTTEN_QUARTER → MAYA_CAFE → ABANDONED_BLDG (Ch2).
- **Optional routes:** CONV_STORE; PARK (and shortcut gate to Forgotten Quarter in Ch2); hidden ROOFTOP (ladder revealed by Memory Sight), CLOCK_ROOM (panel behind the tower clock), PLAYGROUND (hidden gate behind park, Deep Fragment `CH2_F05`).
- **Landmarks:** Archive Tower (visible from Metro exit; light beam), the plaza lamp posts that all flicker in sync, Lantern Park's dry fountain, Hartwell Hotel's broken sign, chalk waves on brick.
- **Important objects:** ticket stub "W.M." (`LOC_EC_ALEX_APT`), child's drawings behind the wardrobe, 4:17 receipts (`LOC_EC_CONV_STORE`), blank index card (`LOC_EC_ARCHIVE_TOWER`), the empty chair (`LOC_EC_ABANDONED_BLDG`), the wedding photo pieces (park + café).
- **NPC locations:** ARV at the Catalogue Desk (`LOC_EC_ARCHIVE_TOWER`) and voice on Metro speakers (Ch1); `NPC_CLERK_ECHO` at the store counter (repeats one line); `NPC_WHISPERER` in the Forgotten Quarter; MAY in `LOC_EC_MAYA_CAFE` (Ch2); Forgotten crowds in the Quarter.
- **Puzzle locations:** `PZL_EC_01` wardrobe drawing order (`LOC_EC_ALEX_APT`, Pattern); `PZL_EC_02` card catalogue symbols (`LOC_EC_ARCHIVE_TOWER`, Symbol); `PZL_EC_03` set clock to 4:17 (`LOC_EC_HID_CLOCK_ROOM`, optional); `PZL_EC_04` seat the Forgotten Crowd (`LOC_EC_FORGOTTEN_QUARTER`, Memory Reconstruction); `PZL_EC_05` wedding photo (`LOC_EC_PARK`/`LOC_EC_MAYA_CAFE`, optional); `PZL_EC_06` the empty chair (`LOC_EC_ABANDONED_BLDG`).
- **Mission connections:** CH1_M01 (end), CH1_M02, CH1_M03, CH1_S01, CH1_S02, CH2_M01, CH2_M02, CH2_M03, CH2_S01, CH2_S02.
- **Lighting:** perpetual dusk (blue-violet ambient, warm sodium lamps), practical lights as guidance; the Forgotten Quarter is lit mostly by café windows; the Safe Room is soft amber.
- **Weather:** still, fine drizzle that never wets surfaces (visual particle, cheap). Ch2: slow drifting fog in the Quarter.
- **Environmental storytelling:** every clock reads 4:17; tables have one chair too few; chalk waves; children's drawings of water; mailboxes labeled "MORGAN" with one name scratched out.
- **Audio atmosphere:** distant lullaby hum, low sub-bass, wind through awnings, café radio static, Archive Tower index-card shuffle.
- **Navigation requirements:** none for main path; Memory Sight to reveal hidden ladder, gate and clock panel; no abilities gate the Ch2 main path.
- **Performance:** ≤ 250k visible tris on Main Street; interiors are separate occlusion cells; lamp posts instanced; ≤ 20 simultaneous Forgotten NPCs (billboard LOD beyond 25 m).

### Echo City sub-areas
| ID | Purpose | Design notes |
|---|---|---|
| `LOC_EC_METRO_ENTRANCE` | Ch1 street arrival | Canopy frames Archive Tower; first Light-lead moment. |
| `LOC_EC_MAIN_STREET` | Hub | Plaza with 3 exits; storefront signs repeat "4:17". |
| `LOC_EC_APT_BLDG` | Gateway interior | Lobby, mailboxes, stairwell (4 floors) with basement door to Safe Room. |
| `LOC_EC_ALEX_APT` | Personal clues | One room + bedroom; wardrobe puzzle; Fragment `CH1_F02`. |
| `LOC_EC_CONV_STORE` | Optional | Small interior; receipts clue; `CH1_F03`. |
| `LOC_EC_PARK` | Optional exploration | Open space; benches face a lake that isn't there; `CH2_F02`. |
| `LOC_EC_ALLEY` | Transition, tension corridor | Narrow, chalk waves guide; first Forgotten glimpse. |
| `LOC_EC_ABANDONED_BLDG` | Ch2 set-piece | Multi-floor ruin; empty chair; basement stair to static. |
| `LOC_EC_SAFE_ROOM` | Save + tutorial | Cellar; journal desk; fast-travel node. |

---
## 4. UNDERGROUND METRO (region `UM`, Ch1 and Ch3)
- **Layout:** Echo Station (Ch1 start) and Concourse; deeper, **Line 0** abandoned platforms with tilted trains, a Signal Recording Room, a hidden maintenance crawlspace, and the Static Tunnel. ~250 m long linear structure.
- **Entry/Exit:** game start at `LOC_UM_ECHO_STATION`; Concourse → street (Ch1). Static Tunnel from the Hartwell basement (Ch2 end); exit via a static wall in the Recording Room to Dreamland (Ch3).
- **Main routes:** ECHO_STATION → CONCOURSE → street (Ch1); TUNNEL_STATIC → ABANDONED_PLATFORMS → RECORDING_ROOM → DL_CROSSING (Ch3).
- **Optional routes:** vent grate to MAINTENANCE crawlspace; Concourse-to-Line 0 shortcut gate opened from the Line 0 side.
- **Landmarks:** the 4:17 station clock; a train with its doors open and lights on at the far end of Line 0; tape reel wall.
- **Important objects:** blank ticket (`CH1_F01`), lost-luggage tags, reel tapes ("Tape Zero" has Elias's voice, `CH3_F03`), the worker's logbook (`CH3_S03`).
- **NPC locations:** ARV voice on station speakers (Ch1); none in Line 0 except recordings.
- **Puzzle locations:** `PZL_UM_01` reel-tape sequencing (`LOC_UM_RECORDING_ROOM`, Sound Echo).
- **Mission connections:** CH1_M01, CH1_S01, CH3_M01, CH3_S03.
- **Lighting:** flickering fluorescent tubes in rhythm with the lullaby hum; Line 0 lit by train headlights and emergency red.
- **Weather:** none; dust motes, occasional water drip; wind pulses when a train "passes".
- **Environmental storytelling:** peeling posters of missing people, a pram parked on a platform, a lost-and-found shelf with a child's yellow raincoat button.
- **Audio atmosphere:** announcements that repeat fragments of Alex's name, distant train, reverb tunnel hum, tape hiss.
- **Navigation requirements:** none in Ch1; Memory Sight to read hidden platform writing; Reality Shift not needed here.
- **Performance:** tunnels instanced from 4 modular kits; ≤ 180k visible tris; no real-time reflections (baked reflection probes).

---
## 5. DREAMLAND (region `DL`, Ch3) — "The Other Side"
- **Layout:** non-Euclidean: Crossing (sky stairs), Anchor Fields (3 floating islands), Crib Room (central nursery), Time Echo Gallery, The Hum (optional soundscape), Upside-Down Staircase (hidden).
- **Entry/Exit:** in from `LOC_UM_RECORDING_ROOM` (static wall); out via the Crib Room's monitor-tone door to `LOC_MH_LOBBY` (Ch4).
- **Main routes:** CROSSING → ANCHOR_FIELDS (activate 3 anchors with Reality Shift) → CRIB_ROOM.
- **Optional routes:** ECHO_GALLERY (Time Echo puzzles), THE_HUM, HID_UPSIDE_STAIRS (via Reality Shift in the Gallery).
- **Landmarks:** a giant floating crib mobile visible from the Crossing; the three anchor pylons with colored light (distinct shapes + audio tones).
- **Important objects:** crib mobile (Ch3 foreshadow), painted-over name on the wall, nursery wallpaper matching Alex's coat lining, the crash headlight flash during first Reality Shift.
- **NPC locations:** ARV guides at the Crossing; FCH glimpse in the Crib Room; Maya voice only.
- **Puzzle locations:** `PZL_DL_01–03` Shift Anchors (`LOC_DL_ANCHOR_FIELDS`, Reality Shift Swap); `PZL_DL_04` Time Echo gallery (`LOC_DL_ECHO_GALLERY`); `PZL_DL_05` Hum frequency matching (`LOC_DL_THE_HUM`).
- **Mission connections:** CH3_M01 (end), CH3_M02, CH3_M03, CH3_S01, CH3_S02.
- **Lighting:** shifting hue sky (teal to amber), no cast shadows from some objects (stylized), rim light on the player.
- **Weather:** floating paper-like ash that falls upward.
- **Environmental storytelling:** drawings of waves float like fish; doors with no walls; an upside-down hallway of family photos with faces missing.
- **Audio atmosphere:** reversed lullaby, glass harmonics, heartbeat that becomes a monitor beep at the Crib Room.
- **Navigation requirements:** Reality Shift (obtained at the first Anchor) to cross gaps; Time Echo for gallery doors.
- **Performance:** ≤ 200k tris; avoid real physics; spatial distortion done with shader tricks only on high preset (fallback: simple fade). Reality Shift swaps via pre-baked variants, never runtime generation.

---
## 6. MEMORY HOSPITAL (region `MH`, Ch4)
- **Layout:** compact 4-floor hospital: Lobby, Ward 11 (Alex), Waiting Room, Reconstruction Lab. Elevator connects floors. Living-world details overlay the echo (pulse monitors, voices).
- **Entry/Exit:** in from `LOC_DL_CRIB_ROOM`; out to `LOC_BF_ROAD_EDGE` (via Lab projection, Ch4) and finally to `LOC_SD_FLOODED_STREETS` (Ch4 end).
- **Main routes:** LOBBY → WARD_ALEX (CH4_M01); LOBBY → RECON_LAB → BF (CH4_M02); return to WARD_ALEX (CH4_M03).
- **Optional routes:** WAITING_ROOM (Maya's journal); Lab archive shelves (voicemail archive).
- **Landmarks:** a green EXIT sign that flickers 4:17; the Ward 11 window with a tree outside; Lab's large memory projector.
- **Important objects:** coma chart ("11 days"), Maya's journal, father's tuning fork on the nightstand, lake photograph.
- **NPC locations:** MAY at Alex's bedside (`LOC_MH_WARD_ALEX`); Nurse and doctor echoes in the Lobby (no dialogue, ambient).
- **Puzzle locations:** `PZL_MH_01` memory reconstruction of "The Drive" (`LOC_MH_RECON_LAB`); `PZL_MH_02` journal cipher (`LOC_MH_WAITING_ROOM`, optional).
- **Mission connections:** CH4_M01, CH4_M02 (start), CH4_M03, CH4_S01, CH4_S02.
- **Lighting:** cold clinical white with flickers; Ward 11 warm bedside lamp; Lab blue-cyan.
- **Weather:** rain visible on windows only (billboard textures).
- **Environmental storytelling:** wristband tags with Alex's name, a half-finished cup of Maya's tea, voicemail slips taped to the wall.
- **Audio atmosphere:** heart monitor in sync with the lullaby, distant PA "Ward 11, visitors please..." fragments, rain on glass.
- **Navigation requirements:** none; Echo Voice not yet available.
- **Performance:** interior cells with portals; ≤ 150k tris; no dynamic shadows except bedside lamp.

---
## 7. BLACK FOREST (region `BF`, Ch4)
- **Layout:** wet forest road with a bus shelter (safe point), crash site 80 m down the road, optional trail to The Hollow and the Lake Overlook; hidden mossy shrine beyond the overlook. ~250 × 250 m.
- **Entry/Exit:** in from Reconstruction Lab projection (`LOC_BF_ROAD_EDGE`); out back to `LOC_MH_RECON_LAB`.
- **Main routes:** ROAD_EDGE → CRASH_SITE (headlight light-and-mirror puzzle).
- **Optional routes:** deer trail to HOLLOW (sound totems) → LAKE_OVERLOOK → HID_SHRINE (hidden stair).
- **Landmarks:** crash site headlights cutting through fog; the lake glimmer on the overlook horizon; a tall dead tree with a swing.
- **Important objects:** wrecked car (driver door open), phone with unsent message "Dad, we need to talk", a small shoe, the shrine's toy boat.
- **NPC locations:** none (Forgotten silhouettes between trees; non-hostile).
- **Puzzle locations:** `PZL_BF_01` headlight mirrors (`LOC_BF_CRASH_SITE`, Light & Mirror); `PZL_BF_02` totem sound sequence (`LOC_BF_HOLLOW`, optional).
- **Mission connections:** CH4_M02, CH4_S03.
- **Lighting:** moonlight through fog with strong volumetric shafts (only on High preset; Low uses fog billboards).
- **Weather:** frozen rain (suspended droplets) around the crash; falling leaves elsewhere.
- **Environmental storytelling:** tire marks that bend impossibly, a child's chalk waves on road signs, swing moving without wind.
- **Audio atmosphere:** crickets that stop when the player stops, distant water, low cello drone, slow breathing.
- **Navigation requirements:** none for main; Memory Sight to follow glowing footprints to the shrine; Time Echo not required.
- **Performance:** foliage via instanced billboards past 30 m; ≤ 220k tris; no real-time grass physics.

---
## 8. SUNKEN DISTRICT (region `SD`, Ch5; Core region `CR`, Ch6)
- **Layout:** flooded old downtown: Flooded Streets (knee-deep water), Old City Hall, the Atrium (ring of three node corridors), hidden Sunken Nursery, then the Descent shaft to the Core.
- **Entry/Exit:** in from `LOC_MH_WARD_ALEX` (Index door); out via `LOC_SD_DESCENT` to `LOC_CR_SHORE` (Ch6).
- **Main routes:** FLOODED_STREETS → OLD_CITY_HALL → ATRIUM → (NODE_CONTROL, NODE_ARCHIVE, NODE_MEMORY in any order) → DESCENT.
- **Optional routes:** hidden submerged door to SUNKEN_NURSERY (Reality Shift + Echo Voice); Elias's recordings room in Old City Hall; the Unsent Letter in the Atrium.
- **Landmarks:** half-sunk clock tower, the Atrium's dome with suspended glowing memories, three colored node beacons.
- **Important objects:** Index schematics, Elias's lab logs, Archivist "Instruction 0" card, Wren's drawing.
- **NPC locations:** ARC in the Atrium (`LOC_SD_ATRIUM`); ARV with the Archive Node; MAY via echo voice; Forgotten line the Flooded Streets.
- **Puzzle locations:** `PZL_SD_01` valve water-level puzzle (`LOC_SD_FLOODED_STREETS`); `PZL_SD_02–04` node puzzles (Control: Time Echo; Archive: Reality Shift; Memory: Echo Voice).
- **Mission connections:** CH5_M01, CH5_M02, CH5_M03, CH5_S01, CH5_S02; end links to CH6_M01.
- **Lighting:** teal water caustics, warm amber inside the Atrium, node colors (red, blue, gold) as navigational beacons.
- **Weather:** none; mist over water; dripping from broken ceilings.
- **Environmental storytelling:** swimming-pool lane ropes in streets, school chairs under water, mailboxes labeled with Wren's initial.
- **Audio atmosphere:** water laps, underwater muffling in submerged zones, choir-like humming in the Atrium, the Architect's tuning fork note.
- **Navigation requirements:** Reality Shift and Time Echo for nodes; Echo Voice (unlocked CH5) for the Memory Node and hidden nursery.
- **Performance:** water as a flat shader plane with baked caustics; ≤ 200k tris; Atrium memories are particle emitters (≤ 300 particles).

### The Core (region `CR`, Ch6)
- **Layout:** a single shoreline and pier made of static: Shore → Lullaby Pier → Choice Point.
- **Entry/Exit:** in from the Descent; endings exit to credits (no outgoing route).
- **Main routes:** SHORE → LULLABY_PIER → CHOICE_POINT.
- **Optional routes:** none; Deep-Fragment lullaby (`CH6_S01`) is completed on the pier.
- **Landmarks:** a yellow raincoat on a pier post; a lighthouse made of memory light.
- **Important objects:** Wren's footprints, the three lullaby lines (Deep Fragments), the empty chair at the pier's end.
- **NPC locations:** FCH at the Shore and Pier; ARC at the Choice Point; ARV and MAY arrive as voices at the end.
- **Puzzle locations:** `PZL_CR_01` lullaby with Time Echo (`LOC_CR_LULLABY_PIER`); `PZL_CR_02` final Echo Voice choice (`LOC_CR_CHOICE_POINT`).
- **Mission connections:** CH6_M01, CH6_M02, CH6_M03, CH6_S01.
- **Lighting:** dawn-grey sky transitioning toward gold depending on choices.
- **Weather:** soft static snow; calm water.
- **Environmental storytelling:** wet footprints that dry; objects from every earlier chapter washed ashore.
- **Audio atmosphere:** the full lullaby, built up from the Deep Fragments; water.
- **Navigation requirements:** all four abilities.
- **Performance:** very low geometry (≤ 80k tris); ending cinematics use the same scene.

---
## 9. Mission validity gate
`python3 tools/world_data.py` checks that: every location referenced by a mission, fragment, scene or cinematic exists; every main mission has a route from the previous main mission's end using only routes opened by that chapter; every location is reachable by Chapter 6; every location is used by a route or fragment; 30 fragments (5 per chapter, 3 Deep).
Result at last run: **OK: 47 locations, 48 routes, 31 missions (18 main), 30 fragments, 21 scene refs.**
