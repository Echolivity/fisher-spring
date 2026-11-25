"""Builds the Max for Live device from source:
  device/gen/*.genexpr  -> embedded gen~ codeboxes
  reference/params.py   -> live.dial / live.menu parameters (names, ranges, defaults)
  presets/*.json        -> in-device factory preset menu
  ir/catalogue.json     -> IR library menu
Writes device/Echolivity.maxpat (open in Max) and device/Echolivity.amxd (drop in Live).
"""
import json, os, struct, sys, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)
from reference.params import PARAMS, ENGINE_MODES  # noqa

DEV = os.path.join(ROOT, "device")
# Hardware-replica panel (Echolivity family look): brushed-brass faceplate after the Fisher K-10,
# engraved section frames, image knobs under transparent live.dial graphics. Images are rendered
# by tools/render_panel.py into device/ (fisher_*.png, 1x and @2x), next to the .amxd.
sys.path.insert(0, os.path.join(ROOT, "tools"))
import hwpanel  # noqa: E402
APPV = {"major": 8, "minor": 6, "revision": 0, "architecture": "x64", "modernui": 1}

boxes, lines = [], []
_id = [0]


def nid():
    _id[0] += 1
    return f"obj-{_id[0]}"


def box(text=None, rect=(0, 0, 100, 22), maxclass="newobj", ins=1, outs=1, **kw):
    i = nid()
    b = {"id": i, "maxclass": maxclass, "numinlets": ins, "numoutlets": outs,
         "outlettype": [""] * outs, "patching_rect": list(rect)}
    if text is not None:
        b["text"] = text
    b.update(kw)
    boxes.append({"box": b})
    return i


def line(a, ao, b, bi):
    lines.append({"patchline": {"source": [a, ao], "destination": [b, bi]}})


def gen_patcher(code, n_in, n_out):
    g_boxes, g_lines = [], []
    cid = "obj-1"
    g_boxes.append({"box": {"id": cid, "maxclass": "codebox", "code": code, "fontface": 0,
                            "fontname": "<Monospaced>", "fontsize": 11, "numinlets": n_in,
                            "numoutlets": n_out, "outlettype": [""] * n_out,
                            "patching_rect": [20, 60, 700, 600]}})
    for k in range(n_in):
        i = f"obj-{k + 2}"
        g_boxes.append({"box": {"id": i, "maxclass": "newobj", "text": f"in {k + 1}", "numinlets": 0,
                                "numoutlets": 1, "outlettype": [""], "patching_rect": [20 + 80 * k, 20, 40, 22]}})
        g_lines.append({"patchline": {"source": [i, 0], "destination": [cid, k]}})
    for k in range(n_out):
        o = f"obj-{n_in + k + 2}"
        g_boxes.append({"box": {"id": o, "maxclass": "newobj", "text": f"out {k + 1}", "numinlets": 1,
                                "numoutlets": 0, "patching_rect": [20 + 80 * k, 680, 45, 22]}})
        g_lines.append({"patchline": {"source": [cid, k], "destination": [o, 0]}})
    return {"fileversion": 1, "appversion": APPV, "classnamespace": "dsp.gen", "rect": [50, 50, 760, 740],
            "boxes": g_boxes, "lines": g_lines}


def gen_box(name, n_in, n_out, rect):
    code = open(os.path.join(DEV, "gen", name + ".genexpr")).read()
    return box("gen~", rect, ins=n_in, outs=n_out, outlettype=["signal"] * n_out,
               patcher=gen_patcher(code, n_in, n_out), varname=name)


# ---- labels / formatting ------------------------------------------------------
LABEL = {"drive": "Drive", "decay": "Decay", "tone": "Tone", "damping": "Damping", "mix": "Mix",
         "output": "Output", "boing": "Boing", "tension": "Tension", "dispersion": "Dispersion",
         "resonance": "Resonance", "movement": "Movement", "ir_level": "IR Level",
         "model_level": "Model Level", "blend": "Hybrid Blend", "feedback": "Feedback",
         "fb_tone": "FB Tone", "fb_drive": "FB Drive", "fb_damping": "FB Damping",
         "self_osc": "Self-Osc", "predelay": "Pre-delay", "width": "Width", "modulation": "Modulation"}
