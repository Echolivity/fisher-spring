"""Tiny GenExpr -> Python translator for the subset used in device/gen/*.genexpr.

Purpose: run the *actual* GenExpr source of the Max device sample-by-sample in
Python, so the port can be compared against the reference engine without Max.
Supported: Param, History, Data, Delay(read/write, cubic/linear), Buffer (as Data),
functions, if/else if/else, for, while, ternary (one level), && || !, peek/poke.
Not a general GenExpr implementation.
"""
import math
import re
import numpy as np

BUILTINS = """
import math
def _clamp(x, lo, hi): return lo if x < lo else (hi if x > hi else x)
def _fixdenorm(x): return 0.0 if abs(x) < 1e-30 else x
def _floor(x): return float(math.floor(x))
"""


class GenDelay:
    def __init__(self, n):
        self.buf = np.zeros(int(n) + 4)
        self.w = 0          # index of last written sample
        self.wrote = False  # written already in this tick? (gen~: write-before-read allows delay 0)

    def read(self, t, interp="linear"):
        n = len(self.buf)
        rp = self.w - t if self.wrote else self.w - (t - 1)
        i = math.floor(rp); f = rp - i
        if interp == "cubic":
            xm1, x0, x1, x2 = (self.buf[(i - 1) % n], self.buf[i % n], self.buf[(i + 1) % n], self.buf[(i + 2) % n])
            c1 = 0.5 * (x1 - xm1)
            c2 = xm1 - 2.5 * x0 + 2.0 * x1 - 0.5 * x2
            c3 = 0.5 * (x2 - xm1) + 1.5 * (x0 - x1)
            return ((c3 * f + c2) * f + c1) * f + x0
        return self.buf[i % n] * (1 - f) + self.buf[(i + 1) % n] * f

    def write(self, x):
        self.wrote = True
        self.w = (self.w + 1) % len(self.buf)
        self.buf[self.w] = x


class GenData:
    def __init__(self, n, ch=1):
        self.a = np.zeros((int(n), int(ch)))

    def peek(self, i, ch=0):
        i = int(i)
        return float(self.a[i, int(ch)]) if 0 <= i < self.a.shape[0] else 0.0

    def poke(self, v, i, ch=0):
        i = int(i)
        if 0 <= i < self.a.shape[0]:
            self.a[i, int(ch)] = v


def _split_statements(src):
    src = re.sub(r"//[^\n]*", "", src)
    out, buf, depth = [], "", 0
    for chx in src:
        if chx == "(":
            depth += 1
        elif chx == ")":
            depth -= 1
        if chx in "{};" and depth == 0:
            if buf.strip():
                out.append(buf.strip())
            if chx in "{}":
                out.append(chx)
            buf = ""
        else:
            buf += chx
    if buf.strip():
        out.append(buf.strip())
    return out


def _paren_ternaries(e):
    """Recursively rewrite 'a ? b : c' found inside parentheses."""
    out, i = "", 0
    while i < len(e):
        if e[i] == "(":
            depth, j = 1, i + 1
            while depth:
                depth += {"(": 1, ")": -1}.get(e[j], 0); j += 1
            inner = _paren_ternaries(e[i + 1:j - 1])
            parts, depth2, cur = [], 0, ""
            for chx in inner:
                if chx == "(":
                    depth2 += 1
                elif chx == ")":
                    depth2 -= 1
                if chx == "," and depth2 == 0:
                    parts.append(cur); cur = ""
                else:
                    cur += chx
            parts.append(cur)
            out += "(" + ",".join(_ternary(pp) if "?" in pp else pp for pp in parts) + ")"
            i = j
        else:
            out += e[i]; i += 1
    return out


def _ternary(e):
    depth, q, col = 0, -1, -1
    for i, chx in enumerate(e):
        if chx == "(":
            depth += 1
        elif chx == ")":
            depth -= 1
        elif chx == "?" and depth == 0 and q < 0:
            q = i
        elif chx == ":" and depth == 0 and q >= 0 and col < 0:
            col = i
    if q < 0:
        return e
    return f"(({e[q + 1:col]}) if ({e[:q]}) else ({_ternary(e[col + 1:])}))"


