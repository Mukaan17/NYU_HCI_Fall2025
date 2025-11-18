# VioletVibes iOS App

Native SwiftUI iOS application converted from React Native/Expo.

## Project Structure

```
ios-app/
└── VioletVibes/
    ├── VioletVibesApp.swift          # App entry point
    ├── Models/                        # Data models
    │   ├── ChatMessage.swift
    │   ├── Recommendation.swift
    │   ├── SelectedPlace.swift
    │   ├── QuickAction.swift
    │   ├── Weather.swift
    │   └── APIResponse.swift
    ├── Views/                         # SwiftUI views
    │   ├── Onboarding/
    │   │   ├── WelcomeView.swift
    │   │   └── PermissionsView.swift
    │   ├── Dashboard/
    │   │   └── DashboardView.swift
    │   ├── Chat/
    │   │   └── ChatView.swift
    │   ├── Map/
    │   │   └── MapView.swift
    │   ├── Safety/
    │   │   └── SafetyView.swift
    │   ├── Quick/
    │   │   └── QuickResultsView.swift
    │   └── MainTabView.swift
    ├── ViewModels/                    # State management
    │   ├── OnboardingViewModel.swift
    │   ├── ChatViewModel.swift
    │   ├── PlaceViewModel.swift
    │   ├── LocationManager.swift
    │   ├── DashboardViewModel.swift
    │   └── MapViewModel.swift
    ├── Services/                      # API & system services
    │   ├── APIService.swift
    │   ├── LocationService.swift
    │   ├── CalendarService.swift
    │   ├── NotificationService.swift
    │   ├── WeatherService.swift
    │   └── StorageService.swift
    ├── Components/                    # Reusable SwiftUI components
    │   ├── NavBar.swift
    │   ├── RecommendationCard.swift
    │   ├── InputField.swift
    │   ├── PrimaryButton.swift
    │   └── NotificationView.swift
    ├── Utilities/                     # Helpers & extensions
    │   ├── Extensions/
    │   │   └── Color+Hex.swift
    │   └── Helpers/
    │       └── PolylineDecoder.swift
    ├── Resources/                     # Assets, colors, fonts
    │   └── Theme.swift
    └── Info.plist                     # Permissions & config
```

## Setup Instructions

### 1. Create Xcode Project

1. Open Xcode
2. Create a new project:
   - Choose "iOS" → "App"
   - Product Name: `VioletVibes`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Bundle Identifier: `com.violetvibes.app`
   - Minimum Deployment: `iOS 17.0`

### 2. Add Files to Project

1. Copy all files from `ios-app/VioletVibes/` into your Xcode project
2. Maintain the folder structure shown above
3. Ensure all files are added to the target

### 3. Configure Info.plist

The `Info.plist` file is already configured with:
- Location permissions
- Calendar permissions
- Notification permissions
- URL scheme: `violetvibes`
- App Transport Security settings

### 4. Configure API URL

Create a `Config.plist` file in the project root with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>API_URL</key>
    <string>http://localhost:5000</string>
    <key>OPENWEATHER_KEY</key>
    <string>YOUR_OPENWEATHER_API_KEY</string>
</dict>
</plist>
```

Or set environment variables in Xcode scheme:
- `API_URL`: Your backend server URL
- `OPENWEATHER_KEY`: Your OpenWeather API key

### 5. Dependencies

This project uses only native iOS frameworks:
- SwiftUI (iOS 17+)
- CoreLocation
- EventKit
- UserNotifications
- MapKit
- URLSession

No external dependencies required.

### 6. Build and Run

1. Select your target device or simulator
2. Press `Cmd + R` to build and run
3. Ensure the backend server is running on the configured URL

## Features

- ✅ Welcome onboarding flow
- ✅ Permissions management (Location, Calendar, Notifications)
- ✅ Dashboard with weather, quick actions, and recommendations
- ✅ Chat interface with AI recommendations
- ✅ Map view with directions and place markers
- ✅ Safety center with emergency contacts
- ✅ Quick category-based recommendations
- ✅ Custom navigation bar with blur effects
- ✅ Liquid Glass design with materials
- ✅ Dark theme matching original design

## API Endpoints

The app communicates with the Flask backend at these endpoints:

- `POST /api/chat` - Send chat message
- `GET /api/quick_recs?category={category}` - Get quick recommendations
- `GET /api/directions?lat={lat}&lng={lng}` - Get walking directions
- `GET /api/events` - Get nearby events

## Notes

- Server remains unchanged - all endpoints work as before
- The app uses iOS 17+ features including latest SwiftUI APIs
- Map polyline rendering requires MKMapView for full implementation (currently using MapKit's Map view)
- All UI components match the original React Native design
- Theme colors, typography, and spacing match `theme.ts` exactly

## Troubleshooting

### Build Errors

- Ensure all files are added to the target
- Check that iOS deployment target is 17.0+
- Verify Info.plist is properly configured

### API Connection Issues

- Check that `API_URL` is correctly set
- Verify backend server is running
- Check App Transport Security settings for localhost

### Location Not Working

- Ensure location permissions are granted
- Check Info.plist has location usage descriptions
- Verify location services are enabled on device/simulator

