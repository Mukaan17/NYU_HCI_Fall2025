# Quick Setup Guide - Getting VioletVibes Running

## Step 1: Create Xcode Project

1. **Open Xcode** (you need Xcode 15+ for iOS 26 support)

2. **Create New Project:**
   - File → New → Project
   - Select **iOS** → **App**
   - Click **Next**

3. **Configure Project:**
   - **Product Name:** `VioletVibes`
   - **Team:** Select your development team (or "None" for simulator only)
   - **Organization Identifier:** `com.violetvibes` (or your own)
   - **Bundle Identifier:** Will auto-generate (e.g., `com.violetVibes.VioletVibes`)
   - **Interface:** `SwiftUI`
   - **Language:** `Swift`
   - **Storage:** `None` (we'll add our own)
   - **Include Tests:** Optional
   - Click **Next**

4. **Save Location:**
   - Navigate to `/Users/mukaan/Classes/NYU_HCI_Fall2025/ios-app/`
   - **IMPORTANT:** Uncheck "Create Git repository" if you don't want a new repo
   - Click **Create**

## Step 2: Delete Default Files

1. In Xcode, delete the default files Xcode created:
   - `ContentView.swift` (if it exists)
   - `VioletVibesApp.swift` (if it exists - we have our own)
   - Any default assets

2. **Keep:** The project structure and Info.plist (we'll merge with ours)

## Step 3: Add All Source Files

1. **In Xcode Project Navigator:**
   - Right-click on the `VioletVibes` folder (blue icon)
   - Select **Add Files to "VioletVibes"...**
   - Navigate to `ios-app/VioletVibes/`
   - Select **ALL** files and folders:
     - `VioletVibesApp.swift`
     - `Models/` folder
     - `Views/` folder
     - `ViewModels/` folder
     - `Services/` folder
     - `Components/` folder
     - `Resources/` folder
     - `Utilities/` folder
   - **IMPORTANT:** Check these options:
     - ✅ **Copy items if needed** (uncheck if files are already in the right place)
     - ✅ **Create groups** (not folder references)
     - ✅ **Add to targets:** VioletVibes
   - Click **Add**

## Step 4: Replace Info.plist

1. **In Xcode:**
   - Find `Info.plist` in the project
   - Right-click → **Show in Finder**
   - Replace its contents with the one from `ios-app/VioletVibes/Info.plist`
   - Or manually copy the keys from our Info.plist

## Step 5: Configure Build Settings

1. **Select the Project** (blue icon at top of navigator)
2. **Select the Target** "VioletVibes"
3. **Go to "General" tab:**
   - **Minimum Deployments:** Set to **iOS 26.0** (or iOS 17.0 if iOS 26 isn't available yet)
   - **Supported Destinations:** iPhone, iPad

4. **Go to "Build Settings" tab:**
   - Search for "Swift Language Version"
   - Set to **Swift 6** (or latest available)
   - Search for "iOS Deployment Target"
   - Set to **26.0** (or 17.0 minimum)

## Step 6: Configure API Connection

### Option A: Using Config.plist (Recommended)

1. **Create Config.plist:**
   - Right-click on `VioletVibes` folder in Xcode
   - New File → Property List
   - Name it `Config.plist`
   - Add these keys:
     ```xml
     <key>API_URL</key>
     <string>http://localhost:5001</string>
     <key>OPENWEATHER_KEY</key>
     <string>YOUR_KEY_HERE</string>
     ```
   - Replace `YOUR_KEY_HERE` with your OpenWeather API key (get one free at openweathermap.org)

2. **Add Config.plist to project:**
   - Make sure it's added to the target

### Option B: Using Environment Variables

1. **In Xcode:**
   - Product → Scheme → Edit Scheme
   - Select "Run" → "Arguments"
   - Under "Environment Variables", add:
     - `API_URL` = `http://localhost:5001`
     - `OPENWEATHER_KEY` = `your_key_here`

## Step 7: Start Your Backend Server

1. **Open Terminal:**
   ```bash
   cd /Users/mukaan/Classes/NYU_HCI_Fall2025/server
   python app.py
   ```

2. **Verify it's running:**
   - Should see: `Running on http://0.0.0.0:5001`
   - Keep this terminal open

## Step 8: Build and Run

1. **Select a Simulator:**
   - In Xcode toolbar, click the device selector
   - Choose **iPhone 15 Pro** or any iOS 17+ simulator

2. **Build:**
   - Press `Cmd + B` to build
   - Fix any errors if they appear

3. **Run:**
   - Press `Cmd + R` to run
   - The app should launch in the simulator

## Step 9: Test the App

1. **Onboarding Flow:**
   - You should see the Welcome screen
   - Tap "Let's Go"
   - Grant permissions when prompted

2. **Test Features:**
   - Dashboard should show weather and recommendations
   - Chat should connect to your backend
   - Map should show your location (if permissions granted)

## Troubleshooting

### Build Errors

**"Cannot find type 'X' in scope"**
- Make sure all files are added to the target
- Check that imports are correct
- Clean build folder: Product → Clean Build Folder (`Cmd + Shift + K`)

**"Module 'Observation' not found"**
- This is part of Swift 6 / iOS 17+
- Make sure you're using Xcode 15+ and iOS 17+ deployment target

**"Use of undeclared type 'MapCameraPosition'"**
- This requires iOS 17+
- Update deployment target to iOS 17.0 or higher

### Runtime Errors

**"API connection failed"**
- Check that backend server is running
- Verify `API_URL` in Config.plist or environment variables
- For physical device, use your Mac's IP address instead of localhost

**"Location not working"**
- Grant location permissions when prompted
- For simulator: Features → Location → Custom Location (set to NYU Tandon: 40.693393, -73.98555)

**"Weather not loading"**
- Check that `OPENWEATHER_KEY` is set correctly
- Get a free API key at: https://openweathermap.org/api

### For Physical Device Testing

1. **Get your Mac's IP:**
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
   Example: `192.168.1.100`

2. **Update Config.plist:**
   ```xml
   <key>API_URL</key>
   <string>http://192.168.1.100:5001</string>
   ```

3. **Connect device:**
   - Plug iPhone into Mac
   - Trust the computer on iPhone
   - Select your device in Xcode
   - Make sure device and Mac are on same WiFi

## Quick Checklist

- [ ] Xcode project created
- [ ] All source files added to project
- [ ] Info.plist configured
- [ ] Deployment target set to iOS 17.0+ (or 26.0)
- [ ] Config.plist created with API_URL and OPENWEATHER_KEY
- [ ] Backend server running on port 5001
- [ ] App builds without errors
- [ ] App runs in simulator/device
- [ ] Permissions granted
- [ ] Can send chat messages
- [ ] Map shows location

## Next Steps

Once the app is running:
1. Test all features (chat, map, dashboard, safety)
2. Customize theme colors if needed
3. Add app icon and launch screen
4. Configure for App Store if deploying

## Need Help?

- Check the main README.md for project structure
- Check SERVER_CONNECTION.md for API details
- Ensure all files are in the correct folders
- Verify Xcode version supports iOS 17+ features

