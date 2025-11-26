# VioletVibes - NYU Nightlife & Events Discovery App

A multi-platform application for discovering nightlife, events, and places around NYU campus, built with native iOS (Swift/SwiftUI) and React Native/Expo, backed by a Python Flask API server.

---

## 🏗️ Project Architecture

### Overview

VioletVibes is a **multi-platform project** with three main components:

1. **iOS Native App** (`ios-app/`) - Primary implementation using Swift 6.2 & SwiftUI
2. **React Native/Expo App** (`mobile/`) - Cross-platform implementation using Expo SDK 54
3. **Python Flask Backend** (`server/`) - RESTful API server for recommendations, events, and chat

---

### 📱 iOS Native App Architecture (Primary)

The iOS app follows a **MVVM (Model-View-ViewModel) architecture** with Swift 6.2's modern concurrency and observation patterns.

#### **Technology Stack**
- **Language**: Swift 6.2
- **UI Framework**: SwiftUI
- **State Management**: `@Observable` macro (Swift 6.2)
- **Concurrency**: `async/await`, `actor`, `Task`
- **Design System**: iOS 18 HIG with "Liquid Glass" aesthetic

#### **Project Structure**

```
ios-app/VioletVibes/
├── VioletVibesApp.swift          # App entry point & root navigation
├── Models/                        # Data models
│   ├── UserAccount.swift         # User authentication data
│   ├── UserPreferences.swift     # User preferences & settings
│   ├── Recommendation.swift      # Place/event recommendations
│   ├── ChatMessage.swift         # Chat conversation data
│   ├── Weather.swift             # Weather data model
│   └── ...
├── ViewModels/                    # Business logic & state management
│   ├── OnboardingViewModel.swift # Onboarding flow state
│   ├── ChatViewModel.swift       # Chat conversation state
│   ├── DashboardViewModel.swift  # Dashboard recommendations
│   ├── MapViewModel.swift        # Map & routing state
│   ├── PlaceViewModel.swift      # Selected place state
│   ├── LocationManager.swift     # Location tracking & updates
│   └── WeatherManager.swift      # Weather data management
├── Services/                       # Business logic & API integration
│   ├── APIService.swift          # HTTP client for backend API
│   ├── LocationService.swift     # CoreLocation wrapper (actor-based)
│   ├── StorageService.swift      # UserDefaults persistence (actor-based)
│   ├── WeatherService.swift      # Weather API integration
│   ├── CalendarService.swift     # Google Calendar integration
│   ├── ContactsService.swift     # Trusted contacts management
│   ├── NotificationService.swift # Push notifications
│   └── ...
├── Views/                         # SwiftUI views organized by feature
│   ├── Onboarding/               # Welcome, Login, Sign-up, Survey, Permissions
│   ├── Dashboard/                # Main dashboard with quick actions
│   ├── Chat/                      # AI chat interface
│   ├── Map/                       # Map view with location tracking
│   ├── Quick/                     # Quick action results sheets
│   ├── Safety/                    # Safety features & location sharing
│   ├── Settings/                  # Account, preferences, trusted contacts
│   └── MainTabView.swift          # Tab navigation container
├── Components/                    # Reusable UI components
│   ├── InputField.swift          # Text input with liquid glass styling
│   ├── PrimaryButton.swift       # Primary action button
│   ├── RecommendationCard.swift  # Place/event card component
│   ├── LocationPickerView.swift  # MapKit autocomplete location picker
│   └── ...
├── Resources/
│   └── Theme.swift                # Design system (colors, typography, spacing)
└── Utilities/
    ├── Extensions/                # Swift extensions
    ├── Helpers/                   # Helper functions
    └── ViewModifiers/             # Custom view modifiers
```

#### **Architecture Patterns**

**1. MVVM with @Observable**
- ViewModels use `@Observable` macro for automatic view updates
- Views access ViewModels via `@Environment` for dependency injection
- Clear separation: Views handle UI, ViewModels handle business logic