def _expr(e):
    e = e.replace("&&", " and ").replace("||", " or ")
    e = re.sub(r"!(?!=)", " not ", e)
    e = re.sub(r"\bclamp\(", "_clamp(", e)
    e = re.sub(r"\bfixdenorm\(", "_fixdenorm(", e)
    e = re.sub(r"\bfloor\(", "_floor(", e)
    for f in ["exp", "tanh", "sin", "cos", "sqrt", "log"]:
        e = re.sub(rf"(?<![\w.]){f}\(", f"math.{f}(", e)
    e = re.sub(r"(?<![\w.])pow\(", "math.pow(", e)
    e = re.sub(r"\bnoise\(\)", "self._noise()", e)
    e = re.sub(r"(?<![\w.])peek\((\w+),", r"\1.peek(", e)
    e = re.sub(r"(?<![\w.])poke\((\w+),", r"\1.poke(", e)
    e = _paren_ternaries(e)
    e = re.sub(r"\btwopi\b", "6.283185307179586", e)
    e = re.sub(r"(?<![\w.])pi\b", "3.141592653589793", e)
    e = re.sub(r"\bsamplerate\b", "self.samplerate", e)
    e = re.sub(r'interp="(\w+)"', r'interp="\1"', e)
    # one-level ternary  a ? b : c   (outside parentheses)
    depth, q, col = 0, -1, -1
    for i, chx in enumerate(e):
        if chx == "(":
            depth += 1
        elif chx == ")":
            depth -= 1
        elif chx == "?" and depth == 0 and q < 0:
            q = i
        elif chx == ":" and depth == 0 and q >= 0 and col < 0:
            col = i
    if q >= 0:
        return f"(({_expr(e[q + 1:col])}) if ({_expr(e[:q])}) else ({_expr(e[col + 1:])}))"
    # ternaries nested inside parentheses
    def sub_paren(m):
        return m.group(0)
    return e