SHORT = {"model_level": "Model", "ir_level": "IR", "blend": "Blend", "self_osc": "Self-Osc",
         "fb_damping": "FB Damp", "dispersion": "Disperse", "resonance": "Reso", "modulation": "Mod",
         "movement": "Motion", "predelay": "Pre-Dly"}
FRONT = {"drive", "predelay", "engine_mode"}
BACK = set(PARAMS) - {"predelay"}
GEN_NAME = {"mix": "drywet"}
LOADER = {"decay", "damping"}


# ---- look ---------------------------------------------------------------------------
# Palette from assets/fisher-spring-banner.svg / signal-flow.svg (walnut, brass, valve orange)
def rgba(h, a=1.0):
    h = h.lstrip("#")
    return [round(int(h[i:i + 2], 16) / 255, 4) for i in (0, 2, 4)] + [a]


C = {"bg": "#16130f", "panel": "#211a14", "border": "#5a4630", "brass": "#d4ae5f", "brass_hi": "#e9c97f",
     "orange": "#d9774a", "text": "#d9c7ae", "muted": "#9d8b76", "track": "#3a2f25", "cream": "#f3ead9",
     "field": "#100d0a"}
# hardware panel: legends engraved dark on brass (fields stay dark with light text)
C.update({"text": "#24180c", "muted": "#4a3721", "brass": "#1e140a", "brass_hi": "#1e140a",
          "orange": "#9a3412", "field_text": "#e9dcc4"})
DUB_ACCENT = {"feedback", "self_osc", "fb_drive", "fb_tone", "fb_damping"}
KNOB_BOX = 26          # image knob size; centred between a 44x48 live.dial's name and value
KNOB_DY = 26           # knob centre below the dial's top edge
SPEC = {"prefix": "fisher_", "H": 169, "screws": False, "knob_boxes": {"fs": KNOB_BOX}, "knobs": {}, "frames": [],
        "finish": {"base": (178, 146, 88), "texture": "brushed", "legend": (36, 24, 12),
                   "rule": (110, 86, 50)}}

# Unitless 0..1 / -1..1 / 0..2 controls are shown in percent: the dial runs x100 and a
# [* 0.01] box scales it back before gen~, so the DSP ranges are unchanged.
PCT = {k for k, v in PARAMS.items() if v[3] == "" and k != "engine_mode"}


def unit(k):
    u = PARAMS[k][3]
    if u == "dB":
        return {"parameter_unitstyle": 4}
    if u == "ms":
        return {"parameter_unitstyle": 2}
    if u == "s":
        return {"parameter_unitstyle": 9, "parameter_units": "%.2f s"}
    return {"parameter_unitstyle": 5}                       # percent


def dial_range(k):
    lo, hi, dflt = PARAMS[k][:3]
    f = 100.0 if k in PCT else 1.0
    return lo * f, hi * f, dflt * f


def dial(k, prect):
    lo, hi, dflt = dial_range(k)
    va = {"parameter_longname": LABEL[k], "parameter_shortname": SHORT.get(k, LABEL[k]),
          "parameter_type": 0, "parameter_mmin": lo, "parameter_mmax": hi,
          "parameter_initial": [dflt], "parameter_initial_enable": 1, **unit(k)}
    if k in ("decay", "predelay"):
        va["parameter_exponent"] = 2.0
    acc = C["orange"] if k in DUB_ACCENT else C["brass"]
    # image knob first (drawn below), then the dial with transparent knob graphics on top
    SPEC["knobs"][k] = {"cx": prect[0] + prect[2] / 2, "cy": prect[1] + KNOB_DY, "kind": "fs", "scale": "none"}
    pic = box(None, (1700, 20 + 30 * len(SPEC["knobs"]), KNOB_BOX, KNOB_BOX), maxclass="fpic", ins=1, outs=0,
              outlettype=[], presentation=1, presentation_rect=hwpanel.rect(SPEC, "knob", k),
              pic=hwpanel.image_name(SPEC, "knob", k), autofit=0)
    d = box(None, (40 + 60 * len(boxes) % 1200, 900, 44, 48), maxclass="live.dial", ins=1, outs=2,
            outlettype=["", "float"], parameter_enable=1, presentation=1,
            presentation_rect=list(prect), saved_attribute_attributes={"valueof": va},
            varname=LABEL[k], showname=1, shownumber=1, fontsize=9.0, fontname="Arial Bold",
            textcolor=rgba(C["orange"] if k in DUB_ACCENT else C["text"]), focusbordercolor=rgba(acc),
            triangle=0, **{c: hwpanel.CLEAR for c in ("activedialcolor", "dialcolor", "activeneedlecolor",
                                                      "needlecolor", "tricolor")})
    fr = box("expr " + hwpanel.knob_frame_expr(KNOB_BOX, lo, hi, va.get("parameter_exponent", 1.0)),
             (1760, 20 + 30 * len(SPEC["knobs"]), 300, 22))
    of = box("prepend offset 0", (2080, 20 + 30 * len(SPEC["knobs"]), 110, 22))
    line(d, 0, fr, 0); line(fr, 0, of, 0); line(of, 0, pic, 0)
    return d


