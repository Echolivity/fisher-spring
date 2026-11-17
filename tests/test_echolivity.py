"""pytest entry point: every validation check is one test.
Run:  python -m pytest tests -q        (full suite ~15 min; long_duration is the slow one)
"""
import os, subprocess, sys
import pytest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
from tests.validate import CHECKS  # noqa


import glob
NEEDS_K10 = {"k10_geometry_and_ir_evidence", "k10_spectrum_match", "preset_library"}
HAVE_K10 = bool(glob.glob(os.path.join(os.path.dirname(HERE), "ir", "originals", "third_party", "fisher", "*.wav")))


@pytest.mark.parametrize("name", list(CHECKS))
def test_check(name):
    if name in NEEDS_K10 and not HAVE_K10:
        pytest.skip("needs the third-party K-10 IR (not in the repo, see ir/originals/third_party/README.md)")
    ok, evidence = CHECKS[name]()
    assert ok, evidence


@pytest.mark.parametrize("script", ["check_conv_port.py", "check_gen_port.py"])
def test_max_port(script):
    r = subprocess.run([sys.executable, os.path.join(HERE, "port_check", script)], capture_output=True, text=True)
    assert r.returncode == 0, r.stdout[-2000:] + r.stderr[-2000:]
