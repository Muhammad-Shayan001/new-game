"""Single source of truth for AFTERLIFE.EXE world data.
Run `python3 tools/world_data.py` to validate and regenerate:
LOCATION_REGISTER.md, WORLD_MAP.md, LEVEL_FLOW_DIAGRAMS.md, scripts/systems/location_ids.gd
"""
import sys, os, collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

REGIONS = {
 "EC": ("Echo City", 1, "Introductory city built from Alex's and Wren's memories."),
 "UM": ("Underground Metro", 1, "Station and abandoned Line 0; recordings of the Index."),
 "DL": ("Dreamland", 3, "The Other Side: unedited, surreal memory layer."),
 "MH": ("Memory Hospital", 4, "Bridge to the living world; memory reconstruction."),
 "BF": ("Black Forest", 4, "Crash road, lake overlook, supernatural puzzles."),
 "SD": ("Sunken District", 5, "Flooded old city where the Index was born; the Atrium."),
 "CR": ("The Core", 6, "Inner shoreline of the Index where Wren waits."),
}

# id, name, region, type, first_chapter, safe_point, hidden, description
L = [
 ("LOC_UM_ECHO_STATION","Echo Station","UM","platform",1,False,False,"Opening platform; bench where Alex wakes; clock stuck at 4:17."),
 ("LOC_UM_CONCOURSE","Station Concourse","UM","interior",1,False,False,"Turnstiles, dead ticket machines, escalator up to the street."),
 ("LOC_UM_ABANDONED_PLATFORMS","Line 0 Abandoned Platforms","UM","platform",3,False,False,"Collapsed signage, tilted trains, voices on old speakers."),
 ("LOC_UM_RECORDING_ROOM","Signal Recording Room","UM","interior",3,True,False,"Wall of reel tapes of erased memories; safe point."),
 ("LOC_UM_TUNNEL_STATIC","Static Tunnel","UM","tunnel",2,False,False,"Tunnel ending in a wall of static; threshold to the Other Side."),
 ("LOC_UM_HID_MAINTENANCE","Maintenance Crawlspace","UM","interior",3,False,True,"Hidden crawlspace with a worker's logbook."),
 ("LOC_EC_METRO_ENTRANCE","Metro Entrance","EC","exterior",1,False,False,"Stair canopy opening onto the main street."),
 ("LOC_EC_MAIN_STREET","Main Street","EC","street",1,False,False,"Central spine; empty plaza, fixed lamp posts, the Archive Tower visible."),
 ("LOC_EC_APT_BLDG","Morgan Court Apartments","EC","interior",1,False,False,"Apartment block with lobby, mailboxes and basement stair."),
 ("LOC_EC_ALEX_APT","Alex's Apartment (4B)","EC","interior",1,False,False,"Apartment with child's drawings behind a wardrobe; ticket stub 'W.M.'."),
 ("LOC_EC_CONV_STORE","Quick-Mart 4:17","EC","interior",1,False,False,"Convenience store whose receipts all read 4:17."),
 ("LOC_EC_PARK","Lantern Park","EC","exterior",1,False,False,"Public park with dry fountain and benches that face the same way."),
 ("LOC_EC_ALLEY","Narrow Alley","EC","street",2,False,False,"Chalk waves on brick; leads to the Forgotten Quarter."),
 ("LOC_EC_ABANDONED_BLDG","Hartwell Hotel (abandoned)","EC","interior",2,False,False,"Gutted hotel; the empty chair; basement stair to the Static Tunnel."),
 ("LOC_EC_SAFE_ROOM","Safe Room","EC","interior",1,True,False,"Sealed cellar room under Morgan Court; first save point."),
 ("LOC_EC_ARCHIVE_TOWER","Archive Tower","EC","interior",1,False,False,"Catalogue Desk; the Archivist; blank index card."),
 ("LOC_EC_FORGOTTEN_QUARTER","Forgotten Quarter","EC","street",2,False,False,"District of tables with a missing seat; Forgotten gather here."),
 ("LOC_EC_MAYA_CAFE","Maya's Café","EC","interior",2,False,False,"Café where Maya first appears."),
 ("LOC_EC_HID_ROOFTOP","Rooftop Garden","EC","exterior",1,False,True,"Hidden roof garden on Morgan Court."),
 ("LOC_EC_HID_CLOCK_ROOM","Clockwork Room","EC","interior",1,False,True,"Hidden room inside the Archive Tower clock."),
 ("LOC_EC_HID_PLAYGROUND","Sealed Playground","EC","exterior",2,False,True,"Hidden playground behind the park; Deep Fragment 1."),
 ("LOC_DL_CROSSING","The Crossing","DL","exterior",3,False,False,"Arrival; staircases and doors in open sky."),
 ("LOC_DL_ANCHOR_FIELDS","Anchor Fields","DL","exterior",3,False,False,"Floating fields with three Shift Anchors."),
 ("LOC_DL_CRIB_ROOM","The Crib Room","DL","interior",3,True,False,"Nursery with painted-over name; safe point."),
 ("LOC_DL_ECHO_GALLERY","Time Echo Gallery","DL","interior",3,False,False,"Optional gallery of Time Echo puzzles."),
 ("LOC_DL_THE_HUM","The Hum","DL","exterior",3,False,False,"Optional sound-driven area."),
 ("LOC_DL_HID_UPSIDE_STAIRS","Upside-Down Staircase","DL","interior",3,False,True,"Hidden staircase reachable by Reality Shift."),
 ("LOC_MH_LOBBY","Hospital Lobby","MH","interior",4,False,False,"Reception, flickering signage, elevators to every floor."),
 ("LOC_MH_WARD_ALEX","Ward 11 (Alex's Room)","MH","interior",4,True,False,"Alex's bed; Maya at bedside; safe point."),
 ("LOC_MH_WAITING_ROOM","Waiting Room","MH","interior",4,False,False,"Optional; Maya's journal."),
 ("LOC_MH_RECON_LAB","Reconstruction Lab","MH","interior",4,False,False,"Machines that rebuild memories; gateway to the crash."),
 ("LOC_BF_ROAD_EDGE","Forest Road Edge","BF","exterior",4,True,False,"Bus shelter; entry to the forest; safe point."),
 ("LOC_BF_CRASH_SITE","Crash Site","BF","exterior",4,False,False,"Wrecked car, headlights, rain frozen in the air."),
 ("LOC_BF_HOLLOW","The Hollow","BF","exterior",4,False,False,"Optional puzzle clearing with sound totems."),
 ("LOC_BF_LAKE_OVERLOOK","Lake Overlook","BF","exterior",4,False,False,"Overlook of the lake where Wren died."),
 ("LOC_BF_HID_SHRINE","Hidden Shrine","BF","exterior",4,False,True,"Moss shrine to a child; Deep Fragment 2."),
 ("LOC_SD_FLOODED_STREETS","Flooded Streets","SD","street",5,False,False,"Knee-deep water, sunken cars, bent street signs."),
 ("LOC_SD_OLD_CITY_HALL","Old City Hall","SD","interior",5,False,False,"Where the Index was first built; Elias's records."),
 ("LOC_SD_ATRIUM","The Atrium","SD","interior",5,True,False,"Cathedral of memories; Architect's seat; safe point."),
 ("LOC_SD_NODE_CONTROL","Control Node","SD","interior",5,False,False,"Index node controlling edits."),
 ("LOC_SD_NODE_ARCHIVE","Archive Node","SD","interior",5,False,False,"Index node storing the Archivist."),
 ("LOC_SD_NODE_MEMORY","Memory Node","SD","interior",5,False,False,"Index node storing Wren's memories."),
 ("LOC_SD_HID_NURSERY","Sunken Nursery","SD","interior",5,False,True,"Hidden flooded nursery; Deep Fragment 3."),
 ("LOC_SD_DESCENT","The Descent","SD","tunnel",6,False,False,"Falling shaft after the Atrium collapses."),
 ("LOC_CR_SHORE","The Shore","CR","exterior",6,True,False,"Shoreline of static; Wren appears; safe point."),
 ("LOC_CR_LULLABY_PIER","Lullaby Pier","CR","exterior",6,False,False,"Pier where the lullaby puzzle is solved."),
 ("LOC_CR_CHOICE_POINT","Choice Point","CR","exterior",6,False,False,"End of the pier; the final decision."),
]
LOCS = {x[0]: dict(zip(("id","name","region","type","chapter","safe","hidden","desc"), x)) for x in L}

