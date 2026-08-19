# -*- coding: utf-8 -*-
"""Export tat ca .aseprite -> PNG sheet (horizontal) + JSON vao viet-farm/assets/art/"""

import os, re, json, subprocess, unicodedata, sys

ASE = r"C:\Aseprite\Aseprite.exe"
SRC = r"E:\Avatar Farm\AvatarResource\aseprite_projects"
DST = r"E:\Avatar Farm\AvatarClient\viet-farm\assets\art"


def sanitize(s):
    s = s.replace("đ", "d").replace("Đ", "D")
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = re.sub(r"[^A-Za-z0-9_.-]+", "_", s).strip("_")
    return s.lower()


mapping = {}
count = ok = 0
for root, dirs, files in os.walk(SRC):
    dirs[:] = [d for d in dirs if not d.startswith(".")]
    for f in files:
        if not f.lower().endswith(".aseprite"):
            continue
        count += 1
        src = os.path.join(root, f)
        rel = os.path.relpath(root, SRC)
        outdir = os.path.join(DST, sanitize(rel)) if rel != "." else DST
        os.makedirs(outdir, exist_ok=True)
        base = sanitize(os.path.splitext(f)[0]) or "sprite"
        png = os.path.join(outdir, base + ".png")
        js = os.path.join(outdir, base + ".json")
        r = subprocess.run(
            [
                ASE,
                "-b",
                src,
                "--sheet",
                png,
                "--data",
                js,
                "--sheet-type",
                "horizontal",
                "--list-tags",
            ],
            capture_output=True,
            text=True,
        )
        if os.path.exists(png):
            ok += 1
            mapping[os.path.relpath(src, SRC)] = os.path.relpath(png, DST)
        else:
            print("FAIL:", src, r.stderr[-200:] if r.stderr else "")

with open(os.path.join(DST, "_mapping.json"), "w", encoding="utf-8") as fp:
    json.dump(mapping, fp, ensure_ascii=False, indent=1)
print(f"Exported {ok}/{count}")
