#!/usr/bin/env python3
"""Optional: put a 'CTGP' badge on the game's own icon (256x256 JPEG). Needs Pillow."""
import sys
from PIL import Image, ImageDraw, ImageFont

src, dst = sys.argv[1], sys.argv[2]
S, BAND = 256, 58
img = Image.open(src).convert("RGBA").resize((S, S))
overlay = Image.new("RGBA", (S, S), (0, 0, 0, 0))
draw = ImageDraw.Draw(overlay)
y0 = S - BAND
draw.rectangle([0, y0, S, S], fill=(60, 48, 92, 235))
stripes = [(61, 199, 106), (247, 207, 64), (245, 146, 52), (232, 72, 72), (214, 76, 190), (72, 128, 232)]
width = S / len(stripes)
for i, color in enumerate(stripes):
    draw.rectangle([int(i * width), y0 - 5, int((i + 1) * width), y0 - 1], fill=color + (255,))
try:
    font = ImageFont.truetype("DejaVuSans-Bold.ttf", 42)
except OSError:
    font = ImageFont.load_default()
box = draw.textbbox((0, 0), "CTGP", font=font)
x = (S - (box[2] - box[0])) // 2 - box[0]
y = y0 + (BAND - (box[3] - box[1])) // 2 - box[1]
draw.text((x, y), "CTGP", font=font, fill=(255, 255, 255, 255))
Image.alpha_composite(img, overlay).convert("RGB").save(dst, "JPEG", quality=92)
print(dst)
