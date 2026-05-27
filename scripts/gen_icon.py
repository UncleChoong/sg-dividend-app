"""
Generate APY app icon (1024x1024 PNG) for iOS.
Uses deep navy background (#0A0E1A), cyan "APY" text (#00D9D5),
and a small green accent dot (#4ADE80).
"""

from PIL import Image, ImageDraw, ImageFont
import os

W = 1024
img = Image.new('RGB', (W, W), color='#0A0E1A')  # Deep navy, no alpha
draw = ImageDraw.Draw(img)

# Try to load a bold system font
font_paths = [
    "C:/Windows/Fonts/arialbd.ttf",
    "C:/Windows/Fonts/seguibl.ttf",  # Segoe UI Black
    "C:/Windows/Fonts/arial.ttf",
]
font = None
for p in font_paths:
    if os.path.exists(p):
        try:
            font = ImageFont.truetype(p, 380)
            break
        except Exception:
            pass

if font is None:
    font = ImageFont.load_default()

text = "APY"
# Get bounding box to measure text dimensions
bbox = draw.textbbox((0, 0), text, font=font)
text_w = bbox[2] - bbox[0]
text_h = bbox[3] - bbox[1]

# Center with slight upward offset for optical balance
x = (W - text_w) // 2 - bbox[0]
y = (W - text_h) // 2 - bbox[1] - 30

# Draw "APY" in cyan
draw.text((x, y), text, font=font, fill='#00D9D5')

# Small green accent dot at bottom-right of the wordmark
dot_size = 48
dot_x = x + text_w + 20
dot_y = y + text_h - dot_size
draw.ellipse([dot_x, dot_y, dot_x + dot_size, dot_y + dot_size], fill='#4ADE80')

# Save as PNG (no alpha, flat)
os.makedirs('assets', exist_ok=True)
img.save('assets/icon_source.png', 'PNG')
file_size = os.path.getsize('assets/icon_source.png')
print(f"Icon saved to assets/icon_source.png ({file_size} bytes)")

# Verify dimensions
img_check = Image.open('assets/icon_source.png')
print(f"Verified dimensions: {img_check.size} (expected 1024x1024)")