# a, b, route type, gate chapter (route opens), note
E = [
 ("LOC_UM_ECHO_STATION","LOC_UM_CONCOURSE","main",1,"Stairs"),
 ("LOC_UM_CONCOURSE","LOC_EC_METRO_ENTRANCE","transition",1,"Escalator to street"),
 ("LOC_EC_METRO_ENTRANCE","LOC_EC_MAIN_STREET","main",1,"Canopy exit"),
 ("LOC_EC_MAIN_STREET","LOC_EC_APT_BLDG","main",1,"Lit doorway"),
 ("LOC_EC_APT_BLDG","LOC_EC_ALEX_APT","main",1,"Stairwell"),
 ("LOC_EC_APT_BLDG","LOC_EC_SAFE_ROOM","main",1,"Basement door"),
 ("LOC_EC_APT_BLDG","LOC_EC_HID_ROOFTOP","hidden",1,"Memory Sight reveals ladder"),
 ("LOC_EC_MAIN_STREET","LOC_EC_CONV_STORE","optional",1,"Neon sign"),
 ("LOC_EC_MAIN_STREET","LOC_EC_PARK","optional",1,"Tree-lined side path"),
 ("LOC_EC_MAIN_STREET","LOC_EC_ARCHIVE_TOWER","main",1,"Tower visible at street end"),
 ("LOC_EC_ARCHIVE_TOWER","LOC_EC_HID_CLOCK_ROOM","hidden",1,"Ticking behind a panel"),
 ("LOC_EC_MAIN_STREET","LOC_EC_ALLEY","main",2,"Alley opens after Archive card"),
 ("LOC_EC_ALLEY","LOC_EC_FORGOTTEN_QUARTER","main",2,"Chalk waves lead on"),
 ("LOC_EC_FORGOTTEN_QUARTER","LOC_EC_MAYA_CAFE","main",2,"Warm light"),
 ("LOC_EC_FORGOTTEN_QUARTER","LOC_EC_ABANDONED_BLDG","main",2,"Broken revolving door"),
 ("LOC_EC_PARK","LOC_EC_FORGOTTEN_QUARTER","optional",2,"Shortcut gate"),
 ("LOC_EC_PARK","LOC_EC_HID_PLAYGROUND","hidden",2,"Hidden gate (Memory Sight)"),
 ("LOC_EC_ABANDONED_BLDG","LOC_UM_TUNNEL_STATIC","transition",2,"Basement stair to static"),
 ("LOC_UM_TUNNEL_STATIC","LOC_UM_ABANDONED_PLATFORMS","main",3,"Static dissolves"),
 ("LOC_UM_CONCOURSE","LOC_UM_ABANDONED_PLATFORMS","optional",3,"Shortcut gate opened from Line 0"),
 ("LOC_UM_ABANDONED_PLATFORMS","LOC_UM_RECORDING_ROOM","main",3,"Service door"),
 ("LOC_UM_ABANDONED_PLATFORMS","LOC_UM_HID_MAINTENANCE","hidden",3,"Vent grate"),
 ("LOC_UM_RECORDING_ROOM","LOC_DL_CROSSING","transition",3,"Static wall"),
 ("LOC_DL_CROSSING","LOC_DL_ANCHOR_FIELDS","main",3,"Floating bridge"),
 ("LOC_DL_ANCHOR_FIELDS","LOC_DL_CRIB_ROOM","main",3,"Door appears after 3 anchors"),
 ("LOC_DL_ANCHOR_FIELDS","LOC_DL_ECHO_GALLERY","optional",3,"Side door"),
 ("LOC_DL_ANCHOR_FIELDS","LOC_DL_THE_HUM","optional",3,"Low sound"),
 ("LOC_DL_ECHO_GALLERY","LOC_DL_HID_UPSIDE_STAIRS","hidden",3,"Reality Shift"),
 ("LOC_DL_CRIB_ROOM","LOC_MH_LOBBY","transition",4,"Monitor tone door"),
 ("LOC_MH_LOBBY","LOC_MH_WARD_ALEX","main",4,"Elevator"),
 ("LOC_MH_LOBBY","LOC_MH_WAITING_ROOM","optional",4,"Corridor"),
 ("LOC_MH_LOBBY","LOC_MH_RECON_LAB","main",4,"Lab corridor"),
 ("LOC_MH_RECON_LAB","LOC_BF_ROAD_EDGE","transition",4,"Memory projection"),
 ("LOC_BF_ROAD_EDGE","LOC_BF_CRASH_SITE","main",4,"Road"),
 ("LOC_BF_ROAD_EDGE","LOC_BF_HOLLOW","optional",4,"Deer trail"),
 ("LOC_BF_HOLLOW","LOC_BF_LAKE_OVERLOOK","optional",4,"Totem path"),
 ("LOC_BF_LAKE_OVERLOOK","LOC_BF_HID_SHRINE","hidden",4,"Hidden stair"),
 ("LOC_MH_WARD_ALEX","LOC_SD_FLOODED_STREETS","transition",5,"Index access door after Ch4"),
 ("LOC_SD_FLOODED_STREETS","LOC_SD_OLD_CITY_HALL","main",5,"Steps above water"),
 ("LOC_SD_OLD_CITY_HALL","LOC_SD_ATRIUM","main",5,"Great doors"),
 ("LOC_SD_ATRIUM","LOC_SD_NODE_CONTROL","main",5,"Ring corridor"),
 ("LOC_SD_ATRIUM","LOC_SD_NODE_ARCHIVE","main",5,"Ring corridor"),
 ("LOC_SD_ATRIUM","LOC_SD_NODE_MEMORY","main",5,"Ring corridor"),
 ("LOC_SD_FLOODED_STREETS","LOC_SD_HID_NURSERY","hidden",5,"Submerged door (Reality Shift)"),
 ("LOC_SD_ATRIUM","LOC_SD_DESCENT","main",6,"Floor collapses"),
 ("LOC_SD_DESCENT","LOC_CR_SHORE","main",6,"Fall ends at shoreline"),
 ("LOC_CR_SHORE","LOC_CR_LULLABY_PIER","main",6,"Pier"),
 ("LOC_CR_LULLABY_PIER","LOC_CR_CHOICE_POINT","main",6,"Pier end"),
]

