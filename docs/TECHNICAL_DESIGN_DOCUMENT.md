# Technical Design Document (v1.0)

Related: PROJECT_ARCHITECTURE.md · DATA_SCHEMA.md · CODING_STANDARDS.md · PROJECT_FOLDER_STRUCTURE.md · PLAYER_AND_INTERACTION_GUIDE.md · TESTING_AND_RUN_GUIDE.md · CONTENT_AUTHORING_GUIDE.md

## 1. Stack and targets
| | |
|---|---|
| Engine | Godot 4.3 stable (standard build), GDScript with static typing |
| Renderer | Mobile (Vulkan) by default; Compatibility (OpenGL) is the documented fallback for older Android devices (switch in Project Settings, untested) |
| Platforms | Android first (landscape, `arm64-v8a`); Windows desktop second; same code path (input abstraction) |
| Performance target | 30 fps on mid-range Android (Snapdragon 680 class, 4 GB); 60 fps on high-end. Budgets in ANDROID_PERFORMANCE_GUIDE.md |
| Offline | Entire campaign is offline; online co-op is optional and isolated in `Net` |
| Dependencies | None beyond the engine. No plugins, no paid assets |

## 2. Requirement → module map (Prompt 04)
| Requirement | Module(s) |
|---|---|
| Game state | `GameState` |
| Scene transitions | `SceneManager`, `LocationRoot`, `graybox_location`, `LocationPortal` |
| Player control | `PlayerController`, `InputRouter` |
| Camera | `CameraRig`, `CameraZone` |
| Interactions | `Interactable`, `Interactor`, `Mechanism` |
| Missions | `MissionManager` + `resources/missions` |
| Dialogue | `DialogueManager` + `resources/dialogue`, `dialogue_box` |
| Inventory | `InventoryManager` + `resources/items` |
| Puzzles | `PuzzleManager` + `resources/puzzles`, `puzzle_panel` |
| Memory fragments | `MemoryManager` + `resources/fragments` |
| Abilities | `AbilityManager`, `AbilityBase` subclasses + `resources/abilities` |
| Audio | `Audio` + `resources/audio/audio_registry.json` |
| UI | `scenes/ui/*`, reusable `TouchJoystick`, `TouchLookPad`, `TouchButton` |
| Saving | `SaveManager` (provider pattern, schema v2, migrations) |
| Settings | `Settings` |
| Localization | `Loc` (en, ur) |
| Networking | `Net` (ENet, host-authoritative skeleton) |

## 3. Key technical decisions
| Decision | Why |
|---|---|
| JSON data + `DataRegistry` instead of `.tres` | Diffable, generated from world data, validated headless, no editor needed to author. Typed accessors added where hot. |
| `EventBus` for notifications, `Condition`/`Effects` for data logic | Systems stay independent; content authors compose behaviour without code. |
| Locations are data; graybox generated | Every one of the 47 locations is playable and testable on day one; hand-built scenes replace them one by one (`scene` field). |
| Persistent `GameRoot` with swapped `World` child | Player, HUD and camera survive transitions; no reload hitches; simple saves. |
| `InputRouter` with press latch | Quick taps are never lost between physics ticks on slow phones; stale presses expire in 150 ms. |
| SpringArm camera with eased relax | Instant collision response (no clipping) but no popping when obstacles clear. |
| Animation by name contract (`idle/walk/run/sprint/interact`) | Placeholder clips are generated now; imported character animations drop in unchanged. |
| Saves by provider registration | New systems become saveable without editing `SaveManager`. |
| Dev content gated by `OS.is_debug_build()` | Test arena never ships. |

## 4. Quality strategy
- **Automated (headless Godot):** 862 assertions in 118 tests across 13 suites: data integrity (every cross-reference and localization key), mission walkthrough of the whole campaign, save/migration, scene flow (all 47 locations enter), player/camera/interaction/touch behaviour, an end-to-end objective playthrough, and an "add content with data only" test. Details: TESTING_AND_RUN_GUIDE.md.
- **CI:** `.github/workflows/tests.yml` runs the suite and checks generated files are up to date.
- **Manual device testing:** checklist in TESTING_AND_RUN_GUIDE.md (required before the Android gate is considered closed).

## 5. Status (honest)
| Area | State |
|---|---|
| Architecture, data pipeline, all managers | Implemented and unit/integration tested |
| Player, camera, touch input, interaction | Implemented; tested in simulation; **not yet tested on a physical Android device** |
| Animations | Procedural placeholder clips on a capsule; real character animation not yet integrated |
| Art, audio assets | None yet (graybox only); audio registry ready |
| Networking | Host/join/leave and authority API only; **no replication** yet (NETWORKING_DESIGN.md) |
| Localization | English complete for implemented content; Urdu is a sample set |
| Performance | Not profiled on device; budgets are targets, not measurements |
| Story content in game | Chapter 1-2 dialogue samples; the rest is data-ready (missions, locations, fragments) |

## 6. Known risks
1. Mobile renderer needs Vulkan; old devices need Compatibility renderer (visual differences).
2. JSON must be included in Android exports (`*.json` export filter) or the registry loads nothing (documented, checked at startup: the game logs data errors).
3. Real animation rigs may need an additional `AnimationTree` state for turning-in-place.
4. Headless tests use a dummy renderer: shaders, lighting and GPU performance are not covered.
