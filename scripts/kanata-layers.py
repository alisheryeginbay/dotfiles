#!/usr/bin/env python3
"""Draw every hold layer (layer-while-held) in config/kanata.kbd as an SVG.

Usage: scripts/kanata-layers.py [config.kbd] [out.svg]
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "config/kanata.kbd"
OUT = Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "docs/kanata-layers.svg"

# MacBook physical layout (kanata key name, width in key units)
PHYSICAL = [
    [("tab", 1.5)] + [(c, 1) for c in "qwertyuiop[]"] + [("\\", 1.5)],
    [("caps", 1.75)] + [(c, 1) for c in "asdfghjkl;'"] + [("ret", 2.25)],
    [("lsft", 2.25)] + [(c, 1) for c in "zxcvbnm,./"] + [("rsft", 2.75)],
    [("lctl", 1.5), ("lalt", 1.5), ("lmet", 1.75), ("spc", 6.5), ("rmet", 1.75), ("ralt", 2)],
]
KEY_NAMES = {
    "tab": "tab", "caps": "caps", "ret": "return", "lsft": "shift", "rsft": "shift",
    "lctl": "ctrl", "lalt": "opt", "lmet": "cmd", "spc": "space", "rmet": "cmd", "ralt": "opt",
}
HOLD_NAMES = {
    "spc": "Space", "rmet": "Right Cmd", "lmet": "Left Cmd", "ralt": "Right Option",
    "lalt": "Left Option", "caps": "Caps Lock", "tab": "Tab", "grv": "`",
}
ACTIONS = {
    "pgup": "PgUp", "pgdn": "PgDn", "home": "Home", "end": "End",
    "up": "↑", "down": "↓", "left": "←", "rght": "→",
    "bspc": "⌫", "del": "⌦", "ret": "⏎", "esc": "Esc", "tab": "⇥", "spc": "␣",
    "lctl": "⌃", "rctl": "⌃", "lalt": "⌥", "ralt": "⌥", "lmet": "⌘", "rmet": "⌘",
    "lsft": "⇧", "rsft": "⇧", "grv": "`",
}
SHIFTED = dict(zip("1234567890-=[]\\;',./`", "!@#$%^&*()_+{}|:\"<>?~"))
MODS = {"S": "⇧", "C": "⌃", "A": "⌥", "M": "⌘"}


def strip_comments(text):
    text = re.sub(r"#\|.*?\|#", "", text, flags=re.S)
    return re.sub(r";;.*", "", text)


def forms(text):
    """Top-level (...) forms as lists of tokens; nested forms stay one token."""
    out, depth, tok, cur = [], 0, "", []
    for ch in text:
        if ch == "(":
            if depth:
                tok += ch
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth:
                tok += ch
            else:
                if tok:
                    cur.append(tok)
                out.append(cur)
                tok, cur = "", []
        elif depth == 1 and ch.isspace():
            if tok:
                cur.append(tok)
            tok = ""
        elif depth:
            tok += ch
    return out


def label(action):
    if action in ("_", "XX"):
        return None
    mods = ""
    while re.match(r"^[SCAM]-.", action):
        mods += action[0]
        action = action[2:]
    if mods == "S" and action in SHIFTED:
        return SHIFTED[action]
    base = ACTIONS.get(action, action.upper() if mods else action)
    return "".join(MODS[m] for m in mods) + base


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def main():
    parsed = forms(strip_comments(SRC.read_text()))
    defsrc = next(f[1:] for f in parsed if f[0] == "defsrc")
    layers = {f[1]: f[2:] for f in parsed if f[0] == "deflayer"}
    aliases = {}
    for f in parsed:
        if f[0] == "defalias":
            aliases.update(zip(f[1::2], f[2::2]))
    base = next(iter(layers.values()))

    # (layer, physical key held to reach it), in alias order
    held = []
    for name, expr in aliases.items():
        m = re.search(r"\(layer-while-held (\S+?)\)", "(" + expr + ")")
        if m and f"@{name}" in base:
            held.append((m.group(1), defsrc[base.index(f"@{name}")]))

    U, GAP, PAD = 52, 5, 24
    W = 15 * U + PAD * 2
    KB_H = len(PHYSICAL) * U + 40
    H = PAD + len(held) * (KB_H + PAD)
    out = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" '
        'font-family="-apple-system, Helvetica, Arial, sans-serif">',
        """<style>
  .bg { fill: #ffffff; }
  .key { fill: #f3f4f6; stroke: #d1d5db; }
  .on { fill: #dbeafe; stroke: #3b82f6; }
  .hold { fill: #fde68a; stroke: #d97706; }
  .legend { fill: #9ca3af; font-size: 10px; }
  .action { fill: #111827; font-size: 17px; font-weight: 600; }
  .small { font-size: 13px; }
  .title { fill: #111827; font-size: 18px; font-weight: 700; }
  @media (prefers-color-scheme: dark) {
    .bg { fill: #0d1117; }
    .key { fill: #161b22; stroke: #30363d; }
    .on { fill: #1e3a5f; stroke: #58a6ff; }
    .hold { fill: #5c4310; stroke: #d29922; }
    .legend { fill: #7d8590; }
    .action, .title { fill: #e6edf3; }
  }
</style>""",
        f'<rect class="bg" width="{W}" height="{H}" rx="12"/>',
    ]

    y0 = PAD
    for layer, hold in held:
        keys = dict(zip(defsrc, layers[layer]))
        title = f"{layer.capitalize()} — hold {HOLD_NAMES.get(hold, hold)}"
        out.append(f'<text class="title" x="{PAD}" y="{y0 + 20}">{esc(title)}</text>')
        y = y0 + 36
        for row in PHYSICAL:
            x = PAD
            for key, w in row:
                kw = w * U - GAP
                text = label(keys.get(key, "_"))
                cls = "hold" if key == hold else "on" if text else "key"
                out.append(f'<rect class="{cls}" x="{x}" y="{y}" width="{kw}" height="{U - GAP}" rx="6"/>')
                out.append(f'<text class="legend" x="{x + 6}" y="{y + 14}">{esc(KEY_NAMES.get(key, key))}</text>')
                if text:
                    small = " small" if len(text) > 2 else ""
                    out.append(
                        f'<text class="action{small}" x="{x + kw / 2}" y="{y + 34}" '
                        f'text-anchor="middle">{esc(text)}</text>'
                    )
                x += w * U
            y += U
        y0 += KB_H + PAD

    out.append("</svg>")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(out) + "\n")


if __name__ == "__main__":
    main()