# mission id, name, chapter, type, ordered locations
M = [
 ("CH1_M01","Static",1,"Main",["LOC_UM_ECHO_STATION","LOC_UM_CONCOURSE","LOC_EC_METRO_ENTRANCE"]),
 ("CH1_M02","The Empty Plaza",1,"Main",["LOC_EC_MAIN_STREET","LOC_EC_APT_BLDG","LOC_EC_SAFE_ROOM","LOC_EC_ALEX_APT"]),
 ("CH1_M03","Catalogue Desk",1,"Main",["LOC_EC_ARCHIVE_TOWER"]),
 ("CH1_S01","Lost Luggage",1,"Optional",["LOC_UM_CONCOURSE","LOC_EC_CONV_STORE"]),
 ("CH1_S02","The 4:17 Clock",1,"Optional",["LOC_EC_HID_CLOCK_ROOM"]),
 ("CH2_M01","Faceless Crowd",2,"Main",["LOC_EC_ALLEY","LOC_EC_FORGOTTEN_QUARTER"]),
 ("CH2_M02","Maya's Café",2,"Main",["LOC_EC_MAYA_CAFE"]),
 ("CH2_M03","The Seat Without a Name",2,"Main",["LOC_EC_ABANDONED_BLDG"]),
 ("CH2_S01","Calm the Whispering Man",2,"Optional",["LOC_EC_FORGOTTEN_QUARTER"]),
 ("CH2_S02","Rebuild the Wedding Photo",2,"Optional",["LOC_EC_PARK","LOC_EC_MAYA_CAFE"]),
 ("CH3_M01","Crossing",3,"Main",["LOC_UM_TUNNEL_STATIC","LOC_UM_ABANDONED_PLATFORMS","LOC_UM_RECORDING_ROOM","LOC_DL_CROSSING"]),
 ("CH3_M02","Shift Anchors",3,"Main",["LOC_DL_ANCHOR_FIELDS"]),
 ("CH3_M03","The Crib Room",3,"Main",["LOC_DL_CRIB_ROOM"]),
 ("CH3_S01","Time Echo Gallery",3,"Optional",["LOC_DL_ECHO_GALLERY"]),
 ("CH3_S02","The Hum",3,"Optional",["LOC_DL_THE_HUM"]),
 ("CH3_S03","The Maintenance Log",3,"Optional",["LOC_UM_HID_MAINTENANCE"]),
 ("CH4_M01","Hospital Echo",4,"Main",["LOC_MH_LOBBY","LOC_MH_WARD_ALEX"]),
 ("CH4_M02","The Crash",4,"Main",["LOC_MH_RECON_LAB","LOC_BF_ROAD_EDGE","LOC_BF_CRASH_SITE"]),
 ("CH4_M03","What Maya Knows",4,"Main",["LOC_MH_WARD_ALEX"]),
 ("CH4_S01","Maya's Journal",4,"Optional",["LOC_MH_WAITING_ROOM"]),
 ("CH4_S02","Voicemail Archive",4,"Optional",["LOC_MH_RECON_LAB"]),
 ("CH4_S03","Totem Hollow",4,"Optional",["LOC_BF_HOLLOW"]),
 ("CH5_M01","The Atrium",5,"Main",["LOC_SD_FLOODED_STREETS","LOC_SD_OLD_CITY_HALL","LOC_SD_ATRIUM"]),
 ("CH5_M02","The Argument",5,"Main",["LOC_SD_ATRIUM"]),
 ("CH5_M03","Three Nodes",5,"Main",["LOC_SD_NODE_CONTROL","LOC_SD_NODE_ARCHIVE","LOC_SD_NODE_MEMORY"]),
 ("CH5_S01","Elias's Recordings",5,"Optional",["LOC_SD_OLD_CITY_HALL"]),
 ("CH5_S02","The Unsent Letter",5,"Optional",["LOC_SD_ATRIUM"]),
 ("CH6_M01","The Shore",6,"Main",["LOC_CR_SHORE"]),
 ("CH6_M02","The Lullaby",6,"Main",["LOC_CR_LULLABY_PIER"]),
 ("CH6_M03","The Last Memory",6,"Main",["LOC_CR_CHOICE_POINT"]),
 ("CH6_S01","Deep Fragment Trio",6,"Optional",["LOC_CR_LULLABY_PIER"]),
]

