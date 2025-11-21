# Setting Up App Icon from SVG

You have an `App Icon.svg` file that needs to be converted to iOS app icon PNG files. Here's how to do it:

## Option 1: Using Online Tool (Easiest)

1. **Go to:** https://www.appicon.co/ or https://www.appicon.build/
2. **Upload** your `App Icon.svg` file from `mobile/media/App Icon.svg`
3. **Download** the generated iOS app icon set
4. **Extract** the zip file
5. **Copy** all PNG files to: `ios-app/VioletVibes/Assets.xcassets/AppIcon.appiconset/`

## Option 2: Using ImageMagick (Command Line)

If you have ImageMagick installed:

```bash
cd /Users/mukaan/Classes/NYU_HCI_Fall2025/mobile/media

# Convert SVG to PNG at required sizes
convert -background none "App Icon.svg" -resize 40x40 AppIcon-20x20@2x.png
convert -background none "App Icon.svg" -resize 60x60 AppIcon-20x20@3x.png
convert -background none "App Icon.svg" -resize 58x58 AppIcon-29x29@2x.png
convert -background none "App Icon.svg" -resize 87x87 AppIcon-29x29@3x.png
convert -background none "App Icon.svg" -resize 80x80 AppIcon-40x40@2x.png
convert -background none "App Icon.svg" -resize 120x120 AppIcon-40x40@3x.png
convert -background none "App Icon.svg" -resize 120x120 AppIcon-60x60@2x.png
convert -background none "App Icon.svg" -resize 180x180 AppIcon-60x60@3x.png
convert -background none "App Icon.svg" -resize 1024x1024 AppIcon-1024x1024.png

# Move to asset catalog
mv AppIcon-*.png /Users/mukaan/Classes/NYU_HCI_Fall2025/ios-app/VioletVibes/Assets.xcassets/AppIcon.appiconset/
```

## Option 3: Using Xcode (Manual)

1. **Open your Xcode project**
2. **Navigate to:** `VioletVibes` → `Assets.xcassets` → `AppIcon`
3. **Drag and drop** your SVG file onto the AppIcon set
4. Xcode will automatically generate all required sizes

## Option 4: Using Python Script (Automated)

I'll create a script to do this automatically. Run:

```bash
cd /Users/mukaan/Classes/NYU_HCI_Fall2025/ios-app
python3 convert_icon.py
```

## Required Icon Sizes

iOS requires these specific sizes:

- **20x20@2x** = 40x40 pixels (Notification icon)
- **20x20@3x** = 60x60 pixels (Notification icon)
- **29x29@2x** = 58x58 pixels (Settings icon)
- **29x29@3x** = 87x87 pixels (Settings icon)
- **40x40@2x** = 80x80 pixels (Spotlight icon)
- **40x40@3x** = 120x120 pixels (Spotlight icon)
- **60x60@2x** = 120x120 pixels (App icon)
- **60x60@3x** = 180x180 pixels (App icon)
- **1024x1024** = 1024x1024 pixels (App Store icon)

## After Converting

1. **In Xcode:**
   - Make sure `Assets.xcassets` is added to your project
   - Verify all PNG files are in `AppIcon.appiconset/`
   - The `Contents.json` file is already created

2. **Build and run** - the app icon should appear!

## Troubleshooting

**Icon not showing:**
- Make sure all files are in `Assets.xcassets/AppIcon.appiconset/`
- Verify `Contents.json` matches the filenames
- Clean build folder: Product → Clean Build Folder (Cmd+Shift+K)
- Delete derived data and rebuild

**Icon looks blurry:**
- Make sure you're using the exact pixel sizes (not points)
- Use high-quality source SVG
- Don't scale up smaller images