def comment(text, prect, size=10, bold=False, color="text"):
    return box(text, (1300, 20 + 22 * len(boxes) % 600, 150, 18), maxclass="comment", ins=1, outs=0,
               outlettype=[], presentation=1, presentation_rect=list(prect), fontsize=size,
               fontname="Arial Bold" if bold else "Arial", textcolor=rgba(C[color]),
               **({"fontface": 1} if bold else {}))


def panel(prect, fill="panel", border="border", rounded=6):
    return box(None, (1500, 20 + 4 * len(boxes) % 600, 60, 40), maxclass="panel", ins=1, outs=0,
               outlettype=[], presentation=1, presentation_rect=list(prect), background=1, ignoreclick=1,
               bgcolor=rgba(C[fill]), bgfillcolor_type="color", bgfillcolor_color=rgba(C[fill]),
               border=1 if border else 0, bordercolor=rgba(C[border or fill]), rounded=rounded)


def menu_style(acc="brass"):
    return dict(bgcolor=rgba(C["field"]), activebgcolor=rgba(C["field"]), textcolor=rgba(C["field_text"]),
                tricolor=rgba(C["field_text"]), bordercolor=rgba(C["border"]), focusbordercolor=rgba(C["field_text"]),
                fontsize=9.0)


IR_NAMES = {  # menu labels; the device still loads files by catalogue id (ech_ui.js LIB)
    "TP_FISHER_K10_derickgtwk_STEREO_96k": "Fisher K-10",
    "TP_BF_FenderDeluxe_MONO_44k": "Fender Deluxe", "TP_BF_Supro_MONO_44k": "Supro",
    "TP_BF_BirdVerb_FenderDeluxe_ST_44k": "Bird-Verb Deluxe", "TP_BF_BirdVerb_Supro_ST_44k": "Bird-Verb Supro",
    "TP_MT_70sStereoSpring_01": "70s Stereo Spring", "TP_MT_Spring_Webcor": "Spring + Webcor",
    "TP_MT_SilverFace_Spring_01": "Silver Face Spring",
    "SYN_LongTank2S_A": "Synthetic Long Tank", "SYN_ShortTank3S_B": "Synthetic Short Tank",
    "SYN_DarkTank2S_C": "Synthetic Dark Tank", "SYN_SplashTank1S_D": "Synthetic Splash",
    "SYN_K10Spec_2S": "Synthetic K-10 Spec",
}


def umenu_items(entries):
    """Max saves umenu items as one flat atom list with "," atoms between entries."""
    out = []
    for i, e in enumerate(entries):
        if i:
            out.append(",")
        out += e.split()
    return out