# fragment id, name, location, kind (Core/Hidden/Deep)
F = [
 ("CH1_F01","A Name on a Ticket","LOC_UM_ECHO_STATION","Core"),("CH1_F02","The Coat Lining","LOC_EC_ALEX_APT","Hidden"),
 ("CH1_F03","Receipt at 4:17","LOC_EC_CONV_STORE","Hidden"),("CH1_F04","Rooftop Garden","LOC_EC_HID_ROOFTOP","Hidden"),
 ("CH1_F05","The Clockmaker","LOC_EC_HID_CLOCK_ROOM","Hidden"),
 ("CH2_F01","Maya's Laugh","LOC_EC_MAYA_CAFE","Core"),("CH2_F02","The Lake (blurred)","LOC_EC_PARK","Core"),
 ("CH2_F03","Chalk Waves","LOC_EC_ALLEY","Hidden"),("CH2_F04","The Empty Chair","LOC_EC_ABANDONED_BLDG","Hidden"),
 ("CH2_F05","Lullaby, Line 1","LOC_EC_HID_PLAYGROUND","Deep"),
 ("CH3_F01","Eight Years Old","LOC_DL_ANCHOR_FIELDS","Core"),("CH3_F02","Sister","LOC_DL_CRIB_ROOM","Core"),
 ("CH3_F03","Tape Zero: A Father's Voice","LOC_UM_RECORDING_ROOM","Hidden"),("CH3_F04","Echo of a Birthday","LOC_DL_ECHO_GALLERY","Hidden"),
 ("CH3_F05","The Staircase Down","LOC_DL_HID_UPSIDE_STAIRS","Hidden"),
 ("CH4_F01","The Drive","LOC_BF_CRASH_SITE","Core"),("CH4_F02","Wren's Name","LOC_MH_WARD_ALEX","Core"),
 ("CH4_F03","Maya's Vigil","LOC_MH_WAITING_ROOM","Hidden"),("CH4_F04","Lake Shadows","LOC_BF_LAKE_OVERLOOK","Hidden"),
 ("CH4_F05","Lullaby, Line 2","LOC_BF_HID_SHRINE","Deep"),
 ("CH5_F01","The Lake (clear)","LOC_SD_ATRIUM","Core"),("CH5_F02","Elias's Promise","LOC_SD_OLD_CITY_HALL","Core"),
 ("CH5_F03","The Flooded Classroom","LOC_SD_FLOODED_STREETS","Hidden"),("CH5_F04","Wren's Drawing","LOC_SD_NODE_MEMORY","Hidden"),
 ("CH5_F05","Lullaby, Line 3","LOC_SD_HID_NURSERY","Deep"),
 ("CH6_F01","The Day at the Lake","LOC_CR_CHOICE_POINT","Core"),("CH6_F02","Footprints","LOC_CR_SHORE","Hidden"),
 ("CH6_F03","The Lullaby","LOC_CR_LULLABY_PIER","Hidden"),("CH6_F04","Wren's Laugh","LOC_CR_LULLABY_PIER","Hidden"),
 ("CH6_F05","Goodbye Letter","LOC_CR_CHOICE_POINT","Hidden"),
]

