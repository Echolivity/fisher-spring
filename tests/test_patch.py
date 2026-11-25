"""Static checks on the built Max patch (device/Echolivity.maxpat). No Max needed.

Added 19 Nov 2026 after "plugin~ 2" (= right input only) silenced the device in Live.
Run: python -m pytest tests/test_patch.py -q
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
P = json.load(open(os.path.join(ROOT, "device", "Echolivity.maxpat")))["patcher"]
BOXES = {b["box"]["id"]: b["box"] for b in P["boxes"]}


def by_first_word(word):
    return [b for b in BOXES.values() if b.get("text", "").split(" ")[0] == word]


def outgoing(box_id):
    return [l["patchline"] for l in P["lines"] if l["patchline"]["source"][0] == box_id]


def test_audio_io_uses_both_channels():
    for name in ("plugin~", "plugout~"):
        found = by_first_word(name)
        assert len(found) == 1, f"expected one {name}"
        args = found[0]["text"].split()[1:]
        # no args = channels 1 and 2; explicit "1 2" is also fine; anything else drops a channel
        assert args in ([], ["1", "2"]), f"{name} {' '.join(args)} does not carry both channels"


def test_both_inputs_reach_the_dsp():
    pin = by_first_word("plugin~")[0]["id"]
    used = {l["source"][1] for l in outgoing(pin)}
    assert used == {0, 1}, f"plugin~ outlets used: {sorted(used)}"


def test_both_outputs_are_fed():
    pout = by_first_word("plugout~")[0]["id"]
    fed = {l["patchline"]["destination"][1] for l in P["lines"] if l["patchline"]["destination"][0] == pout}
    assert fed == {0, 1}, f"plugout~ inlets fed: {sorted(fed)}"


def test_ir_sample_rate_comes_from_info_left_outlet():
    info = by_first_word("info~")[0]["id"]
    to_irsr = [l for l in outgoing(info)
               if BOXES[l["destination"][0]].get("text", "").startswith("prepend irsr")]
    assert to_irsr and all(l["source"][1] == 0 for l in to_irsr)


def test_every_connection_in_range():
    for l in P["lines"]:
        (s, so), (d, di) = l["patchline"]["source"], l["patchline"]["destination"]
        assert s in BOXES and d in BOXES
        assert so < BOXES[s]["numoutlets"] and di < BOXES[d]["numinlets"], (BOXES[s].get("text"), so, BOXES[d].get("text"), di)


def test_ir_loader_receives_load_and_sample_rates():
    loader = [b for b in BOXES.values() if b.get("varname") == "ech_ir_loader"][0]["id"]
    feeds = {BOXES[l["patchline"]["source"][0]].get("text", "") for l in P["lines"]
             if l["patchline"]["destination"][0] == loader}
    for needed in ("load", "prepend irsr", "prepend sr", "prepend decay", "prepend damping",
                   "names ---echIR ---echH"):
        assert needed in feeds, f"IR loader gets nothing from '{needed}'"


def test_scripts_are_embedded():
    """No [js file.js] boxes: Live could not find the files (19 Nov)."""
    assert not by_first_word("js")
    codeboxes = [b for b in BOXES.values() if b["maxclass"] == "v8.codebox"]
    assert len(codeboxes) == 2 and all(len(b.get("code", "")) > 500 for b in codeboxes)
    assert all("jsarguments" not in b["code"] for b in codeboxes)


def test_gen_functions_come_first():
    """gen~: 'function definitions must precede all statements' (Max console, 19 Nov)."""
    import re
    for f in ("ech_front", "ech_back", "ech_conv"):
        src = re.sub(r"//[^\n]*", "", open(os.path.join(ROOT, "device", "gen", f + ".genexpr")).read())
        lines = [l for l in src.split("\n") if l.strip()]
        first_stmt = next((i for i, l in enumerate(lines) if not re.match(r"^\w+\s*\([\w\s,]*\)\s*\{$", l)
                           and not l.startswith(("\t", "}"))), 0)
        later_funcs = [l for l in lines[first_stmt:] if re.match(r"^\w+\s*\([\w\s,]*\)\s*\{$", l)]
        assert not later_funcs, f"{f}: function defined after a statement: {later_funcs}"


def test_dials_reach_dsp_in_dsp_units():
    """Percent dials run x100 and must pass a [* 0.01] before their 'prepend <param>'."""
    import sys
    sys.path.insert(0, ROOT)
    from reference.params import PARAMS
    gen = {"mix": "drywet"}
    for b in BOXES.values():
        v = b.get("saved_attribute_attributes", {}).get("valueof", {})
        if b["maxclass"] != "live.dial":
            continue
        key = next(k for k in PARAMS if v["parameter_longname"] in (k,) or b["varname"] == {
            "drive": "Drive", "decay": "Decay", "tone": "Tone", "damping": "Damping", "mix": "Mix", "output": "Output",
            "boing": "Boing", "tension": "Tension", "dispersion": "Dispersion", "resonance": "Resonance",
            "movement": "Movement", "ir_level": "IR Level", "model_level": "Model Level", "blend": "Hybrid Blend",
            "feedback": "Feedback", "fb_tone": "FB Tone", "fb_drive": "FB Drive", "fb_damping": "FB Damping",
            "self_osc": "Self-Osc", "predelay": "Pre-delay", "width": "Width", "modulation": "Modulation"}.get(k))
        factor = 1.0
        # the hardware panel's image driver ([expr] -> [prepend offset 0] -> fpic) is not a DSP path
        targets = [BOXES[l["destination"][0]] for l in outgoing(b["id"])
                   if not BOXES[l["destination"][0]].get("text", "").startswith("expr -int(")]
        if len(targets) == 1 and targets[0].get("text") == "* 0.01":
            factor = 0.01
            targets = [BOXES[l["destination"][0]] for l in outgoing(targets[0]["id"])]
        texts = [t.get("text") for t in targets]
        assert f"prepend {gen.get(key, key)}" in texts, (key, texts)
        lo, hi = PARAMS[key][:2]
        assert abs(v["parameter_mmin"] * factor - lo) < 1e-9 and abs(v["parameter_mmax"] * factor - hi) < 1e-9, key


def test_panel_layout_fits_and_does_not_overlap():
    W = P["devicewidth"]
    # images (fpic) are underlays and the background-layer fallback message is covered by the faceplate
    items = [b for b in BOXES.values() if b.get("presentation") and b["maxclass"] not in ("panel", "fpic")
             and not b.get("background")]
    for b in items:
        x, y, w, h = b["presentation_rect"]
        assert x >= 0 and y >= 0 and x + w <= W and y + h <= 169, (b.get("varname") or b.get("text"), b["presentation_rect"])
    for i, a in enumerate(items):
        for c in items[i + 1:]:
            ax, ay, aw, ah = a["presentation_rect"]; cx, cy, cw, ch = c["presentation_rect"]
            overlap = ax < cx + cw and cx < ax + aw and ay < cy + ch and cy < ay + ah
            assert not overlap, (a.get("varname") or a.get("text"), c.get("varname") or c.get("text"))


def test_preset_menu_entries_match_selector():
    um = [b for b in BOXES.values() if b["maxclass"] == "umenu"][0]
    n_entries = um["items"].count(",") + 1
    sel = [b for b in BOXES.values() if b.get("text", "").startswith("sel ")][0]
    picks = [int(t) for t in sel["text"].split()[1:]]
    assert picks == list(range(1, n_entries)), (n_entries, picks)   # entry 0 is the header


def test_hardware_panel_image_knobs():
    """Hardware panel: one image knob per dial, drawn before it, horizontally centred on it and
    between its name and value, driven by the dial; faceplate in the background layer; every
    image present next to the device in 1x and @2x."""
    import os
    order = [b["box"]["id"] for b in P["boxes"]]
    dials = [b for b in BOXES.values() if b["maxclass"] == "live.dial"]
    pics = {b["id"]: b for b in BOXES.values() if b["maxclass"] == "fpic"}
    face = [b for b in pics.values() if b.get("background") == 1]
    assert len(face) == 1 and face[0]["presentation_rect"] == [0, 0, P["devicewidth"], 169]
    assert len(pics) == len(dials) + 1
    for d in dials:
        fr = [BOXES[l["destination"][0]] for l in outgoing(d["id"])
              if BOXES[l["destination"][0]].get("text", "").startswith("expr -int(")]
        assert len(fr) == 1, d["varname"]
        of = [BOXES[l["destination"][0]] for l in outgoing(fr[0]["id"])]
        assert len(of) == 1 and of[0]["text"] == "prepend offset 0"
        pic = [BOXES[l["destination"][0]] for l in outgoing(of[0]["id"])]
        assert len(pic) == 1 and pic[0]["maxclass"] == "fpic"
        pic = pic[0]
        assert order.index(pic["id"]) < order.index(d["id"])
        dx, dy, dw, dh = d["presentation_rect"]; px, py, pw, ph = pic["presentation_rect"]
        assert abs((px + pw / 2) - (dx + dw / 2)) < 0.11 and dy + 11 <= py and py + ph <= dy + dh - 9
        assert all(d[c] == [0.0, 0.0, 0.0, 0.0] for c in ("activedialcolor", "dialcolor", "needlecolor"))
    for b in pics.values():
        for n in (b["pic"], b["pic"].replace(".png", "@2x.png")):
            assert os.path.exists(os.path.join(ROOT, "device", n)), n
