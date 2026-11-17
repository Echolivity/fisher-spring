"""Diagnostic ladder for a Live load crash: builds reduced copies of device/Echolivity.amxd.

  FS Test 1 Passthrough   plugin~ -> plugout~ only
  FS Test 2 Gen only      the three gen~ objects with their buffers/delays; no js, no UI
  FS Test 3 Gen + js      as 2, plus the js IR loader/UI scripts and pattrstorage; no panel controls
  FS Test 4 UI only       every panel control and js; gen~ removed, audio passes through
  (the full device is the last rung)

Drop them into Live one at a time; the first that crashes points at the cause.
Usage: python tools/make_bisect.py OUTDIR   (copy OUTDIR next to device/ so js/IR paths resolve)
"""
import copy
import json
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
full = json.loads((ROOT / "device" / "Echolivity.maxpat").read_text())
UI = {"live.dial", "live.menu", "live.drop", "umenu", "comment", "live.comment", "panel", "message"}


def first(b):
    return b.get("text", "").split(" ")[0]


def variant(keep, passthrough=False):
    p = copy.deepcopy(full)
    P = p["patcher"]
    P["boxes"] = [b for b in P["boxes"] if keep(b["box"])]
    ids = {b["box"]["id"] for b in P["boxes"]}
    P["lines"] = [l for l in P["lines"] if l["patchline"]["source"][0] in ids and l["patchline"]["destination"][0] in ids]
    if passthrough:
        pin = next(b["box"]["id"] for b in P["boxes"] if first(b["box"]) == "plugin~")
        pout = next(b["box"]["id"] for b in P["boxes"] if first(b["box"]) == "plugout~")
        P["lines"] = [l for l in P["lines"] if l["patchline"]["destination"][0] != pout]
        P["lines"] += [{"patchline": {"source": [pin, 0], "destination": [pout, 0]}},
                       {"patchline": {"source": [pin, 1], "destination": [pout, 1]}}]
    prm = {k: v for k, v in P["parameters"].items() if k in ids}
    names = [v[0] for v in prm.values()]
    banks = {}
    for i, (k, bk) in enumerate(P["parameters"]["parameterbanks"].items()):
        ps = [x if x in names else "-" for x in bk["parameters"]]
        if any(x != "-" for x in ps):
            banks[str(len(banks))] = dict(bk, index=len(banks), parameters=ps)
    prm["parameterbanks"] = banks
    prm["inherited_shortname"] = 1
    P["parameters"] = prm
    return p


def amxd(pat):
    body = json.dumps(pat, indent=1).encode("utf-8") + b"\x00"
    return (b"ampf" + struct.pack("<I", 4) + b"aaaa" + b"meta" + struct.pack("<I", 4) + b"\x00\x00\x00\x00"
            + b"ptch" + struct.pack("<I", len(body)) + body)


io = lambda b: first(b) in ("plugin~", "plugout~")
js = lambda b: first(b) in ("js", "pattrstorage", "pattr", "live.thisdevice")
ladder = {
    "FS Test 1 Passthrough": variant(io, passthrough=True),
    "FS Test 2 Gen only": variant(lambda b: b["maxclass"] not in UI and not js(b)),
    "FS Test 3 Gen + js": variant(lambda b: b["maxclass"] not in UI),
    "FS Test 4 UI only": variant(lambda b: first(b) != "gen~", passthrough=True),
}
out = Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
for name, p in ladder.items():
    (out / f"{name}.amxd").write_bytes(amxd(p))
    P = p["patcher"]
    print(f"{name}: {len(P['boxes'])} boxes, {len(P['lines'])} lines, {len(P['parameters']) - 2} params")