# scene / cinematic references used in DIALOGUE_SCRIPT.md and CINEMATIC_SCRIPT.md
SCENES = {
 "CH1_S03_Catalogue":"LOC_EC_ARCHIVE_TOWER","CH2_S02_Cafe":"LOC_EC_MAYA_CAFE","CH3_S01_Crossing":"LOC_DL_CROSSING",
 "CH3_S02_Anchors":"LOC_DL_ANCHOR_FIELDS","CH3_S03_Crib":"LOC_DL_CRIB_ROOM","CH4_S01_Hospital":"LOC_MH_WARD_ALEX",
 "CH4_S03_Voice":"LOC_MH_WARD_ALEX","CH5_S02_Argument":"LOC_SD_ATRIUM","CH5_S03_Nodes":"LOC_SD_NODE_CONTROL",
 "CH6_S01_Shore":"LOC_CR_SHORE","CH6_S03_Choice":"LOC_CR_CHOICE_POINT",
 "CINE_01":"LOC_UM_ECHO_STATION","CINE_02":"LOC_EC_ARCHIVE_TOWER","CINE_03":"LOC_EC_ABANDONED_BLDG",
 "CINE_04":"LOC_DL_ANCHOR_FIELDS","CINE_05":"LOC_MH_WARD_ALEX","CINE_06":"LOC_SD_ATRIUM",
 "CINE_07_SAVE":"LOC_CR_CHOICE_POINT","CINE_08_RELEASE":"LOC_CR_CHOICE_POINT",
 "CINE_09_ESCAPE":"LOC_CR_CHOICE_POINT","CINE_10_SECRET":"LOC_CR_CHOICE_POINT",
}

