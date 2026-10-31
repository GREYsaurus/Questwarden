# Questwarden project logo: a shield (the warden) holding a dotted route that ends in a waypoint arrow (the guide).
# Original artwork, drawn with Pillow; no third-party or game artwork. Editable source for docs/curseforge/logo.png.
# Copyright (C) 2026 GREYsaurus (https://github.com/GREYsaurus)
# SPDX-License-Identifier: GPL-3.0-only
# Usage: python docs/curseforge/logo.py     (writes logo.png next to this file, 400x400)
import math
import os

from PIL import Image, ImageDraw

S = 1600                     # drawn at 4x, then scaled down for smooth edges
OUT = 400
BG_TOP, BG_BOTTOM = (22, 58, 72), (9, 26, 34)
GOLD, GOLD_DARK = (232, 182, 76), (176, 126, 40)
SHIELD_FILL = (14, 40, 50)
ROUTE = (235, 226, 205)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def shield(cx, top, w, h):
    """Shield outline: flat top with rounded shoulders, sides curving to a point."""
    pts = []
    r = w * 0.12
    for k in range(0, 91, 10):  # top-left shoulder
        a = math.radians(180 + k)
        pts.append((cx - w / 2 + r + r * math.cos(a), top + r + r * math.sin(a)))
    for k in range(0, 91, 10):  # top-right shoulder
        a = math.radians(270 + k)
        pts.append((cx + w / 2 - r + r * math.cos(a), top + r + r * math.sin(a)))
    for k in range(0, 41):      # right side down to the point
        t = k / 40
        x = cx + w / 2 * (1 - t ** 3.2)
        y = top + r + (h - r) * t
        pts.append((x, y))
    for k in range(40, -1, -1):  # left side back up
        t = k / 40
        x = cx - w / 2 * (1 - t ** 3.2)
        y = top + r + (h - r) * t
        pts.append((x, y))
    return pts


img = Image.new("RGB", (S, S))
d = ImageDraw.Draw(img)
for y in range(S):
    d.line([(0, y), (S, y)], fill=lerp(BG_TOP, BG_BOTTOM, y / S))

# rounded-tile mask so the logo reads as an icon
mask = Image.new("L", (S, S), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=int(S * 0.18), fill=255)
tile = Image.new("RGBA", (S, S), (0, 0, 0, 0))
tile.paste(img, (0, 0), mask)
d = ImageDraw.Draw(tile)

cx, top, w, h = S / 2, S * 0.14, S * 0.64, S * 0.74
d.polygon(shield(cx, top, w + 90, h + 70), fill=GOLD_DARK)        # outer rim
d.polygon(shield(cx, top + 30, w + 20, h + 10), fill=GOLD)
d.polygon(shield(cx, top + 75, w - 70, h - 95), fill=SHIELD_FILL)  # inner field

# dotted route: a gentle S from lower left to upper right inside the shield
path = []
for k in range(0, 1001):
    t = k / 1000
    x = cx - w * 0.22 + w * 0.40 * t + math.sin(t * math.pi * 2.0) * w * 0.09
    y = top + h * 0.70 - h * 0.46 * t
    path.append((x, y))
# dots at even spacing along the curve, stopping just short of the arrow
dot_r, gap = S * 0.022, S * 0.062
seg = [0.0]
for i in range(1, len(path)):
    seg.append(seg[-1] + math.dist(path[i - 1], path[i]))
total, nxt, j = seg[-1], gap, 0
for i, p in enumerate(path):
    if seg[i] >= nxt and seg[i] < total - S * 0.10:
        d.ellipse([p[0] - dot_r, p[1] - dot_r, p[0] + dot_r, p[1] + dot_r], fill=ROUTE)
        nxt += gap

# start ring at the route's beginning
sx, sy = path[0]
d.ellipse([sx - 58, sy - 58, sx + 58, sy + 58], outline=GOLD, width=24)

# waypoint arrow at the end, pointing along the route
ex, ey = path[-1]
px, py = path[-80]
ang = math.atan2(ey - py, ex - px)
L, W = S * 0.17, S * 0.12
tip = (ex + math.cos(ang) * L * 0.55, ey + math.sin(ang) * L * 0.55)
back = (ex - math.cos(ang) * L * 0.45, ey - math.sin(ang) * L * 0.45)
left = (back[0] + math.cos(ang + math.pi / 2) * W / 2, back[1] + math.sin(ang + math.pi / 2) * W / 2)
right = (back[0] + math.cos(ang - math.pi / 2) * W / 2, back[1] + math.sin(ang - math.pi / 2) * W / 2)
notch = (ex - math.cos(ang) * L * 0.18, ey - math.sin(ang) * L * 0.18)
d.polygon([tip, left, notch, right], fill=GOLD)

out = tile.resize((OUT, OUT), Image.LANCZOS)
dest = os.path.join(os.path.dirname(os.path.abspath(__file__)), "logo.png")
out.save(dest, "PNG", optimize=True)
print("wrote", dest, out.size)
