from PIL import Image
from collections import deque

WHITE_MIN = 232

SRC2 = "2.png"
SRC_LR = "walk_left_or_right.png"

DIRS = {
    "front": (
        "2.png",
        [
            (66, 19, 183, 243),
            (245, 19, 364, 242),
            (435, 19, 549, 242),
            (619, 19, 732, 242),
            (802, 19, 914, 243),
            (985, 19, 1101, 243),
            (1170, 19, 1286, 243),
            (1354, 19, 1469, 242),
        ],
    ),
    "back": (
        "2.png",
        [
            (66, 266, 183, 497),
            (243, 267, 366, 499),
            (434, 266, 552, 499),
            (616, 267, 733, 499),
            (799, 266, 916, 497),
            (985, 266, 1102, 498),
            (1170, 266, 1286, 499),
            (1353, 266, 1470, 498),
        ],
    ),
    "left": (
        "lr",
        [
            (31, 557, 239, 891),
            (309, 559, 480, 895),
            (563, 560, 717, 893),
            (793, 560, 1006, 899),
            (1077, 558, 1244, 897),
            (1321, 559, 1476, 893),
        ],
    ),
    "right": (
        "lr",
        [
            (40, 100, 239, 431),
            (303, 103, 479, 431),
            (575, 100, 725, 431),
            (799, 106, 1002, 434),
            (1091, 106, 1246, 431),
            (1345, 102, 1498, 435),
        ],
    ),
}

imgs = {
    "2.png": Image.open(SRC2).convert("RGBA"),
    "lr": Image.open(SRC_LR).convert("RGBA"),
}


def remove_halo(img, x0, y0, x1, y1):
    crop = img.crop((x0, y0, x1 + 1, y1 + 1)).copy()
    px = crop.load()
    w, h = crop.size
    white = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            white[y][x] = a > 10 and min(r, g, b) >= WHITE_MIN
    seen = [[False] * w for _ in range(h)]
    dq = deque()
    for x in range(w):
        for y in (0, h - 1):
            if white[y][x] and not seen[y][x]:
                seen[y][x] = True
                dq.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if white[y][x] and not seen[y][x]:
                seen[y][x] = True
                dq.append((x, y))
    while dq:
        x, y = dq.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and white[ny][nx] and not seen[ny][nx]:
                seen[ny][nx] = True
                dq.append((nx, ny))
    for y in range(h):
        for x in range(w):
            if seen[y][x]:
                px[x, y] = (px[x, y][0], px[x, y][1], px[x, y][2], 0)
    return crop


cells = {}
for d, (src, boxes) in DIRS.items():
    cells[d] = []
    for b in boxes:
        crop = remove_halo(imgs[src], *b)
        bb = crop.getbbox()
        cells[d].append((crop, bb))

TARGET_H = max(bb[3] - bb[1] for row in cells.values() for _, bb in row)
print("target char height:", TARGET_H)

scaled = {}
for d, frames in cells.items():
    scaled[d] = []
    for crop, bb in frames:
        s = crop.crop(bb)
        sw, sh = s.size
        ns = int(round(sw * TARGET_H / sh))
        s = s.resize((ns, TARGET_H), Image.NEAREST)
        scaled[d].append(s)

W = max(s.width for row in scaled.values() for s in row)
H = TARGET_H
print("canvas W x H:", W, "x", H)

ORDER = ["front", "back", "left", "right"]
NC = max(len(row) for row in scaled.values())
sheet = Image.new("RGBA", (W * NC, H * 4), (0, 0, 0, 0))


def comx(crop):
    px = crop.load()
    w, h = crop.size
    sx = 0
    n = 0
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 10:
                sx += x
                n += 1
    return sx / n if n else w / 2


for ri, d in enumerate(ORDER):
    for ci, s in enumerate(scaled[d]):
        sw, sh = s.size
        cx = comx(s)
        ox = ci * W + (W - sw) // 2 + int(round((sw / 2 - cx)))
        oy = ri * H + H - sh
        sheet.paste(s, (ox, oy), s)
sheet.save("player_walk_sheet.png")
print("saved player_walk_sheet.png", sheet.size)
print("frame counts:", {d: len(v) for d, v in cells.items()})