def graph(chapter):
    g = collections.defaultdict(list)
    for a,b,t,gate,_ in E:
        if gate <= chapter:
            g[a].append(b); g[b].append(a)
    return g

def path(g, s, t):
    if s == t: return [s]
    prev = {s: None}; q = collections.deque([s])
    while q:
        u = q.popleft()
        for v in g[u]:
            if v not in prev:
                prev[v] = u
                if v == t:
                    p = [v]
                    while prev[p[-1]]: p.append(prev[p[-1]])
                    return p[::-1]
                q.append(v)
    return None

def validate():
    errs, routes = [], {}
    for a,b,*_ in E:
        for x in (a,b):
            if x not in LOCS: errs.append(f"edge uses unknown location {x}")
    for m in M:
        for x in m[4]:
            if x not in LOCS: errs.append(f"{m[0]} uses unknown location {x}")
    for f in F:
        if f[2] not in LOCS: errs.append(f"fragment {f[0]} unknown location {f[2]}")
    for k,v in SCENES.items():
        if v not in LOCS: errs.append(f"scene {k} unknown location {v}")
    # main-mission chain
    cur = "LOC_UM_ECHO_STATION"
    for mid,name,ch,typ,locs in M:
        g = graph(ch)
        if typ == "Main":
            seq = [cur] + locs
        else:
            seq = [anchor.get(ch, cur)] + locs
        full = []
        for a,b in zip(seq, seq[1:]):
            p = path(g, a, b)
            if p is None: errs.append(f"{mid}: no route {a} -> {b} with chapter {ch} gates"); break
            full += p if not full else p[1:]
        routes[mid] = full
        if typ == "Main":
            cur = locs[-1]
            anchor = globals().setdefault("anchor", {}); anchor[ch] = cur
    # chapter 1 optional anchors need the chapter's spine point
    # all locations reachable by chapter 6
    g6 = graph(6)
    seen = {"LOC_UM_ECHO_STATION"}; q = [*seen]
    while q:
        u = q.pop()
        for v in g6[u]:
            if v not in seen: seen.add(v); q.append(v)
    for l in LOCS:
        if l not in seen: errs.append(f"unreachable: {l}")
    # fragments: 30, 3 deep, 5 per chapter
    if len(F) != 30: errs.append(f"fragment count {len(F)} != 30")
    if sum(1 for f in F if f[3]=="Deep") != 3: errs.append("deep fragments != 3")
    for c in range(1,7):
        if sum(1 for f in F if f[0].startswith(f"CH{c}_")) != 5: errs.append(f"chapter {c} fragments != 5")
    # every location referenced by some mission, fragment or scene or is on a route
    used = set()
    for r in routes.values(): used.update(r)
    for l in LOCS:
        if l not in used and not any(f[2]==l for f in F):
            errs.append(f"orphan location (no mission route/fragment): {l}")
    return errs, routes