def build():
    cat = json.load(open(os.path.join(ROOT, "ir", "catalogue.json")))
    # Fisher first (default), then other third-party tanks, then synthetic
    lib = sorted((e["id"] for e in cat), key=lambda i: (0 if "FISHER" in i else 1 if i.startswith("TP_") else 2, i))
    presets = [json.load(open(p)) for p in sorted(glob.glob(os.path.join(ROOT, "presets", "*.json")))
               if not p.endswith("index.json")]

    # ---- audio graph -------------------------------------------------------------
    # No arguments: plugin~ defaults to input channels 1 and 2. (A number argument selects ONE
    # channel: "plugin~ 2" is right-input-only, which silenced the device in Live, 19 Nov.)
    pin = box("plugin~", (40, 40, 80, 22), ins=2, outs=2, outlettype=["signal", "signal"])
    front = gen_box("ech_front", 4, 2, (40, 160, 160, 22))
    conv = gen_box("ech_conv", 1, 2, (40, 240, 120, 22))
    back = gen_box("ech_back", 5, 4, (40, 320, 260, 22))
    pout = box("plugout~", (40, 420, 80, 22), ins=2, outs=0, outlettype=[])
    tin_fb = box("tapin~ 100", (340, 380, 70, 22), ins=1, outs=1, outlettype=["tapconnect"])
    tout_fb = box("tapout~ 0", (340, 410, 70, 22), ins=1, outs=1, outlettype=["signal"])
    tin_sp = box("tapin~ 100", (440, 380, 70, 22), ins=1, outs=1, outlettype=["tapconnect"])
    tout_sp = box("tapout~ 0", (440, 410, 70, 22), ins=1, outs=1, outlettype=["signal"])
    line(pin, 0, front, 0); line(pin, 1, front, 1)
    line(pin, 0, back, 0); line(pin, 1, back, 1)
    line(front, 0, back, 2); line(front, 1, conv, 0)
    line(conv, 0, back, 3); line(conv, 1, back, 4)
    line(back, 0, pout, 0); line(back, 1, pout, 1)
    line(back, 2, tin_fb, 0); line(tin_fb, 0, tout_fb, 0); line(tout_fb, 0, front, 2)
    line(back, 3, tin_sp, 0); line(tin_sp, 0, tout_sp, 0); line(tout_sp, 0, front, 3)

    # ---- IR machinery --------------------------------------------------------------
    irbuf = box("buffer~ ---echIR", (600, 160, 110, 22), ins=1, outs=2, outlettype=["float", "bang"])
    hbuf = box("buffer~ ---echH 1 2", (600, 300, 120, 22), ins=1, outs=2, outlettype=["float", "bang"])
    # Scripts are embedded (Max 9 v8.codebox), not separate .js files: Live couldn't find the
    # files on the first real test (19 Nov). Embedded code can't take "---" arguments, so the
    # per-instance buffer names arrive as a "names" message (message boxes do expand "---").
    loader_code = open(os.path.join(DEV, "code", "ech_ir_loader.js")).read()
    loader_code = loader_code.replace(
        'var irName = jsarguments[1] || "echIR";\nvar hName = jsarguments[2] || "echH";',
        'var irName = "echIR";\nvar hName = "echH";\nfunction names(a, b) { irName = String(a); hName = String(b); }')
    assert "jsarguments" not in loader_code
    ui_code = (open(os.path.join(DEV, "code", "ech_ui.js")).read().replace("__LIB__", json.dumps(lib))
               .replace("__NAMES__", json.dumps([IR_NAMES.get(i, i) for i in lib])))
    loader = box(None, (600, 240, 260, 120), maxclass="v8.codebox", ins=1, outs=2, code=loader_code,
                 varname="ech_ir_loader")
    ui = box(None, (600, 100, 260, 120), maxclass="v8.codebox", ins=1, outs=4, code=ui_code, varname="ech_ui")
    info = box("info~ ---echIR", (760, 190, 90, 22), ins=1, outs=10)
    tbb = box("t b b", (600, 190, 40, 22), ins=1, outs=2)
    msg_load = box("load", (600, 215, 40, 22), maxclass="message", ins=2, outs=1)
    pre_irsr = box("prepend irsr", (760, 215, 80, 22))
    route_l = box("route bsize nparts ir_peak have_ir", (600, 270, 220, 22), ins=1, outs=5)
    pre_bs = box("prepend bsize", (600, 340, 80, 22)); pre_np = box("prepend nparts", (690, 340, 90, 22))
    pre_pk = box("prepend ir_peak", (790, 340, 90, 22)); pre_hi = box("prepend have_ir", (890, 340, 90, 22))
    thisdev = box("live.thisdevice", (900, 40, 100, 22), ins=1, outs=3, outlettype=["bang", "int", "int"])
    bind = box("H ---echH", (900, 80, 80, 22), maxclass="message", ins=2, outs=1)
    dsp = box("dspstate~", (1000, 80, 70, 22), ins=1, outs=4, outlettype=["int", "float", "int", "int"])
    pre_sr = box("prepend sr", (1000, 110, 70, 22))
    store = box("pattr userpath", (900, 130, 160, 22), ins=2, outs=3)
    pstore = box("pattrstorage echstore @savemode 0 @autorestore 0", (900, 160, 260, 22), ins=1, outs=2,
                 parameter_enable=1,
                 saved_attribute_attributes={"valueof": {"parameter_longname": "echstore",
                                                         "parameter_shortname": "echstore",
                                                         "parameter_type": 3, "parameter_invisible": 1}})
    pre_restore = box("prepend restore", (900, 190, 100, 22))
    pre_user = box("prepend user", (1000, 250, 80, 22))
    line(ui, 0, irbuf, 0)
    line(irbuf, 1, tbb, 0); line(tbb, 1, info, 0); line(tbb, 0, msg_load, 0)
    line(info, 0, pre_irsr, 0)  # info~ left outlet = file sample rate
    line(pre_irsr, 0, loader, 0); line(msg_load, 0, loader, 0)
    line(loader, 0, route_l, 0)
    line(route_l, 0, pre_bs, 0); line(route_l, 1, pre_np, 0)
    line(route_l, 2, pre_pk, 0); line(route_l, 3, pre_hi, 0)
    line(pre_bs, 0, conv, 0); line(pre_np, 0, conv, 0)
    line(pre_pk, 0, back, 0); line(pre_hi, 0, back, 0)
    # load order (trigger fires right to left): buffer names -> H binding + sample rate -> IR choice
    t_load = box("t b b b", (900, 60, 60, 22), ins=1, outs=3)
    names = box("names ---echIR ---echH", (1080, 80, 140, 22), maxclass="message", ins=2, outs=1)
    line(thisdev, 0, t_load, 0)
    line(t_load, 2, names, 0); line(names, 0, loader, 0)
    line(t_load, 1, bind, 0); line(bind, 0, conv, 0)
    line(t_load, 1, dsp, 0); line(dsp, 1, pre_sr, 0); line(pre_sr, 0, loader, 0)
    line(ui, 3, store, 0); line(store, 0, pre_restore, 0); line(pre_restore, 0, ui, 0)

    # ---- UI ---------------------------------------------------------------------------
    # Five framed sections in one row, footer with brand / status / presets. 169 px tall.
    SX, SW, SY, SH, GAP = 6, 158, 4, 142, 6
    COLS = [7, 57, 107]                      # dial x offsets inside a section
    ROW = [22, 84]                           # dial rows (live.dial: name above, value below)
    DW = SX + 5 * SW + 4 * GAP + 6
    SPEC["W"] = DW              # = devicewidth
    panel([0, 0, DW, 169], fill="bg", border=None, rounded=0)           # fallback if images missing
    comment("Panel images not found: keep the fisher_*.png files next to the .amxd, or Freeze the device in Max.",
            (12, 60, 600, 16), size=9, color="field_text")
    boxes[-1]["box"]["background"] = 1
    box(None, (1700, 0, 120, 30), maxclass="fpic", ins=1, outs=0, outlettype=[], presentation=1,
        presentation_rect=[0, 0, DW, 169], pic=hwpanel.image_name(SPEC, "faceplate"), autofit=0, background=1)
    secs = [("CORE", ["drive", "decay", "tone", "damping", "mix", "output"]),
            ("SPRING", ["boing", "tension", "dispersion", "resonance", "movement"]),
            ("HYBRID", ["ir_level", "model_level", "blend"]),
            ("DUB", ["feedback", "fb_tone", "fb_drive", "fb_damping", "self_osc"]),
            ("ADVANCED", ["predelay", "width", "modulation"])]
    dial_ids = {}

    def wire(k, d):
        gname = GEN_NAME.get(k, k)
        src = d
        if k in PCT:
            src = box("* 0.01", (40 + 110 * len(dial_ids), 930, 50, 22), ins=2, outs=1)
            line(d, 0, src, 0)
        pre = box(f"prepend {gname}", (40 + 110 * len(dial_ids), 960, 100, 22))
        line(src, 0, pre, 0)
        if k in FRONT:
            line(pre, 0, front, 0)
        if k in BACK:
            line(pre, 0, back, 0)
        if k in LOADER:
            pre2 = box(f"prepend {k}", (40 + 110 * len(dial_ids), 990, 100, 22))
            line(src, 0, pre2, 0); line(pre2, 0, loader, 0)

    for n, (title, keys) in enumerate(secs):
        x = SX + n * (SW + GAP)
        SPEC["frames"].append((x, SY, SW, SH))
        comment(title, (x + 6, SY + 2, SW - 12, 16), size=9, bold=True,
                color="orange" if title == "DUB" else "brass")
        if title in ("HYBRID", "ADVANCED"):
            slots = [(ROW[1], c) for c in COLS]          # dials on the lower row; menus above
        else:
            slots = [(r, c) for r in ROW for c in COLS]
        for k, (ry, cx) in zip(keys, slots):
            d = dial(k, (x + cx, SY + ry, 44, 48))
            dial_ids[k] = d
            wire(k, d)
        if title == "HYBRID":
            comment("ENGINE", (x + 7, SY + 22, 80, 14), size=8, color="muted")
            mode = box(None, (300, 900, 100, 18), maxclass="live.menu", ins=1, outs=3,
                       outlettype=["", "", "float"], parameter_enable=1, presentation=1,
                       presentation_rect=[x + 7, SY + 37, SW - 14, 18], varname="Engine Mode",
                       saved_attribute_attributes={"valueof": {
                           "parameter_longname": "Engine Mode", "parameter_shortname": "Engine",
                           "parameter_type": 2, "parameter_enum": ENGINE_MODES,
                           "parameter_mmax": len(ENGINE_MODES) - 1,
                           "parameter_initial": [PARAMS["engine_mode"][2]], "parameter_initial_enable": 1}},
                       **menu_style())
            dial_ids["engine_mode"] = mode
            pre = box("prepend engine_mode", (300, 930, 120, 22))
            line(mode, 0, pre, 0); line(pre, 0, front, 0); line(pre, 0, back, 0)
        if title == "ADVANCED":
            comment("IMPULSE RESPONSE", (x + 7, SY + 18, SW - 14, 14), size=8, color="muted")
            irmenu = box(None, (500, 900, 140, 18), maxclass="live.menu", ins=1, outs=3,
                         outlettype=["", "", "float"], parameter_enable=1, presentation=1,
                         presentation_rect=[x + 7, SY + 32, SW - 14, 18], varname="IR",
                         saved_attribute_attributes={"valueof": {
                             "parameter_longname": "IR", "parameter_shortname": "IR", "parameter_type": 2,
                             "parameter_enum": [IR_NAMES.get(i, i) for i in lib] + ["User IR"], "parameter_mmax": len(lib),
                             "parameter_initial": [0], "parameter_initial_enable": 1}},
                         **menu_style())
            dial_ids["ir"] = irmenu
            pre_lib = box("prepend lib", (500, 930, 80, 22))
            line(irmenu, 0, pre_lib, 0); line(pre_lib, 0, ui, 0)
            line(ui, 1, irmenu, 0)
            drop = box(None, (650, 900, 140, 20), maxclass="live.drop", ins=1, outs=2,
                       outlettype=["", ""], presentation=1, presentation_rect=[x + 7, SY + 54, SW - 14, 22],
                       parameter_enable=0, legend="Drop your own IR (WAV)", fontsize=8.0,
                       bgcolor=rgba(C["field"]), bordercolor=rgba(C["border"]), textcolor=rgba(C["field_text"]),
                       focusbordercolor=rgba(C["brass"]))
            line(drop, 0, pre_user, 0); line(pre_user, 0, ui, 0)

    # footer: brand, IR status, presets
    FY = 151
    comment("FISHER SPRING", (8, FY, 104, 16), size=11, bold=True, color="brass_hi")
    comment("ECHOLIVITY", (116, FY + 2, 66, 14), size=8, color="muted")
    status = box("no IR loaded", (600, 380, 300, 18), maxclass="comment", ins=1, outs=0, outlettype=[],
                 presentation=1, presentation_rect=[190, FY + 2, 400, 14], fontsize=8.0, fontname="Arial",
                 textcolor=rgba(C["muted"]))
    line(loader, 1, status, 0); line(ui, 2, status, 0)
    comment("PRESET", (DW - 236, FY + 2, 44, 14), size=8, bold=True, color="muted")
    pmenu = box(None, (40, 1100, 200, 20), maxclass="umenu", ins=1, outs=3, outlettype=["int", "", ""],
                presentation=1, presentation_rect=[DW - 190, FY, 184, 17],
                items=umenu_items(["Load a preset..."] + [f"{p['number']:02d} {p['name']}" for p in presets]),
                fontsize=9.0, arrow=1,
                bgcolor=rgba(C["field"]), bgfillcolor_type="color", bgfillcolor_color=rgba(C["field"]),
                textcolor=rgba(C["text"]), elementcolor=rgba(C["brass"]), color=rgba(C["brass"]))
    sel = box("sel " + " ".join(str(i + 1) for i in range(len(presets))), (40, 1130, 300, 22),
              ins=2, outs=len(presets) + 1)              # item 0 is the "Load a preset..." header
    line(pmenu, 0, sel, 0)
    routed = [k for k in dial_ids]
    rt = box("route " + " ".join(routed), (40, 1220, 900, 22), ins=1, outs=len(routed) + 1)
    for j, k in enumerate(routed):
        line(rt, j, dial_ids[k], 0)

    def shown(k, v):                          # preset values in dial units
        return round(v * 100.0, 6) if k in PCT else v
    for j, p in enumerate(presets):
        vals = dict(p["params"])
        items = [f"{k} {shown(k, vals[k])}" for k in routed if k in vals]
        items.append(f"ir {lib.index(p['ir']) if p['ir'] in lib else 0}")
        m = box(", ".join(items), (40 + 20 * j, 1160 + 2 * j, 200, 22), maxclass="message", ins=2, outs=1)
        line(sel, j, m, 0); line(m, 0, rt, 0)

    # init on load: bind H, report SR, load selected library IR
    t_init = box("t b b", (900, 60, 40, 22), ins=1, outs=2)
    line(t_load, 0, t_init, 0)
    line(t_init, 0, dial_ids["ir"], 0)        # bang -> live.menu re-outputs current IR choice

    pat = {"patcher": {
        "fileversion": 1, "appversion": APPV, "classnamespace": "box", "rect": [40, 80, 1300, 900],
        "openrect": [0, 0, DW, 169], "openinpresentation": 1, "devicewidth": float(DW), "default_fontsize": 10.0,
        "default_fontname": "Arial", "gridsize": [8, 8], "boxes": boxes, "lines": lines,
        "description": "Echolivity - Fisher Spring Hybrid. Convolution + physical spring model + dub feedback.",
        "digest": "Hybrid spring reverb", "tags": "reverb spring dub",
        "dependency_cache": [],
        "latency": 0, "is_mpe": 0, "minimum_live_version": "12.0", "minimum_max_version": "8.6"}}
    return pat, lib


