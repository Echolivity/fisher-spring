"""reports/technical_validation.json + port checks -> reports/TECHNICAL_VALIDATION.md"""
import json, os, datetime, platform

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
R = os.path.join(ROOT, "reports")


def fmt(v, depth=0):
    if isinstance(v, dict):
        if all(not isinstance(x, (dict, list)) for x in v.values()) and len(v) <= 8:
            return ", ".join(f"{k}: {x}" for k, x in v.items())
        return "\n".join(f"{'  ' * depth}- **{k}**: {fmt(x, depth + 1)}" if not isinstance(x, dict) or len(x) <= 8 and all(not isinstance(y, (dict, list)) for y in x.values())
                         else f"{'  ' * depth}- **{k}**:\n{fmt(x, depth + 1)}" for k, x in v.items())
    if isinstance(v, float):
        return f"{v:.4g}"
    return str(v)


def main():
    tv = json.load(open(os.path.join(R, "technical_validation.json")))
    ports = {}
    for n in ("port_check_conv", "port_check_gen"):
        p = os.path.join(R, n + ".json")
        ports[n] = json.load(open(p)) if os.path.exists(p) else {"passed": False, "results": "not run"}
    n_pass = sum(v["passed"] for v in tv.values()) + sum(v["passed"] for v in ports.values())
    n_all = len(tv) + len(ports)
    out = ["# Technical validation report", "",
           f"Generated {datetime.date.today().isoformat()} by `tools/make_report.py` on {platform.machine()} "
           f"/ Python {platform.python_version()}.", "",
           f"**{n_pass} of {n_all} checks passed.**", "",
           "## What this covers, and what it doesn't", "",
           "- **Covered:** the reference DSP engine (`reference/engine.py`), the IR library audit, presets, "
           "and the Max port: the device's own GenExpr and JavaScript, run outside Max and compared "
           "sample-by-sample with the reference engine.",
           "- **Not covered:** anything that needs Max or Live running: whether gen~ compiles, real CPU use, "
           "the UI, automation recorded in Live, preset recall in a Live Set, multiple instances, and real "
           "sample-rate switching. Those stay *Open* in the development register until `docs/QA_PROTOCOL.md` "
           "has been run in Live.", "",
           "Reproduce: `python tests/validate.py && python tests/port_check/check_conv_port.py && "
           "python tests/port_check/check_gen_port.py && python tools/make_report.py`", "",
           "| Check | Result | Time |", "|---|---|---|"]
    for k, v in tv.items():
        out.append(f"| {k} | {'PASS' if v['passed'] else '**FAIL**'} | {v['seconds']} s |")
    for k, v in ports.items():
        out.append(f"| {k} (Max port) | {'PASS' if v['passed'] else '**FAIL**'} | - |")
    out += ["", "## Evidence", ""]
    for k, v in tv.items():
        out += [f"### {k} - {'PASS' if v['passed'] else 'FAIL'}", ""]
        if v.get("doc"):
            out += [v["doc"], ""]
        out += [fmt(v["evidence"]), ""]
    for k, v in ports.items():
        out += [f"### {k} - {'PASS' if v['passed'] else 'FAIL'}", "", fmt(v["results"]), ""]
    open(os.path.join(R, "TECHNICAL_VALIDATION.md"), "w").write("\n".join(out) + "\n")
    print(f"{n_pass}/{n_all}")


if __name__ == "__main__":
    main()