def name(l): return LOCS[l]["name"]

def gen_register(routes):
    refs = collections.defaultdict(list)
    for mid,_,_,_,locs in M:
        for l in locs: refs[l].append(mid)
    frs = collections.defaultdict(list)
    for f in F: frs[f[2]].append(f[0])
    sc = collections.defaultdict(list)
    for k,v in SCENES.items(): sc[v].append(k)
    o = ["# Location Register\n",
         "Generated from `tools/world_data.py`. **Do not edit by hand**; edit the data file and run `python3 tools/world_data.py`.\n",
         "## ID conventions\n",
         "| Namespace | Pattern | Example | Used by |\n|---|---|---|---|",
         "| Location | `LOC_<REGION>_<NAME>` (`HID` marks hidden) | `LOC_EC_ARCHIVE_TOWER` | missions, dialogue scenes, cinematics, save data |",
         "| Region | 2-letter code | `EC` | location IDs |",
         "| Mission | `CH#_M##` main, `CH#_S##` optional | `CH3_M02` | mission data, save flags |",
         "| Fragment | `CH#_F##` | `CH2_F05` | save data, journal |",
         "| Scene | `CH#_S##_Name` | `CH1_S03_Catalogue` | dialogue script |",
         "| Cinematic | `CINE_##` | `CINE_05` | cinematic script |\n",
         "Save data stores `current_location` (a `LOC_*` ID) and `visited_locations` (array of `LOC_*` IDs) in `GameState`.\n",
         "## Regions\n","| Code | Region | First chapter | Summary |\n|---|---|---|---|"]
    for c,(n,ch,s) in REGIONS.items(): o.append(f"| {c} | {n} | {ch} | {s} |")
    o += ["\n## Locations\n","| ID | Name | Type | Ch | Safe | Hidden | Missions | Fragments | Scenes / Cinematics |","|---|---|---|---|---|---|---|---|---|"]
    for l,d in LOCS.items():
        o.append(f"| `{l}` | {d['name']} | {d['type']} | {d['chapter']} | {'yes' if d['safe'] else ''} | {'yes' if d['hidden'] else ''} | {', '.join(refs[l])} | {', '.join(frs[l])} | {', '.join(sc[l])} |")
    o += ["\n## Memory fragments (30; Core = story, Hidden = optional, Deep = secret ending)\n","| ID | Name | Kind | Location |","|---|---|---|---|"]
    for f in F: o.append(f"| {f[0]} | {f[1]} | {f[3]} | `{f[2]}` |")
    o += ["\n## Scene and cinematic references\n","| Reference | Location |","|---|---|"]
    for k,v in SCENES.items(): o.append(f"| {k} | `{v}` |")
    return "\n".join(o)+"\n"

STY = {"main":"---","optional":"-.-","hidden":"-.-","transition":"==="}
def edge(a,b,t,label=""):
    s = {"main":"---","optional":"-.-","hidden":"-.-","transition":"==="}[t]
    return f"  {a} {s} {b}" if not label else f"  {a} {s}|{label}| {b}"

