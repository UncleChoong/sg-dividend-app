"""
Generate iOS app icons from the source icon (1024x1024).
This bypasses flutter_launcher_icons and directly creates the required PNG sizes
for iOS.
"""

from PIL import Image
import os

# Source icon
source_path = 'assets/icon_source.png'
icon_dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'

# iOS icon sizes as specified in the AppIcon.appiconset/Contents.json
# Format: (filename, size_in_pixels)
ios_sizes = [
    ('Icon-App-20x20@1x.png', 20),
    ('Icon-App-20x20@2x.png', 40),
    ('Icon-App-20x20@3x.png', 60),
    ('Icon-App-29x29@1x.png', 29),
    ('Icon-App-29x29@2x.png', 58),
    ('Icon-App-29x29@3x.png', 87),
    ('Icon-App-40x40@1x.png', 40),
    ('Icon-App-40x40@2x.png', 80),
    ('Icon-App-40x40@3x.png', 120),
    ('Icon-App-60x60@2x.png', 120),
    ('Icon-App-60x60@3x.png', 180),
    ('Icon-App-76x76@1x.png', 76),
    ('Icon-App-76x76@2x.png', 152),
    ('Icon-App-83.5x83.5@2x.png', 167),
    ('Icon-App-1024x1024@1x.png', 1024),
]

# Load source icon
source_img = Image.open(source_path)
print(f"Loaded source icon: {source_img.size}")

# Generate all sizes
for filename, size in ios_sizes:
    output_path = os.path.join(icon_dir, filename)
    # Resize using high-quality resampling
    resized = source_img.resize((size, size), Image.Resampling.LANCZOS)
    # Ensure RGB (no alpha)
    if resized.mode != 'RGB':
        resized = resized.convert('RGB')
    resized.save(output_path, 'PNG')
    file_size = os.path.getsize(output_path)
    print(f"Generated {filename} ({size}x{size}, {file_size} bytes)")

print(f"\nTotal icons generated: {len(ios_sizes)}")
