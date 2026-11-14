# Environment Asset List
Budgets target Android mid-range. Source: Blender (own work) or CC0/properly licensed packs; track every external asset in ASSET_REGISTER.md. Tri budgets are per asset (LOD0). Texture sizes max 1024 mobile (2048 for hero props).
Status key: P0 = needed for vertical slice (Ch1), P1 = full game, P2 = polish.

## Shared kits
| Asset | Tris | Tex | Variants | Notes | Pri |
|---|---|---|---|---|---|
| Modular street kit (sidewalk, curb, road) | 400–1.2k | 1024 atlas | 6 | trim sheet | P0 |
| Building facade kit (windows/doors/awnings) | 500–2k | 1024 atlas | 12 | instanced | P0 |
| Lamp posts (synced flicker) | 800 | shared | 3 | emissive | P0 |
| Props: bench, bin, mailbox, bicycle, car shell | 300–2.5k | atlas | 20 | | P0 |
| Interior kit (walls, doors, stairs) | 300–1.5k | 1024 atlas | 10 | | P0 |
| Chalk wave decals | quad | 512 | 8 | game-wide motif | P0 |
| Clock (4:17) | 1.5k | 512 | 2 | repeated | P0 |
| Index card/drawer set | 1k | 512 | 4 | Archive | P0 |

## By region
| Region | Asset groups (examples) | Hero assets | Approx. unique assets |
|---|---|---|---|
| EC (`LOC_EC_*`) | street kit, facades, Morgan Court lobby, Alex's apartment set, store interior, park (fountain, trees), alley, Hartwell Hotel ruin, Safe Room | Archive Tower (6k tris), Alex's wardrobe, the empty chair | 90 |
| UM (`LOC_UM_*`) | tunnel kit, turnstiles, ticket machines, tilted train, reel tape wall, vents | Line 0 train (5k), tape wall (3k) | 45 |
| DL (`LOC_DL_*`) | floating islands, sky stairs, anchor pylons, crib + mobile, wireframe materials | giant crib mobile, anchors | 40 |
| MH (`LOC_MH_*`) | hospital corridor kit, beds, monitors, lab machines, elevators | Ward 11 bed + monitor, memory projector | 50 |
| BF (`LOC_BF_*`) | tree kit (3 species), rocks, wrecked car, bus shelter, shrine, totems | crashed car (4k), the swing tree | 45 |
| SD (`LOC_SD_*`) | flooded street kit, sunken cars, Old City Hall, Atrium dome, node machines, nursery | Atrium dome, node cores | 60 |
| CR (`LOC_CR_*`) | pier, shore, static particles, raincoat prop | Lullaby Pier, lighthouse of memory | 15 |

## Characters (for reference, separate list)
Alex (15k tris, 2048), Maya (15k), Archivist (12k, paper/glass shader), Architect (12k), Wren (10k), Forgotten (3 body variants, 4k), crowd billboards.

## FX and materials
Memory Sight shimmer · Reality Shift dissolve (shader + pre-baked variants) · Time Echo ghost (silhouette shader) · water (flat plane + baked caustics) · fog cards · dust motes · frozen rain.

## Audio asset hooks
Per location: ambience loop, reverb zone, objective audio cue (see AUDIO_DIRECTION_GUIDE.md).

## Vertical slice (Chapter 1) asset count
≈ 140 unique assets: Echo Station, Concourse, Metro Entrance, Main Street, Morgan Court, Safe Room, Alex's apartment, Archive Tower interior, hidden Clockwork Room.
