"""Find library IRs by id (searches ir/originals recursively) and apply the
catalogue's 'processing' directives (same as the processed variants)."""
import glob, json, os
import numpy as np
import soundfile as sf

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def path(ir_id):
    hits = glob.glob(os.path.join(ROOT, "ir", "originals", "**", ir_id + ".wav"), recursive=True)
    if not hits:
        raise FileNotFoundError(ir_id)
    return hits[0]


def apply_processing(x, sr, proc):
    x = np.array(x, dtype=np.float64, copy=True)
    ms = (proc or {}).get("remove_direct_ms")
    if ms:
        n = int(ms * 1e-3 * sr)
        f = max(1, int(0.0005 * sr))
        x[:n] = 0.0
        x[n:n + f] *= np.linspace(0, 1, f)[:, None]
    return x


def load(ir_id, processed=True):
    p = path(ir_id)
    x, sr = sf.read(p, always_2d=True)
    if processed:
        meta = json.load(open(p[:-4] + ".json"))
        x = apply_processing(x, sr, meta.get("processing"))
    return x, sr
