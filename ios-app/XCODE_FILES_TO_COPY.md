# Files to Copy to Xcode After Implementation

After implementing the UI changes, ensure these files are properly added to the Xcode project:

## Core App Files
- `ios-app/VioletVibes/VioletVibesApp.swift` - Main app entry point
- `ios-app/VioletVibes/Info.plist` - App configuration

## View Files
- `ios-app/VioletVibes/Views/MainTabView.swift` - Updated with native TabView (Tab enum moved here)
- `ios-app/VioletVibes/Views/Dashboard/DashboardView.swift` - Updated UI with centered badges
- `ios-app/VioletVibes/Views/Chat/ChatView.swift` - Updated UI
- `ios-app/VioletVibes/Views/Map/MapView.swift` - Updated UI
- `ios-app/VioletVibes/Views/Onboarding/WelcomeView.swift` - Updated UI
- `ios-app/VioletVibes/Views/Onboarding/PermissionsView.swift` - Updated UI with glass effects
- `ios-app/VioletVibes/Views/Safety/SafetyView.swift` - Updated UI
- `ios-app/VioletVibes/Views/Quick/QuickResultsView.swift` - Quick results view

## Component Files
- `ios-app/VioletVibes/Components/RecommendationCard.swift` - Updated with glass effects
- `ios-app/VioletVibes/Components/InputField.swift` - Updated with glass input
- `ios-app/VioletVibes/Components/NotificationView.swift` - Updated layout
- `ios-app/VioletVibes/Components/PrimaryButton.swift` - Primary button component
- `ios-app/VioletVibes/Views/Onboarding/PermissionCard.swift` - Updated with glass effects and emoji icons
- **DELETE**: `ios-app/VioletVibes/Components/NavBar.swift` - Remove custom NavBar (already deleted)

## ViewModel Files
- `ios-app/VioletVibes/ViewModels/DashboardViewModel.swift`
- `ios-app/VioletVibes/ViewModels/ChatViewModel.swift`
- `ios-app/VioletVibes/ViewModels/PlaceViewModel.swift`
- `ios-app/VioletVibes/ViewModels/OnboardingViewModel.swift`
- `ios-app/VioletVibes/ViewModels/LocationManager.swift`
- `ios-app/VioletVibes/ViewModels/MapViewModel.swift`

## Model Files
- `ios-app/VioletVibes/Models/Recommendation.swift`
- `ios-app/VioletVibes/Models/ChatMessage.swift`
- `ios-app/VioletVibes/Models/SelectedPlace.swift`
- `ios-app/VioletVibes/Models/Weather.swift`
- `ios-app/VioletVibes/Models/QuickAction.swift`
- `ios-app/VioletVibes/Models/APIResponse.swift`

## Service Files
- `ios-app/VioletVibes/Services/APIService.swift`
- `ios-app/VioletVibes/Services/LocationService.swift`
- `ios-app/VioletVibes/Services/WeatherService.swift`
- `ios-app/VioletVibes/Services/StorageService.swift`
- `ios-app/VioletVibes/Services/CalendarService.swift`
- `ios-app/VioletVibes/Services/NotificationService.swift`

## Resource Files
- `ios-app/VioletVibes/Resources/Theme.swift` - Theme definitions
- `ios-app/VioletVibes/Utilities/Extensions/Color+Hex.swift` - Color extension

## Helper Files
- `ios-app/VioletVibes/Utilities/Helpers/PolylineDecoder.swift` - Polyline decoder

## Configuration Files
- `ios-app/VioletVibes/config.plist` - API configuration (if exists, create if needed)

## Assets
- `ios-app/VioletVibes/Assets.xcassets/` - Asset catalog (app icons, images)

## Important Notes

After copying files to Xcode, ensure:

1. **All files are added to the correct target** (VioletVibes)
   - Right-click on files in Xcode → "Target Membership" → Check "VioletVibes"

2. **File references are correct** (not folder references)
   - Files should appear as individual files, not blue folders

3. **Build phases include all Swift files**
   - Check "Build Phases" → "Compile Sources" includes all `.swift` files

4. **Info.plist is properly configured**
   - Verify all permission descriptions are present
   - Check bundle identifier matches

5. **Asset catalog is included in the bundle**
   - Verify `Assets.xcassets` is in "Copy Bundle Resources"

6. **Tab enum moved to MainTabView.swift**
   - The `Tab` enum is now defined in `MainTabView.swift` instead of `NavBar.swift`
   - Update any imports if needed

7. **Native TabView with accent color**
   - The app now uses native SwiftUI `TabView` with `.tint(Theme.Colors.gradientStart)` for active tab color
   - Custom `NavBar.swift` has been removed

8. **PermissionCard uses emoji icons**
   - Icons are now emoji (📍, 📅, 🔔) instead of SF Symbols
   - Glass effects enhanced with proper gradients and shadows

