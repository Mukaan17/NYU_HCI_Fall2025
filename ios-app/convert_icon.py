#!/usr/bin/env python3
"""
Convert App Icon.svg to iOS app icon PNG files
Requires: pip install cairosvg pillow
"""

import os
import sys
from pathlib import Path

try:
    import cairosvg
    from PIL import Image
except ImportError:
    print("Error: Missing required packages")
    print("Install with: pip3 install cairosvg pillow")
    sys.exit(1)

# Paths
script_dir = Path(__file__).parent
svg_path = script_dir.parent / "mobile" / "media" / "App Icon.svg"
output_dir = script_dir / "VioletVibes" / "Assets.xcassets" / "AppIcon.appiconset"

# Required sizes (filename: (width, height))
sizes = {
    "AppIcon-20x20@2x.png": (40, 40),
    "AppIcon-20x20@3x.png": (60, 60),
    "AppIcon-29x29@2x.png": (58, 58),
    "AppIcon-29x29@3x.png": (87, 87),
    "AppIcon-40x40@2x.png": (80, 80),
    "AppIcon-40x40@3x.png": (120, 120),
    "AppIcon-60x60@2x.png": (120, 120),
    "AppIcon-60x60@3x.png": (180, 180),
    "AppIcon-1024x1024.png": (1024, 1024),
}

def convert_svg_to_png(svg_path, output_path, size):
    """Convert SVG to PNG at specified size"""
    try:
        # Convert SVG to PNG using cairosvg
        png_data = cairosvg.svg2png(
            url=str(svg_path),
            output_width=size[0],
            output_height=size[1]
        )
        
        # Save PNG
        with open(output_path, 'wb') as f:
            f.write(png_data)
        
        print(f"✓ Created {output_path.name} ({size[0]}x{size[1]})")
        return True
    except Exception as e:
        print(f"✗ Error creating {output_path.name}: {e}")
        return False

def main():
    # Check if SVG exists
    if not svg_path.exists():
        print(f"Error: SVG file not found at {svg_path}")
        print("Looking for: mobile/media/App Icon.svg")
        sys.exit(1)
    
    # Create output directory
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"Converting {svg_path.name} to iOS app icons...")
    print(f"Output directory: {output_dir}\n")
    
    # Convert each size
    success_count = 0
    for filename, size in sizes.items():
        output_path = output_dir / filename
        if convert_svg_to_png(svg_path, output_path, size):
            success_count += 1
    
    print(f"\n✓ Successfully created {success_count}/{len(sizes)} icon files")
    print(f"\nNext steps:")
    print(f"1. Open your Xcode project")
    print(f"2. Make sure Assets.xcassets is added to the project")
    print(f"3. Verify AppIcon.appiconset contains all PNG files")
    print(f"4. Clean build folder (Cmd+Shift+K) and rebuild")

if __name__ == "__main__":
    main()