# Root patcher keys Max writes when it saves a device (taken from a device that loads in
# Live 12.4.15 / Max 9.1.5: Twin Phasor 76 S2+). Added 2026-11-18 after Twin Phasor's
# hand-built S1 patch crashed Live inside the gen~ compiler on load.
MAX_ROOT_DEFAULTS = {
    "bglocked": 0, "default_fontface": 0, "gridonopen": 1, "gridsnaponopen": 1, "objectsnaponopen": 1,
    "statusbarvisible": 2, "toolbarvisible": 1, "lefttoolbarpinned": 0, "toptoolbarpinned": 0,
    "righttoolbarpinned": 0, "bottomtoolbarpinned": 0, "toolbars_unpinned_last_save": 0, "tallnewobj": 0,
    "boxanimatetime": 200, "enablehscroll": 1, "enablevscroll": 1, "subpatcher_template": "", "style": "",
    "autosave": 0, "assistshowspatchername": 0, "external_mpe_tuning_enabled": 0, "platform_compatibility": 0,
    "openrectmode": 0,
}
BANK_ORDER = [  # Push banks, by panel section
    ("Core", ["Drive", "Decay", "Tone", "Damping", "Mix", "Output"]),
    ("Spring", ["Boing", "Tension", "Dispersion", "Resonance", "Movement"]),
    ("Hybrid", ["Engine Mode", "IR", "IR Level", "Model Level", "Hybrid Blend"]),
    ("Dub", ["Feedback", "FB Tone", "FB Drive", "FB Damping", "Self-Osc"]),
    ("Advanced", ["Pre-delay", "Width", "Modulation"]),
]
EPOCH = int(os.environ.get("SOURCE_DATE_EPOCH", "1763424000"))  # fixed: reproducible builds


