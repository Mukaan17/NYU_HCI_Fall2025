# Fix: Multiple commands produce Info.plist

This error occurs when Xcode tries to process `Info.plist` both automatically AND as a copied resource.

## Solution: Remove Info.plist from Copy Bundle Resources

### Steps:

1. **Open your Xcode project**

2. **Select your project** (blue icon at top of navigator)

3. **Select the "VioletVibes" target**

4. **Go to "Build Phases" tab**

5. **Expand "Copy Bundle Resources"**

6. **Find `Info.plist` in the list**

7. **Remove it:**
   - Select `Info.plist`
   - Press `Delete` key
   - Click "Remove" when prompted

8. **Verify Info.plist is in the project:**
   - In Project Navigator, `Info.plist` should still be visible
   - It should NOT be in "Copy Bundle Resources" anymore

9. **Clean and rebuild:**
   - Product → Clean Build Folder (`Cmd+Shift+K`)
   - Product → Build (`Cmd+B`)

## Alternative: Check Build Settings

If the above doesn't work:

1. **Select target** → **Build Settings** tab

2. **Search for "Info.plist"**

3. **Find "Info.plist File" setting**

4. **Verify it points to:** `VioletVibes/Info.plist` (relative path)

5. **Make sure "Generate Info.plist File" is set to "No"** (if that option exists)

## Why This Happens

Xcode automatically processes `Info.plist` during the build. If you also add it to "Copy Bundle Resources", Xcode tries to:
- Process it automatically (normal)
- Copy it as a resource (duplicate)

This creates a conflict. The solution is to let Xcode handle it automatically and NOT copy it as a resource.

