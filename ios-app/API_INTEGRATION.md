# iOS App API Integration Guide

This document describes the API integration for the iOS native app, including authentication, endpoints, and error handling.

## Authentication

### UserSession

The app uses `UserSession` (Observable) for managing authentication state:
- `jwt: String?` - JWT token
- `googleCalendarLinked: Bool` - Google Calendar connection status
- `preferences: UserPreferences` - User preferences
- `settings: BackendSettingsPayload?` - Backend settings

### Token Storage

JWT tokens are stored in `StorageService` using UserDefaults. The token is automatically included in authenticated API requests via `APIService`.

## API Service

### APIService

Location: `ios-app/VioletVibes/VioletVibes/Services/APIService.swift`

The `APIService` is an actor (thread-safe) that provides:
- Automatic JWT token injection
- Error handling with `APIError` enum
- Rate limit detection (429)
- Network error handling
- Automatic token clearing on 401

### Methods

#### Authentication
- `signup(email:password:firstName:)` - User signup
- `login(email:password:)` - User login

#### Dashboard
- `getDashboard(jwt:)` - Get dashboard data
- `getTopRecommendations(limit:jwt:preferences:weather:vibe:)` - Get top recommendations

#### Calendar
- `getFreeTimeBlocks(jwt:)` - Get all free time blocks
- `getNextFreeBlock(jwt:)` - Get next free block (simple)
- `getNextFreeWithRecommendation(jwt:)` - Get next free block with recommendation
- `getFullRecommendation(jwt:)` - Full recommendation engine

#### Other
- `sendChatMessage(_:latitude:longitude:jwt:preferences:)` - Send chat message
- `getQuickRecommendations(category:limit:)` - Get quick recommendations
- `getDirections(lat:lng:originLat:originLng:)` - Get directions
- `getEvents()` - Get events

## Endpoints

### Dashboard

**Endpoint**: `GET /api/dashboard`

**Authentication**: Required (JWT token)

**Response**: `DashboardAPIResponse`
- `weather: Weather?` - Current weather
- `calendar_linked: Bool?` - Calendar connection status
- `next_free: FreeTimeBlock?` - Next free time block
- `free_time_suggestion: FreeTimeSuggestion?` - Free time suggestion
- `quick_recommendations: [String: [Recommendation]]?` - All recommendation categories

**Usage**: Called by `DashboardViewModel.loadDashboard()` to get all dashboard data.

### Top Recommendations

**Endpoint**: `GET /api/top_recommendations?limit=X&weather=Y`

**Authentication**: Optional (JWT token for personalized recommendations)

**Response**: `QuickRecsAPIResponse` with `category: "top"` and `places: [Recommendation]`

**Usage**: Used by `DashboardViewModel.loadRecommendations()` as fallback if dashboard unavailable.

### Calendar Free Time

**Endpoints**:
- `GET /api/calendar/free_time` → `FreeTimeBlocksResponse`
- `GET /api/calendar/next_free_block` → `NextFreeBlockResponse`
- `GET /api/calendar/next_free` → `NextFreeRecommendationResponse`
- `GET /api/calendar/recommendation` → `FullRecommendationResponse`

**Authentication**: Required

**Usage**: Available via `APIService` methods, can be called from `CalendarViewModel` or directly.

### Weather

**Endpoint**: `GET /api/weather`

**Authentication**: Not required

**Response**: `Weather` model (decodes `{temp_f, desc, icon}`)

**Usage**: Dashboard endpoint includes weather. `WeatherService` can optionally use this endpoint.

## Models

### Dashboard Models

Location: `ios-app/VioletVibes/VioletVibes/Models/APIResponse.swift`

- `FreeTimeBlock` - `{start: String, end: String}`
- `SuggestionItem` - Event/place suggestion details
- `FreeTimeSuggestion` - `{should_suggest, type, suggestion, message}`
- `DashboardAPIResponse` - Complete dashboard response

### Response Models

- `FreeTimeBlocksResponse` - All free blocks
- `NextFreeBlockResponse` - Next free block with duration
- `NextFreeRecommendationResponse` - Next free with recommendation
- `FullRecommendationResponse` - Full recommendation package

## Error Handling

### APIError Enum

```swift
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError(String)
    case serverError(String)
}
```

### Error Handling in APIService

All API methods handle:
- **429 Rate Limit**: Returns user-friendly message
- **401 Unauthorized**: Returns authentication error
- **Network Errors**: Returns network error message
- **Decoding Errors**: Returns decoding error with details

## State Management

### ViewModels

- `DashboardViewModel` - Dashboard state and data loading
- `CalendarViewModel` - Calendar events and free time
- `ChatViewModel` - Chat messages
- `WeatherManager` - Weather data

### Observable Pattern

All ViewModels use `@Observable` macro for SwiftUI integration. State updates automatically trigger view updates.

## Memory Management

### Task Cancellation

All async functions in ViewModels check for cancellation:
- `Task.checkCancellation()` before processing
- Graceful exit on `CancellationError`
- Cleanup in `deinit` for observers

### Example

```swift
func loadDashboard(jwt: String) async {
    try? Task.checkCancellation()
    // ... load data
    try Task.checkCancellation()
    // ... process data
}
```

## Production Considerations

1. **Token Security**: Tokens stored in UserDefaults (consider Keychain for production)
2. **Error Handling**: All API errors handled with user-friendly messages
3. **Rate Limiting**: Automatic detection in APIService
4. **Network Resilience**: Fallback mechanisms (dashboard → top recommendations → sample data)
5. **Memory Leaks**: Task cancellation and proper cleanup in all async operations
