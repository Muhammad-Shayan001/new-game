"""Generates the world-derived game data from tools/world_data.py (single source of truth):
resources/locations/<REGION>.json, resources/missions/CH#.json, resources/fragments/fragments.json,
resources/localization/en_world.json. Hand-authored content (dialogue, items, abilities, puzzles,
interactions, characters) lives directly in resources/ and is never overwritten.
Usage: python3 tools/build_content.py   (also regenerates the world docs)
"""
import json, os, collections, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import world_data as W

ROOT = W.ROOT
def dump(path, obj):
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", encoding="utf-8") as f:
        json.dump(obj, f, indent=1, ensure_ascii=False)
        f.write("\n")

errs, routes = W.validate()
if errs:
    print("world_data validation failed:"); [print(" -", e) for e in errs]; sys.exit(1)

# ---------------------------------------------------------------- locations
adj = collections.defaultdict(list)
for a, b, t, gate, note in W.E:
    adj[a].append({"to": b, "route": t, "gate_chapter": gate})
    adj[b].append({"to": a, "route": t, "gate_chapter": gate})
by_region = collections.defaultdict(list)
for lid, d in W.LOCS.items():
    by_region[d["region"]].append({
        "id": lid, "name_key": "loc." + lid, "region": d["region"], "type": d["type"],
        "chapter": d["chapter"], "safe": d["safe"], "hidden": d["hidden"], "connections": adj[lid]})
for code, entries in by_region.items():
    dump(f"resources/locations/{code}.json", {"entries": entries})

# ---------------------------------------------------------------- fragments
dump("resources/fragments/fragments.json", {"entries": [
    {"id": f[0], "name_key": "frag." + f[0], "location": f[2], "kind": f[3], "chapter": int(f[0][2])}
    for f in W.F]})

# ---------------------------------------------------------------- missions
EXTRA_OBJ = {  # objectives that are not "reach a location"
    "CH1_M03": [{"id": "talk_archivist", "text_key": "obj.talk_archivist",
                 "complete_when": {"event": "dialogue_finished", "arg": "DLG_CH1_CATALOGUE"}}],
    "CH2_M02": [{"id": "talk_maya", "text_key": "obj.talk_maya",
                 "complete_when": {"event": "dialogue_finished", "arg": "DLG_CH2_CAFE"}}],
}
ON_START = {"CH1_M01": [{"do": "unlock_ability", "id": "ABL_MEMORY_SIGHT"}],
            "CH3_M02": [{"do": "unlock_ability", "id": "ABL_REALITY_SHIFT"}, {"do": "unlock_ability", "id": "ABL_TIME_ECHO"}]}
ON_COMPLETE_EXTRA = {"CH5_M01": [{"do": "unlock_ability", "id": "ABL_ECHO_VOICE"}],
                     "CH6_M03": [{"do": "set_flag", "flag": "game_complete"}]}
by_chapter = collections.defaultdict(list)
for mid, name, ch, typ, locs in W.M:
    objs = []
    for l in dict.fromkeys(locs):
        objs.append({"id": "reach_" + l[4:].lower(), "text_key": "obj.reach",
                     "args_keys": {"place": "loc." + l}, "complete_when": {"event": "location_entered", "arg": l}})
    objs += EXTRA_OBJ.get(mid, [])
    if typ == "Main":
        n = int(mid[2]); k = int(mid[-2:])
        if k == 1:
            req = {} if n == 1 else {"mission": [f"CH{n-1}_M03", "COMPLETE"]}
        else:
            req = {"mission": [f"CH{n}_M{k-1:02d}", "COMPLETE"]}
    else:
        req = {"chapter_gte": ch}
    on_complete = []
    if typ == "Main" and mid.endswith("M03") and ch < 6:
        on_complete += [{"do": "set_chapter", "value": ch + 1}, {"do": "toast", "key": "ui.chapter_complete"}]
    on_complete += ON_COMPLETE_EXTRA.get(mid, [])
    m = {"id": mid, "name_key": "mission." + mid, "chapter": ch, "type": "Main" if typ == "Main" else "Secondary",
         "location": locs[0], "objectives": objs, "unlock_requires": req, "auto_start": True}
    if mid in ON_START: m["on_start"] = ON_START[mid]
    if on_complete: m["on_complete"] = on_complete
    by_chapter[ch].append(m)
for ch, ms in by_chapter.items():
    dump(f"resources/missions/CH{ch}.json", {"entries": ms})

# ---------------------------------------------------------------- localization (generated names)
loc = {}
for lid, d in W.LOCS.items(): loc["loc." + lid] = d["name"]
for mid, name, *_ in W.M: loc["mission." + mid] = name
for f in W.F: loc["frag." + f[0]] = f[1]
for code, (n, *_r) in W.REGIONS.items(): loc["region." + code] = n
dump("resources/localization/en_world.json", loc)

W_main = os.path.join(ROOT, "tools", "world_data.py")
subprocess.run([sys.executable, W_main], check=True, stdout=subprocess.DEVNULL)
print(f"built: {len(W.LOCS)} locations, {len(W.M)} missions, {len(W.F)} fragments")
