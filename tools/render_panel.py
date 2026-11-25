"""Render the hardware-replica panel images into device/ (fisher_*.png, 1x and @2x).
Deterministic; needs numpy, scipy and Pillow. Re-run when the layout changes, then
run tools/build_device.py.   python3 tools/render_panel.py"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.dirname(HERE))
import build_device, hwpanel
build_device.build()
print("\n".join(hwpanel.render(build_device.SPEC, build_device.DEV)))