def translate(src, name="Gen"):
    fnames = re.findall(r"^(\w+)\s*\([\w\s,]*\)\s*\{", src, flags=re.M)
    for f in fnames:
        src = re.sub(rf"(?<![\w.]){f}\(", f"self.{f}(", src)
        src = src.replace(f"\nself.{f}(", f"\n{f}(")      # keep the definition line
    stmts = _split_statements(src)
    decls, funcs, body = [], [], []
    params, objs = {}, []
    i = 0
    state_names = []
    lines = None
    indent = 0
    cur = body
    in_func = False
    pending_for = []
    while i < len(stmts):
        s = stmts[i]
        m = re.match(r"Param\s+(\w+)\(([^,)]+)", s)
        if m:
            params[m.group(1)] = float(m.group(2)); i += 1; continue
        m = re.match(r"History\s+(\w+)\(([^)]*)\)", s)
        if m:
            state_names.append(m.group(1)); decls.append(f"self.{m.group(1)} = {m.group(2) or 0}.0"); i += 1; continue
        m = re.match(r"Data\s+(\w+)\(([^)]*)\)", s)
        if m:
            decls.append(f"self.{m.group(1)} = GenData({m.group(2)})"); objs.append(m.group(1)); i += 1; continue
        m = re.match(r"Delay\s+(\w+)\(([^)]*)\)", s)
        if m:
            decls.append(f"self.{m.group(1)} = GenDelay({m.group(2)})"); objs.append(m.group(1)); i += 1; continue
        m = re.match(r'Buffer\s+(\w+)\(', s)
        if m:
            decls.append(f"self.{m.group(1)} = GenData(1, 2)"); objs.append(m.group(1)); i += 1; continue
        m = re.match(r"(\w+)\s*\(([\w\s,]*)\)$", s)
        if m and m.group(1) in fnames and i + 1 < len(stmts) and stmts[i + 1] == "{" and not in_func and indent == 0:
            args = ", ".join(["self"] + [a.strip() for a in m.group(2).split(",") if a.strip()])
            funcs.append(f"    def {m.group(1)}({args}):")
            lines = funcs; in_func = True; indent = 2; i += 2; continue
        target = funcs if in_func else body
        pad = "    " * (indent if in_func else indent + 2)
        if s == "{":
            i += 1; continue
        if s == "}":
            if pending_for and pending_for[-1][0] == indent:
                _, inc = pending_for.pop()
                target.append(pad + inc)
            indent -= 1
            if in_func and indent == 1:
                in_func = False; indent = 0
            i += 1; continue
        m = re.match(r"for\s*\((.*?);(.*?);(.*)\)$", s)
        if m:
            init, cond, inc = m.group(1).strip(), m.group(2).strip(), m.group(3).strip()
            target.append(pad + _stmt(init))
            target.append(pad + f"while {_expr(cond)}:")
            indent += 1
            pending_for.append((indent, _stmt(inc)))
            i += 1; continue
        m = re.match(r"(\}\s*)?else\s+if\s*\((.*)\)$", s)
        if m:
            target.append(pad + f"elif {_expr(m.group(2))}:"); indent += 1; i += 1; continue
        if s == "else":
            target.append(pad + "else:"); indent += 1; i += 1; continue
        m = re.match(r"if\s*\((.*)\)$", s)
        if m:
            target.append(pad + f"if {_expr(m.group(1))}:"); indent += 1; i += 1; continue
        m = re.match(r"while\s*\((.*)\)$", s)
        if m:
            target.append(pad + f"while {_expr(m.group(1))}:"); indent += 1; i += 1; continue
        if s.startswith("return"):
            target.append(pad + "return " + _expr(s[6:].strip())); i += 1; continue
        target.append(pad + _stmt(s))
        i += 1
    # "} else" splits: handle by our splitter producing '}', 'else' -> fine
    code = BUILTINS + f"\nclass {name}:\n    def __init__(self, samplerate, rng):\n        self.samplerate = samplerate\n        self._rng = rng\n"
    code += "".join(f"        {d}\n" for d in decls)
    code += "".join(f"        self.{k} = {v}\n" for k, v in params.items())
    code += "    def _noise(self):\n        return self._rng.uniform(-1, 1)\n"
    code += "\n".join(funcs) + "\n"
    code += "    def tick(self, in1=0.0, in2=0.0, in3=0.0, in4=0.0, in5=0.0):\n"
    code += "".join(f"        {n} = self.{n}\n" for n in state_names)
    code += "".join(f"        {n} = self.{n}\n" for n in objs)
    code += "".join(f"        self.{n}.wrote = False\n" for n in objs if any(d == f"self.{n} = GenDelay" or d.startswith(f"self.{n} = GenDelay") for d in decls))
    code += "".join(f"        {k} = self.{k}\n" for k in params)
    code += "        out1 = out2 = out3 = out4 = 0.0\n"
    code += "\n".join(body) + "\n"
    code += "".join(f"        self.{n} = {n}\n" for n in state_names)
    code += "        return out1, out2, out3, out4\n"
    # functions need access to objects as self.<name>
    for o in objs:
        code = re.sub(rf"(?<=\n)(        (?:    )+.*?)\b{o}\.", lambda mm: mm.group(0), code)
    return code, params


def _stmt(s):
    m = re.match(r"^([\w, ]+?)\s*([+\-*/]?=)\s*(.*)$", s)
    if m and "==" not in s.split("=")[0] + "=" and not s.startswith("("):
        lhs, op, rhs = m.group(1), m.group(2), m.group(3)
        if "(" not in lhs:
            return f"{lhs} {op} {_expr(rhs)}"
    return _expr(s)


def load(path, name):
    src = open(path).read()
    code, params = translate(src, name)
    ns = {"GenData": GenData, "GenDelay": GenDelay, "np": np}
    # functions reference Data objects by bare name: expose them through a module-level proxy
    exec(code, ns)
    return ns[name], code, params