**2. Service Layer Pattern**
- Services encapsulate business logic and external API calls
- `LocationService` and `StorageService` use `actor` for thread-safe operations
- Singleton pattern for shared services (e.g., `APIService.shared`)

**3. Dependency Injection**
- ViewModels and Services injected via SwiftUI's `@Environment`
- Centralized in `VioletVibesApp.swift` for app-wide availability

**4. State Management**
- `@State` for local view state
- `@Environment` for shared ViewModels
- `@Observable` for reactive state updates
- `Task` and `async/await` for asynchronous operations

**5. Navigation Flow**
```
RootView → Welcome → Permissions → Login/Sign-up → Onboarding Survey → MainTabView
                                                                    ↓
                                            Dashboard | Chat | Map | Safety | Settings
```

#### **Key Features**

- **Smart Onboarding**: Tab-based login/sign-up with state memory, preferences survey, permissions flow
- **Location Services**: Optimized location tracking with throttling (100m threshold) and battery efficiency
- **Liquid Glass UI**: Native SwiftUI materials (`.regularMaterial`, `.ultraThinMaterial`) with gradient overlays
- **Performance Optimized**: Deferred heavy operations, cached location checks, throttled updates
- **Swift 6.2 Concurrency**: Strict concurrency with `actor`, `@MainActor`, and structured concurrency

---

### 📱 React Native/Expo App Architecture (Secondary)

#### **Technology Stack**
- **Framework**: React Native 0.81
- **Router**: Expo Router 3.5
- **Language**: TypeScript
- **State Management**: React Context API
- **UI**: React Native components with Expo modules

#### **Project Structure**

```
mobile/
├── app/                           # Expo Router file-based routing
│   ├── _layout.tsx               # Root layout
│   ├── (tabs)/                    # Tab navigation group
│   │   ├── dashboard.tsx         # Dashboard screen
│   │   ├── chat.tsx              # Chat screen
│   │   ├── map.tsx               # Map screen
│   │   └── safety.tsx            # Safety screen
│   ├── welcome.tsx                # Welcome screen
│   ├── permissions.tsx           # Permissions screen
│   └── quick/[category].tsx      # Quick action results
├── components/                    # Reusable React components
├── context/                       # React Context providers
│   ├── ChatContext.tsx           # Chat state management
│   └── PlaceContext.tsx          # Selected place state
├── hooks/                         # Custom React hooks
│   └── useLocation.ts            # Location tracking hook
├── constants/
│   └── theme.ts                  # Design system constants
└── utils/                         # Utility functions
```

---

### 🖥️ Backend API Architecture

#### **Technology Stack**
- **Framework**: Flask (Python)
- **AI**: Google Gemini API for chat recommendations
- **APIs**: Google Places, Google Directions, OpenWeatherMap, NYC Open Data

#### **Project Structure**

```
server/
├── app.py                         # Flask app & route definitions
├── services/                      # Business logic services
│   ├── recommendation_service.py # AI-powered recommendations
│   ├── places_service.py        # Google Places integration
│   ├── directions_service.py    # Walking directions
│   ├── weather_service.py       # Weather data
│   ├── nyc_events_service.py    # NYC permitted events
│   └── ...
├── utils/                         # Utility modules
│   ├── cache.py                 # Request caching
│   ├── chat_memory.py           # Chat conversation memory
│   └── helpers.py               # Helper functions
└── requirements.txt              # Python dependencies
```

#### **API Endpoints**

- `POST /api/chat` - AI chat recommendations with conversation memory
- `GET /api/quick_recs?category=<category>` - Quick action recommendations
- `GET /api/events` - NYC permitted events near campus
- `GET /api/directions?lat=<lat>&lng=<lng>` - Walking directions
- `GET /health` - Health check endpoint

---

## 🚀 Developer Setup Guide

