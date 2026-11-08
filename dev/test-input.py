#!/usr/bin/env python3
"""A virtual test mouse and keyboard for checking the shell (not installed).

Run:      HYPRLAND_INSTANCE_SIGNATURE=… python3 dev/test-input.py
Commands: dev/m click X Y [right] | move X Y | drag X1 Y1 X2 Y2 | type word|ENTER|ESC|TAB|DOWN…
"""
import os, subprocess, time
from evdev import UInput, ecodes as e

FIFO = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "unia-test-input.fifo")
if os.path.exists(FIFO) and not os.path.stat.S_ISFIFO(os.stat(FIFO).st_mode):
    os.remove(FIFO)
if not os.path.exists(FIFO):
    os.mkfifo(FIFO)
KEYS = [getattr(e, "KEY_" + c) for c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ"] + [
    e.KEY_ENTER, e.KEY_ESC, e.KEY_BACKSPACE, e.KEY_DOWN, e.KEY_UP, e.KEY_LEFT, e.KEY_RIGHT,
    e.KEY_SPACE, e.KEY_TAB, e.KEY_LEFTSHIFT, e.KEY_LEFTMETA]
kb = UInput({e.EV_KEY: KEYS}, name="unia-test-kbd")
ui = UInput({e.EV_KEY: [e.BTN_LEFT, e.BTN_RIGHT, e.BTN_MIDDLE], e.EV_REL: [e.REL_X, e.REL_Y, e.REL_WHEEL]}, name="unia-test-mouse")


def warp(x, y):
    subprocess.run(["hyprctl", "dispatch", f"hl.dsp.cursor.move({{ x = {int(x)}, y = {int(y)} }})"], capture_output=True)


def nudge():
    for d in (1, -1):
        ui.write(e.EV_REL, e.REL_X, d); ui.syn(); time.sleep(0.04)


def key(k, mods=()):
    for m in mods: kb.write(e.EV_KEY, m, 1)
    kb.write(e.EV_KEY, k, 1); kb.syn(); time.sleep(0.03)
    kb.write(e.EV_KEY, k, 0)
    for m in mods: kb.write(e.EV_KEY, m, 0)
    kb.syn(); time.sleep(0.04)


while True:
    with open(FIFO) as f:
        for line in f:
            p = line.split()
            if not p:
                continue
            if p[0] == "type":                       # type word | type TAB SHIFT+TAB ENTER
                for tok in p[1:]:
                    mods = []
                    if tok.startswith("SHIFT+"): mods, tok = [e.KEY_LEFTSHIFT], tok[6:]
                    if tok.startswith("SUPER+"): mods, tok = [e.KEY_LEFTMETA], tok[6:]
                    if len(tok) > 1 and hasattr(e, "KEY_" + tok): key(getattr(e, "KEY_" + tok), mods)
                    else:
                        for ch in tok: key(getattr(e, "KEY_" + ch.upper()), mods)
                continue
            warp(p[1], p[2]); time.sleep(0.05); nudge(); time.sleep(0.1)
            if p[0] == "click":
                b = {"right": e.BTN_RIGHT, "middle": e.BTN_MIDDLE}.get(p[3] if len(p) > 3 else "", e.BTN_LEFT)
                ui.write(e.EV_KEY, b, 1); ui.syn(); time.sleep(0.08); ui.write(e.EV_KEY, b, 0); ui.syn()
            elif p[0] == "drag":
                ui.write(e.EV_KEY, e.BTN_LEFT, 1); ui.syn(); time.sleep(0.15)
                x1, y1, x2, y2 = map(int, p[1:5])
                hold = float(p[5]) if len(p) > 5 else 0.2     # how long to hold at the end (for autoscroll)
                for i in range(1, 21):
                    warp(x1 + (x2 - x1) * i // 20, y1 + (y2 - y1) * i // 20)
                    ui.write(e.EV_REL, e.REL_X, 1); ui.syn(); ui.write(e.EV_REL, e.REL_X, -1); ui.syn(); time.sleep(0.03)
                time.sleep(hold); ui.write(e.EV_KEY, e.BTN_LEFT, 0); ui.syn()
