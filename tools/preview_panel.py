"""Approximate render of the device panel from device/Echolivity.maxpat (presentation view).
Not pixel-exact Live rendering: for checking layout, colours and labels without Live.
Usage: python tools/preview_panel.py out.png"""
import json, math, os, sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, Rectangle, Arc

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
P = json.load(open(os.path.join(ROOT, "device", "Echolivity.maxpat")))["patcher"]
W, H = P["devicewidth"], 169
S = 2.0
fig = plt.figure(figsize=(W * S / 100, H * S / 100), dpi=100)
ax = fig.add_axes([0, 0, 1, 1]); ax.set_xlim(0, W); ax.set_ylim(H, 0); ax.axis("off")
col = lambda c: tuple(c[:3]) if c else (0.8, 0.8, 0.8)
FONT = dict(family="DejaVu Sans")


def fmt(v):
    u = v.get("parameter_unitstyle", 1); x = v["parameter_initial"][0]
    if u == 5: return f"{x:.0f} %"
    if u == 4: return f"{x:.1f} dB"
    if u == 2: return f"{x:.0f} ms"
    if u == 9: return v.get("parameter_units", "%.2f").replace("%%", "%") % x
    return f"{x:.2f}"


for b in sorted((b["box"] for b in P["boxes"] if b["box"].get("presentation")),
                key=lambda b: 0 if b["maxclass"] == "panel" else 1):
    x, y, w, h = b["presentation_rect"]; mc = b["maxclass"]
    if mc == "panel":
        ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle=f"round,pad=0,rounding_size={b.get('rounded', 0)}",
                                    fc=col(b["bgcolor"]), ec=col(b.get("bordercolor")) if b.get("border") else "none", lw=1))
    elif mc == "comment":
        ax.text(x + 1, y + h / 2, b.get("text", ""), color=col(b.get("textcolor")), va="center", ha="left",
                fontsize=b.get("fontsize", 10) * S * 0.72, fontweight="bold" if b.get("fontface") == 1 else "normal", **FONT)
    elif mc == "live.dial":
        v = b["saved_attribute_attributes"]["valueof"]
        lo, hi, x0 = v["parameter_mmin"], v["parameter_mmax"], v["parameter_initial"][0]
        e = v.get("parameter_exponent", 1.0)
        frac = ((x0 - lo) / (hi - lo)) ** (1 / e)
        cx, cy, r = x + w / 2, y + 23, 10.5
        ax.add_patch(Arc((cx, cy), 2 * r, 2 * r, theta1=-45, theta2=225, color=col(b["dialcolor"]), lw=2.6 * S / 2))
        start = 225 - 270 * frac
        a0 = 225 if lo >= 0 else 90
        ax.add_patch(Arc((cx, cy), 2 * r, 2 * r, theta1=min(start, a0), theta2=max(start, a0), color=col(b["activedialcolor"]), lw=2.6 * S / 2))
        ang = math.radians(start)
        ax.plot([cx, cx + r * 0.85 * math.cos(ang)], [cy, cy - r * 0.85 * math.sin(ang)], color=col(b["activeneedlecolor"]), lw=1.4)
        ax.text(cx, y + 6, v["parameter_shortname"], color=col(b["textcolor"]), ha="center", va="center", fontsize=9 * S * 0.68, **FONT)
        ax.text(cx, y + 42, fmt(v), color=col(b["textcolor"]), ha="center", va="center", fontsize=9 * S * 0.68, **FONT)
    elif mc in ("live.menu", "umenu"):
        ax.add_patch(Rectangle((x, y), w, h, fc=col(b.get("bgcolor")), ec=col(b.get("bordercolor", b.get("color"))), lw=0.8))
        if mc == "live.menu":
            v = b["saved_attribute_attributes"]["valueof"]; label = v["parameter_enum"][v["parameter_initial"][0]]
        else:
            label = " ".join(b["items"][:b["items"].index(",")])
        ax.text(x + 5, y + h / 2, label, color=col(b.get("textcolor")), va="center", fontsize=9 * S * 0.68, **FONT)
        tri = col(b.get("tricolor", b.get("elementcolor")))
        ax.plot([x + w - 11, x + w - 7, x + w - 3], [y + h / 2 - 2, y + h / 2 + 2, y + h / 2 - 2], color=tri, lw=1.2)
    elif mc == "live.drop":
        ax.add_patch(Rectangle((x, y), w, h, fc=col(b.get("bgcolor")), ec=col(b.get("bordercolor")), lw=0.8, ls=(0, (3, 2))))
        ax.text(x + w / 2, y + h / 2, b.get("legend", ""), color=col(b.get("textcolor")), ha="center", va="center", fontsize=8 * S * 0.68, **FONT)
fig.savefig(sys.argv[1] if len(sys.argv) > 1 else "panel_preview.png", facecolor=col([0.086, 0.075, 0.059]))