def finalize(pat):
    """Bring the hand-built patch in line with what Max itself saves (see MAX_ROOT_DEFAULTS)."""
    P = pat["patcher"]
    for k, v in MAX_ROOT_DEFAULTS.items():
        P.setdefault(k, v)
    width = max((b["box"]["presentation_rect"][0] + b["box"]["presentation_rect"][2]
                 for b in P["boxes"] if b["box"].get("presentation")), default=0)
    P.setdefault("devicewidth", float(round(width + 8)))
    P["project"] = {"version": 1, "creationdate": EPOCH, "modificationdate": EPOCH,
                    "viewrect": [0.0, 0.0, 300.0, 500.0], "autoorganize": 1, "hideprojectwindow": 1,
                    "showdependencies": 1, "autolocalize": 0, "contents": {"patchers": {}}, "layout": {},
                    "searchpath": {}, "detailsvisible": 0, "amxdtype": 1633771873, "readonly": 0,
                    "devpathtype": 0, "devpath": ".", "sortmode": 0, "viewmode": 0, "includepackages": 0}
    params, visible = {}, []
    for b in P["boxes"]:
        bx = b["box"]
        v = bx.get("saved_attribute_attributes", {}).get("valueof")
        if not v:
            continue
        v.setdefault("parameter_modmode", 0)
        if v.get("parameter_type") == 2:
            v["parameter_mmax"] = len(v["parameter_enum"]) - 1
        params[bx["id"]] = [v["parameter_longname"], v["parameter_shortname"], 0]
        if not v.get("parameter_invisible"):
            visible.append(v["parameter_longname"])
    banks, used = {}, set()
    for name, members in BANK_ORDER:
        chunk = [m for m in members if m in visible]
        used |= set(chunk)
        if chunk:
            banks[str(len(banks))] = {"index": len(banks), "name": name, "parameters": chunk + ["-"] * (8 - len(chunk))}
    rest = [m for m in visible if m not in used]
    for i in range(0, len(rest), 8):
        banks[str(len(banks))] = {"index": len(banks), "name": "More", "parameters": rest[i:i + 8] + ["-"] * (8 - len(rest[i:i + 8]))}
    params["parameterbanks"] = banks
    params["inherited_shortname"] = 1
    P["parameters"] = params
    return pat


