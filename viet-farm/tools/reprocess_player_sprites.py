# -*- coding: utf-8 -*-
"""Reprocess player sprites: crop each frame via connected components + fragment merge,
uniform resize to TARGET_CHAR_H, center horizontally and bottom-align."""

import numpy as np
from PIL import Image
import os, collections

d = r"E:\Avatar Farm\AvatarClient\viet-farm\assets\game\characters"

TARGET_CHAR_H = 240
FRAME_W, FRAME_H = 192, 256
BOTTOM_MARGIN = 12


def label_components(mask):
    h, w = mask.shape
    labeled = np.zeros_like(mask, dtype=np.int32)
    n = 0
    for y in range(h):
        for x in range(w):
            if mask[y, x] and labeled[y, x] == 0:
                n += 1
                q = collections.deque([(y, x)])
                labeled[y, x] = n
                while q:
                    cy, cx = q.popleft()
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            ny, nx = cy + dy, cx + dx
                            if (
                                0 <= ny < h
                                and 0 <= nx < w
                                and mask[ny, nx]
                                and labeled[ny, nx] == 0
                            ):
                                labeled[ny, nx] = n
                                q.append((ny, nx))
    return labeled, n


def find_characters(mask):
    labeled, n = label_components(mask)
    comps = []
    for i in range(1, n + 1):
        ys, xs = np.where(labeled == i)
        comps.append(
            {
                "px": len(xs),
                "x0": xs.min(),
                "x1": xs.max(),
                "y0": ys.min(),
                "y1": ys.max(),
            }
        )
    bodies = [c for c in comps if c["px"] > 6000]
    fragments = [c for c in comps if 200 <= c["px"] <= 6000]
    # merge each fragment into nearest body by horizontal center distance
    for f in fragments:
        fcx = (f["x0"] + f["x1"]) / 2
        best = None
        bestd = 1e9
        for b in bodies:
            bcx = (b["x0"] + b["x1"]) / 2
            dist = abs(fcx - bcx)
            if dist < bestd:
                bestd = dist
                best = b
        if best is not None and bestd < 70:
            best["x0"] = min(best["x0"], f["x0"])
            best["x1"] = max(best["x1"], f["x1"])
            best["y0"] = min(best["y0"], f["y0"])
            best["y1"] = max(best["y1"], f["y1"])
    bodies.sort(key=lambda c: c["x0"])
    return [
        (c["x0"], c["y0"], c["x1"] - c["x0"] + 1, c["y1"] - c["y0"] + 1) for c in bodies
    ]


def crop_resize(im, bbox):
    x, y, w, h = bbox
    crop = im.crop((x, y, x + w, y + h))
    scale = TARGET_CHAR_H / h
    nw = max(1, int(round(w * scale)))
    return crop.resize((nw, TARGET_CHAR_H), Image.LANCZOS)


# ---- walk ----
walk = Image.open(os.path.join(d, "walk.png")).convert("RGBA")
wa = np.array(walk)
walpha = wa[:, :, 3]
walk_out = Image.new("RGBA", (FRAME_W * 8, FRAME_H * 4), (0, 0, 0, 0))
for row in range(4):
    band = walpha[row * 256 : (row + 1) * 256, :] > 20
    boxes = find_characters(band)
    print(f"walk row {row}: {len(boxes)} characters")
    for col, (x, y, w, h) in enumerate(boxes[:8]):
        spr = crop_resize(walk, (x, row * 256 + y, w, h))
        nw, nh = spr.size
        offx = (FRAME_W - nw) // 2
        offy = FRAME_H - BOTTOM_MARGIN - nh
        walk_out.paste(spr, (col * FRAME_W + offx, row * FRAME_H + offy), spr)
walk_out.save(os.path.join(d, "walk_clean.png"))
print("saved walk_clean.png", walk_out.size)

# ---- idle (key + crop) ----
idle = Image.open(os.path.join(d, "idle.png")).convert("RGBA")
ia = np.array(idle).astype(int)
irgb = ia[:, :, :3]
igray = irgb.mean(axis=2)
isat = irgb.max(axis=2) - irgb.min(axis=2)
background = (isat < 15) & (igray >= 32) & (igray <= 118)
ialpha = ia[:, :, 3].copy()
ialpha[background] = 0
keyed = ia.copy()
keyed[:, :, 3] = ialpha
keyed_im = Image.fromarray(keyed.astype(np.uint8))

idle_boxes = {
    "front": (449, 481, 191, 384),
    "back": (448, 26, 192, 378),
    "left": (115, 392, 187, 374),
    "right": (794, 392, 184, 374),
}
idle_out = Image.new("RGBA", (FRAME_W * 4, FRAME_H), (0, 0, 0, 0))
for i, name in enumerate(["front", "back", "left", "right"]):
    spr = crop_resize(keyed_im, idle_boxes[name])
    nw, nh = spr.size
    offx = (FRAME_W - nw) // 2
    offy = FRAME_H - BOTTOM_MARGIN - nh
    idle_out.paste(spr, (i * FRAME_W + offx, offy), spr)
idle_out.save(os.path.join(d, "idle_grid.png"))
print("saved idle_grid.png", idle_out.size)
