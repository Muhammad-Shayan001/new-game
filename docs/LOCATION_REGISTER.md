# Location Register

Generated from `tools/world_data.py`. **Do not edit by hand**; edit the data file and run `python3 tools/world_data.py`.

## ID conventions

| Namespace | Pattern | Example | Used by |
|---|---|---|---|
| Location | `LOC_<REGION>_<NAME>` (`HID` marks hidden) | `LOC_EC_ARCHIVE_TOWER` | missions, dialogue scenes, cinematics, save data |
| Region | 2-letter code | `EC` | location IDs |
| Mission | `CH#_M##` main, `CH#_S##` optional | `CH3_M02` | mission data, save flags |
| Fragment | `CH#_F##` | `CH2_F05` | save data, journal |
| Scene | `CH#_S##_Name` | `CH1_S03_Catalogue` | dialogue script |
| Cinematic | `CINE_##` | `CINE_05` | cinematic script |

Save data stores `current_location` (a `LOC_*` ID) and `visited_locations` (array of `LOC_*` IDs) in `GameState`.

## Regions

| Code | Region | First chapter | Summary |
|---|---|---|---|
| EC | Echo City | 1 | Introductory city built from Alex's and Wren's memories. |
| UM | Underground Metro | 1 | Station and abandoned Line 0; recordings of the Index. |
| DL | Dreamland | 3 | The Other Side: unedited, surreal memory layer. |
| MH | Memory Hospital | 4 | Bridge to the living world; memory reconstruction. |
| BF | Black Forest | 4 | Crash road, lake overlook, supernatural puzzles. |
| SD | Sunken District | 5 | Flooded old city where the Index was born; the Atrium. |
| CR | The Core | 6 | Inner shoreline of the Index where Wren waits. |

## Locations

