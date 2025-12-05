# New Features Documentation

This document enumerates all new features migrated from Final_V1 to Main, including their functionality, API endpoints, and frontend integration guidance.

## Table of Contents

1. [Dashboard Endpoint](#dashboard-endpoint)
2. [Top Recommendations](#top-recommendations)
3. [Calendar Free Time Features](#calendar-free-time-features)
4. [Weather Blueprint](#weather-blueprint)
5. [Services](#services)

---

## Dashboard Endpoint

### Endpoint
`GET /api/dashboard`

### Authentication
Required - JWT token in Authorization header

### Rate Limiting
10 requests per minute

### Description
Aggregates multiple data sources into a single dashboard response, including weather, calendar free time, recommendations, and quick suggestions.

### Request
```http
GET /api/dashboard
Authorization: Bearer <JWT_TOKEN>
```

### Response
```json
{
  "weather": {
    "temp_f": 72.5,
    "desc": "clear sky",
    "icon": "01d"
  },
  "calendar_linked": true,
  "next_free": {
    "start": "2025-02-11T14:00:00-05:00",
    "end": "2025-02-11T15:30:00-05:00"
  },
  "free_time_suggestion": {
    "should_suggest": true,
    "type": "event",
    "suggestion": {
      "name": "Brooklyn Bridge Park Event",
      "start": "2025-02-11T14:30:00-05:00",
      "location": "Brooklyn Bridge Park",
      "description": "...",
      "address": "...",
      "maps_link": "...",
      "photo_url": "..."
    },
    "message": "You're free until 3:30 PM — want to check out **Brooklyn Bridge Park Event**?"
  },
  "quick_recommendations": {
    "quick_bites": [...],
    "cozy_cafes": [...],
    "explore": [...],
    "events": [...]
  }
}
```

### Frontend Integration
- Call on dashboard/home screen load
- Display weather widget at top
- Show calendar-linked status indicator
- Display next free time block if available
- Show free-time suggestion card if `should_suggest: true`
- Render quick recommendations in category sections

### Error Handling
- If calendar not linked: `calendar_linked: false`, `next_free: null`, `free_time_suggestion: null`
- If weather unavailable: `weather: {"error": "Weather unavailable"}`
- If recommendations fail: empty arrays for each category

---

## Top Recommendations

### Endpoint
`GET /api/top_recommendations`

### Authentication
Optional - JWT token for personalized recommendations

### Rate Limiting
20 requests per minute

### Description
Returns personalized top recommendations based on user preferences and current context (time of day, weather). Combines multiple categories (quick bites, chill cafes, explore) and scores them using preference matching and context awareness.

### Request Parameters
- `limit` (optional, default: 3, max: 10) - Number of recommendations to return
- `weather` (optional) - Weather hint from client (e.g., "rain", "sunny")

### Request
```http
GET /api/top_recommendations?limit=5&weather=sunny
Authorization: Bearer <JWT_TOKEN>  # Optional
```

### Response
```json
{
  "category": "top",
  "places": [
    {
      "place_id": "...",
      "name": "Coffee Shop",
      "rating": 4.5,
      "address": "...",
      "location": {"lat": 40.6942, "lng": -73.9866},
      "walk_time": "5 min",
      "distance": "0.3 mi",
      "maps_link": "...",
      "photo_url": "...",
      "type": "place",
      "source": "google_places",
      "score": 0.87,
      "top_category": "chill_cafe"
    },
    ...
  ]
}
```

### Frontend Integration
- Use for personalized "For You" section
- Display top 3-5 recommendations in a carousel or grid
- Show score-based ranking
- Include category badge (`top_category`)
- Link to place details using `place_id` or `maps_link`

### Scoring Algorithm
Recommendations are scored using:
- 45% preference match (diet, budget, vibes)
- 20% base category score
- 15% rating
- 10% distance
- 10% context match (time of day, weather)

---

## Calendar Free Time Features

### 1. Get All Free Blocks

#### Endpoint
`GET /api/calendar/free_time`

#### Authentication
Required

#### Rate Limiting
20 requests per minute

#### Description
Returns all free time blocks in the user's calendar for today.

#### Response
```json
{
  "free_blocks": [
    {
      "start": "2025-02-11T09:00:00-05:00",
      "end": "2025-02-11T10:30:00-05:00"
    },
    {
      "start": "2025-02-11T14:00:00-05:00",
      "end": "2025-02-11T15:30:00-05:00"
    }
  ]
}
```

#### Frontend Integration
- Display as timeline or list
- Show duration for each block
- Allow user to select a block for recommendations

---

### 2. Next Free Block with Recommendation

#### Endpoint
`GET /api/calendar/next_free`

#### Authentication
Required

#### Rate Limiting
20 requests per minute

#### Description
Finds the next free time block and generates a recommendation (event or place) if the block meets criteria (>= 30 minutes, between events, before 8 PM).

#### Response
```json
{
  "has_free_time": true,
  "next_free": {
    "start": "2025-02-11T14:00:00-05:00",
    "end": "2025-02-11T15:30:00-05:00"
  },
  "suggestion": {
    "type": "event",
    "name": "Event Name",
    "start": "2025-02-11T14:30:00-05:00",
    "location": "...",
    "description": "...",
    "address": "...",
    "maps_link": "...",
    "photo_url": "..."
  },
  "suggestion_type": "event",
  "message": "You're free until 3:30 PM — want to check out **Event Name**?"
}
```

#### Frontend Integration
- Show as notification or card
- Display suggestion with image if available
- Include action buttons: "View Details", "Get Directions"
- Show message to user

---

### 3. Simple Next Free Block

#### Endpoint
`GET /api/calendar/next_free_block`

#### Authentication
Required

#### Rate Limiting
20 requests per minute

#### Description
Simple endpoint that finds the next free block without generating recommendations.

#### Response
```json
{
  "status": "success",
  "free_block": {
    "start": "2025-02-11T14:00:00-05:00",
    "end": "2025-02-11T15:30:00-05:00",
    "duration_minutes": 90
  }
}
```

#### Frontend Integration
- Use for quick free time checks
- Display duration in minutes
- Show start/end times

---

### 4. Full Free-Time Recommendation

#### Endpoint
`GET /api/calendar/recommendation`

#### Authentication
Required

#### Rate Limiting
20 requests per minute

#### Description
Full recommendation engine that detects next free block and generates a suggestion package.

#### Response
```json
{
  "has_free_time": true,
  "next_free": {
    "start": "2025-02-11T14:00:00-05:00",
    "end": "2025-02-11T15:30:00-05:00"
  },
  "suggestion": {
    "name": "Place or Event Name",
    "location": "...",
    ...
  },
  "suggestion_type": "place",
  "message": "You're free until 3:30 PM — want to explore **Place Name**?"
}
```

#### Frontend Integration
- Similar to `/next_free` but with more comprehensive logic
- Use for dedicated recommendation screens

---

## Weather Blueprint

### Endpoint
`GET /api/weather`

### Authentication
Not required (public endpoint)

### Rate Limiting
30 requests per minute

### Description
Returns current weather for Brooklyn, US. This is a simpler endpoint than the coordinate-based weather endpoints in app.py.

### Response
```json
{
  "temp_f": 72.5,
  "desc": "clear sky",
  "icon": "01d"
}
```

### Frontend Integration
- Use for quick weather display
- Display icon using OpenWeather icon URL: `https://openweathermap.org/img/w/{icon}.png`
- Show temperature and description

### Note
Main also has coordinate-based weather endpoints:
- `GET /api/weather?lat=40.6942&lon=-73.9866` - Current weather by coordinates
- `GET /api/weather/forecast?lat=40.6942&lon=-73.9866` - Weather forecast

---

## Services

### Free Time Recommender Service

**File**: `services/free_time_recommender.py`

#### Functions

##### `get_free_time_suggestion(free_block, events, user_profile)`
Main recommendation engine that suggests events or places for a free time block.

**Parameters**:
- `free_block`: `{"start": ISO, "end": ISO}` - Free time block
- `events`: List of today's calendar events
- `user_profile`: User preferences dict

**Returns**:
```json
{
  "should_suggest": true,
  "type": "event" | "place",
  "suggestion": {...},
  "message": "..."
}
```

**Logic**:
1. Validates block is >= 30 minutes
2. Checks block is before 8 PM
3. Verifies block is between events (not end-of-day)
4. Tries to suggest event first (highest priority)
5. Falls back to place suggestion if no event matches

##### `generate_free_time_recommendation(next_block)`
Wrapper function for the `/recommendation` endpoint.

**Parameters**:
- `next_block`: Free time block dict

**Returns**: Formatted recommendation package

---

### Calendar Suggestion Service

**File**: `services/calendar_suggestion_service.py`

#### Functions

##### `compute_next_free_block(free_blocks)`
Finds the next free block happening now or in the future.

**Parameters**:
- `free_blocks`: List of `{"start": ISO, "end": ISO}` blocks

**Returns**: Next free block or `None`

##### `find_next_free_block(events)`
Finds next free block by analyzing calendar events directly.

**Parameters**:
- `events`: List of calendar events with `start` and `end` fields

**Returns**: Free block with `duration_minutes` or `None`

##### `normalize_event(ev)`
Converts Google Calendar event into parsed datetime objects.

##### `build_suggestion_message(block)`
Creates natural-language message for a free time block.

---

### Quick Recommendations Service Updates

**File**: `services/recommendation/quick_recommendations.py`

#### New Function

##### `get_top_recommendations_for_user(prefs, context, limit)`
Combines multiple recommendation categories and scores them using preferences and context.

**Parameters**:
- `prefs`: User preferences dict (diet, budget, vibes, etc.)
- `context`: Context dict (`hour`, `weather`)
- `limit`: Number of recommendations (default: 3)

**Returns**: `{"category": "top", "places": [...]}`

**Scoring**:
- Preference matching (diet, budget, vibes)
- Context matching (time of day, weather)
- Base category scores
- Ratings and distance

---

## Frontend Integration Checklist

### Dashboard
- [ ] Call `GET /api/dashboard` on home screen load
- [ ] Display weather widget
- [ ] Show calendar connection status
- [ ] Render next free time block
- [ ] Display free-time suggestion card when available
- [ ] Show quick recommendations in category sections

### Top Recommendations
- [ ] Call `GET /api/top_recommendations?limit=5` for "For You" section
- [ ] Pass optional weather parameter from client
- [ ] Display recommendations with scores
- [ ] Show category badges
- [ ] Handle empty results gracefully

### Calendar Free Time
- [ ] Use `/free_time` to show all free blocks in timeline
- [ ] Use `/next_free` for notification-style suggestions
- [ ] Use `/next_free_block` for quick duration checks
- [ ] Use `/recommendation` for dedicated recommendation screens
- [ ] Handle "no free time" responses

### Weather
- [ ] Use `/api/weather` for simple weather display
- [ ] Use coordinate-based endpoints for location-specific weather
- [ ] Display weather icons and descriptions

---

## Error Handling

All endpoints follow Main's error handling patterns:

1. **Rate Limiting**: Returns 429 Too Many Requests when limit exceeded
2. **Authentication**: Returns 401 Unauthorized for protected endpoints
3. **Validation**: Returns 400 Bad Request for invalid parameters
4. **Server Errors**: Returns 500 with error message

### Common Error Responses

```json
{
  "error": "No Google Calendar linked"
}
```

```json
{
  "error": "Weather unavailable"
}
```

```json
{
  "error": "Failed to compute free time"
}
```

---

## Rate Limits Summary

| Endpoint | Rate Limit |
|----------|------------|
| `/api/dashboard` | 10/minute |
| `/api/top_recommendations` | 20/minute |
| `/api/calendar/free_time` | 20/minute |
| `/api/calendar/next_free` | 20/minute |
| `/api/calendar/next_free_block` | 20/minute |
| `/api/calendar/recommendation` | 20/minute |
| `/api/weather` | 30/minute |

---

## Notes

- All new endpoints maintain Main's security features (rate limiting, validation, logging)
- Calendar endpoints require Google Calendar to be linked
- Free-time suggestions only generate for blocks >= 30 minutes and before 8 PM
- Recommendations prioritize events over places
- Top recommendations use weighted scoring combining preferences, context, and base scores

