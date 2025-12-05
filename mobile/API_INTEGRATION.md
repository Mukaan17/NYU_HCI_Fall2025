# API Integration Guide

This document describes the API integration for the React Native mobile app, including authentication, endpoints, and error handling.

## Authentication

### AuthContext

The app uses `AuthContext` for managing authentication state. The context provides:

- `isAuthenticated: boolean` - Whether user is logged in
- `token: string | null` - JWT token
- `user: User | null` - Current user data
- `login(email, password)` - Login function
- `signup(email, password, firstName?)` - Signup function
- `logout()` - Logout function

### Token Storage

JWT tokens are stored securely in AsyncStorage using the `apiService`. The token is automatically included in all authenticated API requests.

## API Service

### Centralized API Service

Location: `mobile/services/apiService.ts`

The `apiService` provides:
- Automatic JWT token injection
- Request timeout (30s)
- Rate limit detection (429)
- Network error handling
- Automatic token clearing on 401

### Methods

- `get<T>(endpoint, params?)` - GET request
- `post<T>(endpoint, body?)` - POST request
- `put<T>(endpoint, body?)` - PUT request
- `delete<T>(endpoint)` - DELETE request

## Endpoints

### Dashboard

**Endpoint**: `GET /api/dashboard`

**Authentication**: Required (JWT token)

**Response**:
```typescript
{
  weather: {
    temp_f: number;
    desc: string;
    icon: string;
  };
  calendar_linked: boolean;
  next_free: {
    start: string;
    end: string;
  } | null;
  free_time_suggestion: {
    should_suggest: boolean;
    type: "event" | "place";
    suggestion: {...};
    message: string;
  } | null;
  quick_recommendations: {
    quick_bites: Recommendation[];
    cozy_cafes: Recommendation[];
    explore: Recommendation[];
    events: Recommendation[];
  };
}
```

**Usage**: Called on dashboard load to get all dashboard data in one request.

### Top Recommendations

**Endpoint**: `GET /api/top_recommendations?limit=X&weather=Y`

**Authentication**: Optional (JWT token for personalized recommendations)

**Parameters**:
- `limit` (optional, default: 3, max: 10)
- `weather` (optional) - Weather hint string

**Response**:
```typescript
{
  category: "top";
  places: Recommendation[];
}
```

**Usage**: Used for personalized "For You" recommendations.

### Calendar Free Time

**Endpoints**:
- `GET /api/calendar/free_time` - All free blocks today
- `GET /api/calendar/next_free_block` - Next free block (simple)
- `GET /api/calendar/next_free` - Next free block with recommendation
- `GET /api/calendar/recommendation` - Full recommendation engine

**Authentication**: Required

**Usage**: Calendar service methods in `mobile/services/calendarService.ts`

### Weather

**Endpoint**: `GET /api/weather?lat=X&lon=Y`

**Authentication**: Not required

**Response**:
```typescript
{
  temp_f: number;
  desc: string;
  icon: string;
}
```

**Usage**: Weather utility in `mobile/utils/getWeather.ts` uses backend endpoint with OpenWeather fallback.

## Error Handling

### Error Handler Utility

Location: `mobile/utils/errorHandler.ts`

Provides:
- `handleApiError(error)` - Maps API errors to user-friendly messages
- `retryWithBackoff(fn, maxRetries, initialDelay)` - Retry mechanism with exponential backoff

### Error Types

- **429 Rate Limit**: "Too Many Requests" - Retryable
- **401 Unauthorized**: "Authentication Required" - Not retryable, triggers logout
- **Network Error**: "Connection Error" - Retryable
- **Server Error (5xx)**: "Server Error" - Retryable
- **Client Error (4xx)**: "Request Error" - Not retryable

## State Management

### Context Providers

- `AuthProvider` - Authentication state
- `ChatProvider` - Chat messages
- `PlaceProvider` - Selected place

### AsyncStorage Keys

- `authToken` - JWT token
- `userAccount` - User account data
- `hasLoggedIn` - Login status flag
- `hasCompletedOnboardingSurvey` - Onboarding completion

## Memory Management

All `useEffect` hooks include cleanup functions to prevent memory leaks:
- Component unmount detection (`isMounted` flag)
- AbortController for fetch requests
- Timer cleanup (`clearTimeout`)

## Production Considerations

1. **Token Security**: Tokens stored in AsyncStorage (consider encrypted storage for production)
2. **Error Handling**: All API errors are handled gracefully with user-friendly messages
3. **Rate Limiting**: Automatic detection and retry with backoff
4. **Network Resilience**: Fallback mechanisms for critical features
5. **Memory Leaks**: All async operations include cleanup
