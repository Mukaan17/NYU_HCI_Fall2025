# How to Fix Config.plist Not Found in Bundle

## Quick Fix: Use Environment Variables (Immediate Solution)

1. **In Xcode:**
   - Product → Scheme → Edit Scheme (or press `Cmd + <`)
   - Select "Run" in the left sidebar
   - Go to "Arguments" tab
   - Under "Environment Variables", click the "+" button
   - Add:
     - **Name:** `OPENWEATHER_KEY`
     - **Value:** `dbb5ec5c928fa184644c1d33f2d9b396` (your actual API key)
   - Click "Close"

2. **Clean and rebuild:**
   - Product → Clean Build Folder (`Cmd + Shift + K`)
   - Product → Build (`Cmd + B`)
   - Run the app

This will work immediately!

---

## Permanent Fix: Add Config.plist to Bundle

### Method 1: Add to Copy Bundle Resources (Recommended)

1. **Select your project** (blue icon at top of Project Navigator)
2. **Select the "VioletVibes" target**
3. **Click "Build Phases" tab**
4. **Expand "Copy Bundle Resources"**
5. **Click the "+" button** at the bottom
6. **Find and select `Config.plist`**
7. **Click "Add"**
8. **Verify `Config.plist` appears in the list** (should be checked)
9. **Clean and rebuild:**
   - Product → Clean Build Folder (`Cmd + Shift + K`)
   - Product → Build (`Cmd + B`)

### Method 2: Verify Target Membership

1. **Select `Config.plist`** in Project Navigator
2. **Open File Inspector** (right sidebar, or `Cmd + Option + 1`)
3. **Under "Target Membership"**, ensure **"VioletVibes" is checked**
4. If not checked, check it
5. **Clean and rebuild**

### Method 3: Re-add the File

If the above doesn't work:

1. **Remove Config.plist from project:**
   - Right-click `Config.plist` → Delete
   - Choose "Remove Reference" (don't move to trash)

2. **Re-add it:**
   - Right-click `VioletVibes` folder → "Add Files to VioletVibes..."
   - Navigate to `ios-app/VioletVibes/Config.plist`
   - **IMPORTANT:** Check "Copy items if needed"
   - **IMPORTANT:** Ensure "VioletVibes" target is selected
   - Click "Add"

3. **Verify it's in Copy Bundle Resources:**
   - Follow Method 1 steps above

4. **Clean and rebuild**

---

## Verify It's Working

After fixing, run the app and check the console. You should see:

```
📄 Found Config.plist at path: ...
📋 Config.plist loaded successfully
🔑 Found OPENWEATHER_KEY in Config.plist: dbb5ec5c...
✅ Weather loaded: 72°F ☀️
```

If you still see "Config.plist not found", the file is still not in the bundle.

---

## Alternative: Check Bundle Contents

To verify what's actually in your app bundle:

1. **Build the app** (`Cmd + B`)
2. **Right-click the app in Products** (in Project Navigator)
3. **Show in Finder**
4. **Right-click the .app file → Show Package Contents**
5. **Look for `Config.plist`** in the root

If it's not there, it's not being copied to the bundle.

