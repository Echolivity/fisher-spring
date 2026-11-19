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
    loader = [b for b in BOXES.values() if b.get("text", "").startswith("js ech_ir_loader.js")][0]["id"]
    feeds = {BOXES[l["patchline"]["source"][0]].get("text", "") for l in P["lines"]
             if l["patchline"]["destination"][0] == loader}
    for needed in ("load", "prepend irsr", "prepend sr", "prepend decay", "prepend damping"):
        assert needed in feeds, f"IR loader gets nothing from '{needed}'"