This project uses Expo SDK 54, React 19, expo-router, and React Native 0.81.
Because of the newer versions, the setup must be followed exactly to avoid dependency conflicts.

🚀 1. Requirements
Node
    Use Node 18 or Node 20.
    Check:

        node -v

NPM:
    Use npm, not yarn/pnpm:
    Check:

        npm -v

Xcode (for iOS development):
    Open Xcode at least once

    Make sure iOS Simulator is installed
(       Xcode → Settings → Platforms → iOS)

--------------------------------------------------------

📦 2. Install Dependencies
Clone the project:

    git clone <repository-url>
    cd mobile


Install:

    npm install


⚠️ Do NOT install anything manually.
The dependency versions are intentionally locked to avoid conflicts.

------------------------------------------------------------------

📱 3. Install the iOS Development Build (Required)
    This project does not work in Expo Go.
    You must build and install the dev client:

        npx expo run:ios


    This step builds a native iOS app and installs it in the simulator.
    (First time takes ~10–20 minutes.)

---------------------------------------------------------------

▶️ 4. Run the App

Start Metro:

    npx expo start --clear


The simulator will automatically open the dev build and load the app.
If the simulator does not open:

    npx expo start --dev-client

Then press:

    i

-----------------------------------------------------------------------

📁 5. Required File Structure
Do not delete or rename these files:

mobile/
  app/
    _layout.tsx
    (onboarding)/
    (tabs)/
  package.json

-------------------------------------------------------------------------

⚠️ 6. Do NOT Do These Things to keep the project stable:

❌ Do NOT run npm install react
❌ Do NOT run npm install react-native
❌ Do NOT run npm install expo-router
❌ Do NOT update Expo or React Native
❌ Do NOT delete App.js
❌ Do NOT install navigation packages manually

Everything is preconfigured.

---------------------------------------------------------------------

🔄 7. Reset If Something Breaks

If you hit bundling errors or React version conflicts:

rm -rf node_modules
rm package-lock.json
npm install
npx expo run:ios
npx expo start --clear


This fixes:

Duplicate React packages

"React Element from older version" errors

Metro cache corruption

Missing module issues

---------------------------------------------------------------------------------

---

## 🎉 You're Ready to Develop

Once the setup is done, you can work normally inside:

- **iOS App**: `ios-app/VioletVibes/` - Native Swift/SwiftUI development
- **React Native App**: `mobile/app/` - Cross-platform development
- **Backend**: `server/` - Python Flask API development

---

## 📝 Development Guidelines

### iOS App Development

- **Use Swift 6.2 features**: `@Observable`, `actor`, strict concurrency
- **Follow MVVM pattern**: Keep business logic in ViewModels, UI in Views
- **Performance**: Defer heavy operations, throttle location updates, cache data
- **Design**: Follow iOS 18 HIG, use liquid glass materials for UI elements
- **Concurrency**: Use `@MainActor` for UI updates, `actor` for thread-safe services

### React Native Development

- **File-based routing**: Use Expo Router's file-based navigation
- **State management**: Use Context API for shared state
- **Components**: Keep components reusable and well-typed with TypeScript

### Backend Development

- **RESTful APIs**: Follow REST conventions for endpoints
- **Error handling**: Always return proper HTTP status codes and error messages
- **Caching**: Use request caching for external API calls to reduce latency

---

## 🔧 Troubleshooting

### iOS App Issues

- **Metal rendering crashes**: Ensure GeometryReader has valid dimensions before rendering
- **Location updates**: Check throttling settings if updates are too frequent
- **Performance**: Use Instruments to profile and identify bottlenecks

### React Native Issues

See the setup guide above for common React/Expo issues and fixes.

---

## 📚 Additional Documentation

- **iOS Setup**: See `ios-app/SETUP_GUIDE.md`
- **Server Connection**: See `ios-app/SERVER_CONNECTION.md`
- **Troubleshooting**: See `ios-app/TROUBLESHOOTING.md`