def gen_map():
    o = ["# World Map\n","Generated from `tools/world_data.py`.\n",
         "Legend: solid = main route, dotted = optional route, dotted with `hidden` = hidden route, thick = region transition.\n",
         "## Master map\n","```mermaid","flowchart TB"]
    for c,(n,_,_) in REGIONS.items():
        o.append(f"  subgraph {c}[\"{n}\"]")
        for l,d in LOCS.items():
            if d["region"]==c: o.append(f"    {l}[\"{d['name']}\"]")
        o.append("  end")
    for a,b,t,g,_ in E:
        o.append(edge(a,b,t,"hidden" if t=="hidden" else ""))
    o.append("```\n")
    o += ["## Region progression\n","| Order | Region | Chapter | Enters from | Leaves to |","|---|---|---|---|---|",
          "| 1 | Underground Metro (Echo Station) | 1 | start | Echo City |",
          "| 2 | Echo City | 1–2 | Echo Station | Static Tunnel |",
          "| 3 | Underground Metro (Line 0) | 3 | Static Tunnel | Dreamland |",
          "| 4 | Dreamland | 3 | Recording Room | Memory Hospital |",
          "| 5 | Memory Hospital / Black Forest | 4 | Crib Room | Sunken District |",
          "| 6 | Sunken District | 5 | Ward 11 | The Core |",
          "| 7 | The Core | 6 | The Descent | endings |\n",
          "## Region transitions\n","| From | To | Gate chapter | Trigger |","|---|---|---|---|"]
    for a,b,t,g,n in E:
        if t=="transition": o.append(f"| `{a}` | `{b}` | {g} | {n} |")
    o += ["\n## Backtracking and fast travel\n",
          "- Doors never lock behind the player; all opened routes stay open (Chapter Replay can restore earlier states).",
          "- Safe points (`safe=yes` in LOCATION_REGISTER.md) are save points and fast-travel nodes. Fast travel is allowed between visited safe points inside regions unlocked by the current chapter, and is disabled during pursuit sequences.",
          "- Regions sealed by story: after the Ch5 Atrium collapse, Echo City, Metro, Dreamland, Hospital and Forest are no longer reachable in the main save; Chapter Replay loads them.",
          "\n## Connection list\n","| From | To | Route | Opens in Ch | Visual cue |","|---|---|---|---|---|"]
    for a,b,t,g,n in E: o.append(f"| `{a}` | `{b}` | {t} | {g} | {n} |")
    return "\n".join(o)+"\n"

def gen_flows(routes):
    o = ["# Level Flow Diagrams\n","Generated from `tools/world_data.py`. Every main mission has a validated route using only routes open in that chapter.\n"]
    for ch in range(1,7):
        ms = [m for m in M if m[2]==ch]
        nodes = {}
        for m in ms:
            for l in routes[m[0]]:
                nodes.setdefault(l, [])
            for l in m[4]: nodes[l].append(m[0])
        o += [f"## Chapter {ch}\n","| Mission | Type | Route |","|---|---|---|"]
        for m in ms:
            o.append(f"| {m[0]} {m[1]} | {m[3]} | {' → '.join(name(x) for x in routes[m[0]])} |")
        o += ["","```mermaid","flowchart LR"]
        for l,lst in nodes.items():
            lab = name(l) + ("<br/>" + ", ".join(lst) if lst else "")
            o.append(f"  {l}[\"{lab}\"]")
        for a,b,t,g,_ in E:
            if g <= ch and a in nodes and b in nodes: o.append(edge(a,b,t))
        o += ["```\n"]
    o += ["## Mission to location matrix\n","| Mission | Name | Type | Chapter | Locations |","|---|---|---|---|---|"]
    for m in M: o.append(f"| {m[0]} | {m[1]} | {m[3]} | {m[2]} | {', '.join('`'+x+'`' for x in m[4])} |")
    return "\n".join(o)+"\n"

def gen_gd():
    o = ["# Generated by tools/world_data.py. Do not edit by hand.","class_name LocationIDs","extends RefCounted\n"]
    for l in LOCS: o.append(f'const {l[4:]} := "{l}"')
    o.append("\nconst SAFE_POINTS: Array[String] = [" + ", ".join(f'"{l}"' for l,d in LOCS.items() if d["safe"]) + "]")
    return "\n".join(o)+"\n"

if __name__ == "__main__":
    errs, routes = validate()
    if errs:
        print("VALIDATION FAILED"); [print(" -", e) for e in errs]; sys.exit(1)
    w = lambda p,t: open(os.path.join(ROOT,p),"w").write(t)
    w("docs/LOCATION_REGISTER.md", gen_register(routes))
    w("docs/WORLD_MAP.md", gen_map())
    w("docs/LEVEL_FLOW_DIAGRAMS.md", gen_flows(routes))
    w("scripts/systems/location_ids.gd", gen_gd())
    mains = [m for m in M if m[3]=="Main"]
    print(f"OK: {len(LOCS)} locations, {len(E)} routes, {len(M)} missions ({len(mains)} main), {len(F)} fragments, {len(SCENES)} scene refs")
    for m in M:
        print(f"{m[0]:7} {len(routes[m[0]])} steps: {' > '.join(x[4:] for x in routes[m[0]])}")
