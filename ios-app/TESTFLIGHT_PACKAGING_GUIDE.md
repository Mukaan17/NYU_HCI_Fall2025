# TestFlight Packaging Guide for VioletVibes

This guide provides step-by-step instructions for packaging and distributing the VioletVibes iOS app via TestFlight.

## Prerequisites

### 1. Apple Developer Account Setup
- Enroll in Apple Developer Program at https://developer.apple.com/programs/ ($99/year)
- Wait for enrollment approval (usually 24-48 hours)
- Access App Store Connect at https://appstoreconnect.apple.com

### 2. App Store Connect App Record
- Log into App Store Connect
- Click "+" → "New App"
- Fill in:
  - Platform: iOS
  - Name: VioletVibes
  - Primary Language: English
  - Bundle ID: `com.HCI.VioletVibes` (must match Xcode project)
  - SKU: `violetvibes-001` (unique identifier, can be anything)
- Save and note the App ID

## Xcode Project Configuration

### 3. Update Build Settings
**File:** `ios-app/VioletVibes/VioletVibes.xcodeproj/project.pbxproj`

**Changes needed:**
- Verify `DEVELOPMENT_TEAM = 3M9PQ9Y9H8` is correct (or update to your team ID)
- Check `PRODUCT_BUNDLE_IDENTIFIER = com.HCI.VioletVibes` matches App Store Connect
- Update `MARKETING_VERSION` (e.g., "1.0") - this is the user-facing version
- Update `CURRENT_PROJECT_VERSION` (e.g., "1") - increment for each build
- Verify `IPHONEOS_DEPLOYMENT_TARGET` is reasonable (currently shows 26.1, should be iOS 17.0+)

### 4. Configure Signing & Capabilities
- Open project in Xcode
- Select project → Target "VioletVibes"
- **Signing & Capabilities tab:**
  - Enable "Automatically manage signing"
  - Select your Team
  - Verify Bundle Identifier matches App Store Connect
- **General tab:**
  - Verify Version and Build numbers
  - Set minimum iOS version to 17.0 (if currently 26.1)

### 5. Update Info.plist
**File:** `ios-app/VioletVibes/VioletVibes/Info.plist`

Ensure required keys are present:
- `CFBundleDisplayName`: App name shown on home screen
- `CFBundleShortVersionString`: Marketing version (1.0)
- `CFBundleVersion`: Build number (1)
- All permission usage descriptions are complete

## Building for Distribution

### 6. Clean Build
- In Xcode: Product → Clean Build Folder (Shift+Cmd+K)
- This ensures a fresh build

### 7. Archive the App
- Select "Any iOS Device" or "Generic iOS Device" as build destination (not simulator)
- Product → Archive
- Wait for archive to complete (may take several minutes)
- Organizer window will open automatically

### 8. Validate Archive
- In Organizer, select your archive
- Click "Validate App"
- Sign in with Apple ID
- Select your team
- Wait for validation to complete
- Fix any errors before proceeding

### 9. Distribute to App Store Connect
- In Organizer, select validated archive
- Click "Distribute App"
- Choose "App Store Connect"
- Select "Upload"
- Choose your distribution options:
  - Include bitcode: No (deprecated)
  - Upload symbols: Yes (for crash reports)
- Select your team and provisioning profile
- Click "Upload"
- Wait for upload to complete (may take 10-30 minutes)

## TestFlight Setup

### 10. Process Build in App Store Connect
- Go to App Store Connect → My Apps → VioletVibes
- Navigate to TestFlight tab
- Wait for build to process (usually 10-60 minutes)
- Build status will change from "Processing" to "Ready to Test"

### 11. Configure TestFlight
- **Internal Testing:**
  - Add internal testers (up to 100 users in your team)
  - No Beta App Review required
  - Available immediately after processing

- **External Testing:**
  - Create a new group or use existing
  - Add the build to the group
  - Submit for Beta App Review (required for external testers)
  - Fill in:
    - What to Test: Description of new features/fixes
    - Contact Information: Your email
    - Demo Account: If app requires login
    - Notes: Any special instructions
  - Submit for review (usually 24-48 hours)

### 12. Add Testers
- **Internal Testers:**
  - App Store Connect → Users and Access → Add users with "App Manager" or "Admin" role
  - They'll receive email invitation

- **External Testers:**
  - TestFlight → External Testing → Add testers
  - Enter email addresses (up to 10,000)
  - Testers receive email with TestFlight link

## Command Line Alternative (Optional)

### 13. Create Build Script
Create a script for automated builds:

**File:** `ios-app/scripts/build-for-testflight.sh`

```bash
#!/bin/bash
# Build script for TestFlight distribution

PROJECT_PATH="VioletVibes/VioletVibes.xcodeproj"
SCHEME="VioletVibes"
ARCHIVE_PATH="./build/VioletVibes.xcarchive"
EXPORT_PATH="./build"

# Clean
xcodebuild clean -project "$PROJECT_PATH" -scheme "$SCHEME"

# Archive
xcodebuild archive \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -archivePath "$ARCHIVE_PATH" \
  -configuration Release \
  -destination "generic/platform=iOS"

# Export (if using manual export)
# xcodebuild -exportArchive \
#   -archivePath "$ARCHIVE_PATH" \
#   -exportPath "$EXPORT_PATH" \
#   -exportOptionsPlist ExportOptions.plist
```

## Important Notes

- **Version Numbers:** Each TestFlight build must have a unique build number. Increment `CURRENT_PROJECT_VERSION` for each upload.
- **Bundle ID:** Cannot be changed after first submission. Ensure `com.HCI.VioletVibes` is final.
- **Certificates:** Xcode will automatically manage certificates if "Automatically manage signing" is enabled.
- **Processing Time:** First build processing can take up to 2 hours. Subsequent builds are usually faster.
- **TestFlight Expiration:** Builds expire after 90 days. Upload new builds before expiration.

## Troubleshooting

- **"No accounts with App Store Connect access"**: Ensure you're signed in with correct Apple ID in Xcode → Preferences → Accounts
- **"Bundle ID not found"**: Create app record in App Store Connect first
- **"Invalid Bundle"**: Check Info.plist and ensure all required keys are present
- **"Missing Compliance"**: Answer export compliance questions in App Store Connect
- **Upload fails**: Check internet connection and try again. Large apps may timeout.

## Files to Review/Update

1. `ios-app/VioletVibes/VioletVibes.xcodeproj/project.pbxproj` - Build settings
2. `ios-app/VioletVibes/VioletVibes/Info.plist` - App metadata and permissions
3. `ios-app/VioletVibes/VioletVibes/VioletVibes.entitlements` - App capabilities
4. Verify `Config.plist` doesn't contain hardcoded localhost URLs for production builds

## Quick Checklist

- [ ] Apple Developer account enrolled and active
- [ ] App record created in App Store Connect
- [ ] Xcode project configured with correct team and bundle ID
- [ ] Version and build numbers set appropriately
- [ ] Code signing configured (automatic or manual)
- [ ] Info.plist contains all required metadata
- [ ] App archived successfully
- [ ] Archive validated without errors
- [ ] Build uploaded to App Store Connect
- [ ] Build processed and ready in TestFlight
- [ ] Testers added (internal or external)
- [ ] Beta App Review submitted (if external testing)

## Additional Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [TestFlight Beta Testing Guide](https://developer.apple.com/testflight/)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)