def main():
    pat, lib = build()
    finalize(pat)
    pics = sorted({b["box"]["pic"] for b in pat["patcher"]["boxes"] if b["box"]["maxclass"] == "fpic"})
    pat["patcher"]["dependency_cache"] = [{"name": n, "type": "PNG", "implicit": 1} for n in pics] + \
        [{"name": n.replace(".png", "@2x.png"), "type": "PNG", "implicit": 1} for n in pics]
    missing = [n for n in pics if not os.path.exists(os.path.join(DEV, n))]
    if missing:
        print("WARNING: panel images missing in device/ (run tools/render_panel.py):", missing)
    # scripts are embedded in the patch (v8.codebox); no loose .js files next to the device
    txt = json.dumps(pat, indent=1)
    open(os.path.join(DEV, "Echolivity.maxpat"), "w").write(txt)
    body = txt.encode("utf-8") + b"\x00"
    amxd = (b"ampf" + struct.pack("<I", 4) + b"aaaa" + b"meta" + struct.pack("<I", 4) + b"\x00\x00\x00\x00"
            + b"ptch" + struct.pack("<I", len(body)) + body)
    open(os.path.join(DEV, "Echolivity.amxd"), "wb").write(amxd)
    print("objects:", len(pat["patcher"]["boxes"]), "lines:", len(pat["patcher"]["lines"]), "amxd bytes:", len(amxd))


if __name__ == "__main__":
    main()