| ID | Name | Type | Ch | Safe | Hidden | Missions | Fragments | Scenes / Cinematics |
|---|---|---|---|---|---|---|---|---|
| `LOC_UM_ECHO_STATION` | Echo Station | platform | 1 |  |  | CH1_M01 | CH1_F01 | CINE_01 |
| `LOC_UM_CONCOURSE` | Station Concourse | interior | 1 |  |  | CH1_M01, CH1_S01 |  |  |
| `LOC_UM_ABANDONED_PLATFORMS` | Line 0 Abandoned Platforms | platform | 3 |  |  | CH3_M01 |  |  |
| `LOC_UM_RECORDING_ROOM` | Signal Recording Room | interior | 3 | yes |  | CH3_M01 | CH3_F03 |  |
| `LOC_UM_TUNNEL_STATIC` | Static Tunnel | tunnel | 2 |  |  | CH3_M01 |  |  |
| `LOC_UM_HID_MAINTENANCE` | Maintenance Crawlspace | interior | 3 |  | yes | CH3_S03 |  |  |
| `LOC_EC_METRO_ENTRANCE` | Metro Entrance | exterior | 1 |  |  | CH1_M01 |  |  |
| `LOC_EC_MAIN_STREET` | Main Street | street | 1 |  |  | CH1_M02 |  |  |
| `LOC_EC_APT_BLDG` | Morgan Court Apartments | interior | 1 |  |  | CH1_M02 |  |  |
| `LOC_EC_ALEX_APT` | Alex's Apartment (4B) | interior | 1 |  |  | CH1_M02 | CH1_F02 |  |
| `LOC_EC_CONV_STORE` | Quick-Mart 4:17 | interior | 1 |  |  | CH1_S01 | CH1_F03 |  |
| `LOC_EC_PARK` | Lantern Park | exterior | 1 |  |  | CH2_S02 | CH2_F02 |  |
| `LOC_EC_ALLEY` | Narrow Alley | street | 2 |  |  | CH2_M01 | CH2_F03 |  |
| `LOC_EC_ABANDONED_BLDG` | Hartwell Hotel (abandoned) | interior | 2 |  |  | CH2_M03 | CH2_F04 | CINE_03 |
| `LOC_EC_SAFE_ROOM` | Safe Room | interior | 1 | yes |  | CH1_M02 |  |  |
| `LOC_EC_ARCHIVE_TOWER` | Archive Tower | interior | 1 |  |  | CH1_M03 |  | CH1_S03_Catalogue, CINE_02 |
| `LOC_EC_FORGOTTEN_QUARTER` | Forgotten Quarter | street | 2 |  |  | CH2_M01, CH2_S01 |  |  |
| `LOC_EC_MAYA_CAFE` | Maya's Café | interior | 2 |  |  | CH2_M02, CH2_S02 | CH2_F01 | CH2_S02_Cafe |
| `LOC_EC_HID_ROOFTOP` | Rooftop Garden | exterior | 1 |  | yes |  | CH1_F04 |  |
| `LOC_EC_HID_CLOCK_ROOM` | Clockwork Room | interior | 1 |  | yes | CH1_S02 | CH1_F05 |  |
| `LOC_EC_HID_PLAYGROUND` | Sealed Playground | exterior | 2 |  | yes |  | CH2_F05 |  |
| `LOC_DL_CROSSING` | The Crossing | exterior | 3 |  |  | CH3_M01 |  | CH3_S01_Crossing |
| `LOC_DL_ANCHOR_FIELDS` | Anchor Fields | exterior | 3 |  |  | CH3_M02 | CH3_F01 | CH3_S02_Anchors, CINE_04 |
| `LOC_DL_CRIB_ROOM` | The Crib Room | interior | 3 | yes |  | CH3_M03 | CH3_F02 | CH3_S03_Crib |
| `LOC_DL_ECHO_GALLERY` | Time Echo Gallery | interior | 3 |  |  | CH3_S01 | CH3_F04 |  |
| `LOC_DL_THE_HUM` | The Hum | exterior | 3 |  |  | CH3_S02 |  |  |
| `LOC_DL_HID_UPSIDE_STAIRS` | Upside-Down Staircase | interior | 3 |  | yes |  | CH3_F05 |  |
| `LOC_MH_LOBBY` | Hospital Lobby | interior | 4 |  |  | CH4_M01 |  |  |
| `LOC_MH_WARD_ALEX` | Ward 11 (Alex's Room) | interior | 4 | yes |  | CH4_M01, CH4_M03 | CH4_F02 | CH4_S01_Hospital, CH4_S03_Voice, CINE_05 |
| `LOC_MH_WAITING_ROOM` | Waiting Room | interior | 4 |  |  | CH4_S01 | CH4_F03 |  |
| `LOC_MH_RECON_LAB` | Reconstruction Lab | interior | 4 |  |  | CH4_M02, CH4_S02 |  |  |
| `LOC_BF_ROAD_EDGE` | Forest Road Edge | exterior | 4 | yes |  | CH4_M02 |  |  |
| `LOC_BF_CRASH_SITE` | Crash Site | exterior | 4 |  |  | CH4_M02 | CH4_F01 |  |
| `LOC_BF_HOLLOW` | The Hollow | exterior | 4 |  |  | CH4_S03 |  |  |
| `LOC_BF_LAKE_OVERLOOK` | Lake Overlook | exterior | 4 |  |  |  | CH4_F04 |  |
| `LOC_BF_HID_SHRINE` | Hidden Shrine | exterior | 4 |  | yes |  | CH4_F05 |  |
| `LOC_SD_FLOODED_STREETS` | Flooded Streets | street | 5 |  |  | CH5_M01 | CH5_F03 |  |
| `LOC_SD_OLD_CITY_HALL` | Old City Hall | interior | 5 |  |  | CH5_M01, CH5_S01 | CH5_F02 |  |
| `LOC_SD_ATRIUM` | The Atrium | interior | 5 | yes |  | CH5_M01, CH5_M02, CH5_S02 | CH5_F01 | CH5_S02_Argument, CINE_06 |
| `LOC_SD_NODE_CONTROL` | Control Node | interior | 5 |  |  | CH5_M03 |  | CH5_S03_Nodes |
| `LOC_SD_NODE_ARCHIVE` | Archive Node | interior | 5 |  |  | CH5_M03 |  |  |
| `LOC_SD_NODE_MEMORY` | Memory Node | interior | 5 |  |  | CH5_M03 | CH5_F04 |  |
| `LOC_SD_HID_NURSERY` | Sunken Nursery | interior | 5 |  | yes |  | CH5_F05 |  |
| `LOC_SD_DESCENT` | The Descent | tunnel | 6 |  |  |  |  |  |
| `LOC_CR_SHORE` | The Shore | exterior | 6 | yes |  | CH6_M01 | CH6_F02 | CH6_S01_Shore |
| `LOC_CR_LULLABY_PIER` | Lullaby Pier | exterior | 6 |  |  | CH6_M02, CH6_S01 | CH6_F03, CH6_F04 |  |
| `LOC_CR_CHOICE_POINT` | Choice Point | exterior | 6 |  |  | CH6_M03 | CH6_F01, CH6_F05 | CH6_S03_Choice, CINE_07_SAVE, CINE_08_RELEASE, CINE_09_ESCAPE, CINE_10_SECRET |

## Memory fragments (30; Core = story, Hidden = optional, Deep = secret ending)

| ID | Name | Kind | Location |
|---|---|---|---|
| CH1_F01 | A Name on a Ticket | Core | `LOC_UM_ECHO_STATION` |
| CH1_F02 | The Coat Lining | Hidden | `LOC_EC_ALEX_APT` |
| CH1_F03 | Receipt at 4:17 | Hidden | `LOC_EC_CONV_STORE` |
| CH1_F04 | Rooftop Garden | Hidden | `LOC_EC_HID_ROOFTOP` |
| CH1_F05 | The Clockmaker | Hidden | `LOC_EC_HID_CLOCK_ROOM` |
| CH2_F01 | Maya's Laugh | Core | `LOC_EC_MAYA_CAFE` |
| CH2_F02 | The Lake (blurred) | Core | `LOC_EC_PARK` |
| CH2_F03 | Chalk Waves | Hidden | `LOC_EC_ALLEY` |
| CH2_F04 | The Empty Chair | Hidden | `LOC_EC_ABANDONED_BLDG` |
| CH2_F05 | Lullaby, Line 1 | Deep | `LOC_EC_HID_PLAYGROUND` |
| CH3_F01 | Eight Years Old | Core | `LOC_DL_ANCHOR_FIELDS` |
| CH3_F02 | Sister | Core | `LOC_DL_CRIB_ROOM` |
| CH3_F03 | Tape Zero: A Father's Voice | Hidden | `LOC_UM_RECORDING_ROOM` |
| CH3_F04 | Echo of a Birthday | Hidden | `LOC_DL_ECHO_GALLERY` |
| CH3_F05 | The Staircase Down | Hidden | `LOC_DL_HID_UPSIDE_STAIRS` |
| CH4_F01 | The Drive | Core | `LOC_BF_CRASH_SITE` |
| CH4_F02 | Wren's Name | Core | `LOC_MH_WARD_ALEX` |
| CH4_F03 | Maya's Vigil | Hidden | `LOC_MH_WAITING_ROOM` |
| CH4_F04 | Lake Shadows | Hidden | `LOC_BF_LAKE_OVERLOOK` |
| CH4_F05 | Lullaby, Line 2 | Deep | `LOC_BF_HID_SHRINE` |
| CH5_F01 | The Lake (clear) | Core | `LOC_SD_ATRIUM` |
| CH5_F02 | Elias's Promise | Core | `LOC_SD_OLD_CITY_HALL` |
| CH5_F03 | The Flooded Classroom | Hidden | `LOC_SD_FLOODED_STREETS` |
| CH5_F04 | Wren's Drawing | Hidden | `LOC_SD_NODE_MEMORY` |
| CH5_F05 | Lullaby, Line 3 | Deep | `LOC_SD_HID_NURSERY` |
| CH6_F01 | The Day at the Lake | Core | `LOC_CR_CHOICE_POINT` |
| CH6_F02 | Footprints | Hidden | `LOC_CR_SHORE` |
| CH6_F03 | The Lullaby | Hidden | `LOC_CR_LULLABY_PIER` |
| CH6_F04 | Wren's Laugh | Hidden | `LOC_CR_LULLABY_PIER` |
| CH6_F05 | Goodbye Letter | Hidden | `LOC_CR_CHOICE_POINT` |

## Scene and cinematic references

| Reference | Location |
|---|---|
| CH1_S03_Catalogue | `LOC_EC_ARCHIVE_TOWER` |
| CH2_S02_Cafe | `LOC_EC_MAYA_CAFE` |
| CH3_S01_Crossing | `LOC_DL_CROSSING` |
| CH3_S02_Anchors | `LOC_DL_ANCHOR_FIELDS` |
| CH3_S03_Crib | `LOC_DL_CRIB_ROOM` |
| CH4_S01_Hospital | `LOC_MH_WARD_ALEX` |
| CH4_S03_Voice | `LOC_MH_WARD_ALEX` |
| CH5_S02_Argument | `LOC_SD_ATRIUM` |
| CH5_S03_Nodes | `LOC_SD_NODE_CONTROL` |
| CH6_S01_Shore | `LOC_CR_SHORE` |
| CH6_S03_Choice | `LOC_CR_CHOICE_POINT` |
| CINE_01 | `LOC_UM_ECHO_STATION` |
| CINE_02 | `LOC_EC_ARCHIVE_TOWER` |
| CINE_03 | `LOC_EC_ABANDONED_BLDG` |
| CINE_04 | `LOC_DL_ANCHOR_FIELDS` |
| CINE_05 | `LOC_MH_WARD_ALEX` |
| CINE_06 | `LOC_SD_ATRIUM` |
| CINE_07_SAVE | `LOC_CR_CHOICE_POINT` |
| CINE_08_RELEASE | `LOC_CR_CHOICE_POINT` |
| CINE_09_ESCAPE | `LOC_CR_CHOICE_POINT` |
| CINE_10_SECRET | `LOC_CR_CHOICE_POINT` |
