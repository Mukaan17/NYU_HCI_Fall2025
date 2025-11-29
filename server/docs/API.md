# API Reference

## Base URL

**Production**: `https://your-app-name.ondigitalocean.app`  
**Development**: `http://localhost:5001`

## Authentication

Most endpoints require JWT authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

Tokens expire after 7 days.

## Rate Limiting

Rate limits are applied per IP address:

- **Default**: 200 requests per day, 50 requests per hour
- **Chat**: 10 requests per minute
- **Auth endpoints**: 5 requests per minute
- **Quick Recommendations**: 30 requests per minute

When rate limit is exceeded, a `429 Too Many Requests` response is returned.

## Error Responses

All errors follow this format:

```json
{
  "error": "Error type",
  "message": "Human-readable error message",
  "request_id": "abc123"
}
```

### HTTP Status Codes

- `200 OK`: Request successful
- `201 Created`: Resource created successfully
- `400 Bad Request`: Invalid request parameters
- `401 Unauthorized`: Authentication required or invalid
- `404 Not Found`: Resource not found
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error
- `503 Service Unavailable`: Service temporarily unavailable

## Endpoints

### Authentication

#### Sign Up

Create a new user account.

**Endpoint**: `POST /api/auth/signup`

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Response** (201 Created):
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "preferences": {
      "vibes": {},
      "distance_limit_minutes": 20,
      "indoor_outdoor": "either"
    },
    "settings": {
      "notifications_enabled": true,
      "calendar_integration_enabled": false
    }
  }
}
```

**Error Responses**:
- `400`: Missing email or password
- `409`: Email already registered
- `500`: Internal server error

**Rate Limit**: 5 requests per minute

---

#### Login

Authenticate and receive JWT token.

**Endpoint**: `POST /api/auth/login`

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Response** (200 OK):
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "preferences": {...},
    "settings": {...}
  }
}
```

**Error Responses**:
- `400`: Missing email or password
- `401`: Invalid email or password
- `500`: Internal server error

**Rate Limit**: 5 requests per minute

---

### User Management

All user endpoints require authentication.

#### Get Current User

Get current user's profile information.

**Endpoint**: `GET /api/user/me`

**Headers**:
```
Authorization: Bearer <token>
```

**Response** (200 OK):
```json
{
  "id": 1,
  "email": "user@example.com",
  "preferences": {...},
  "settings": {...},
  "recent_activity": [...]
}
```

**Error Responses**:
- `401`: Unauthorized (missing or invalid token)
- `500`: Internal server error

---

#### Get User Preferences

Get user preferences.

**Endpoint**: `GET /api/user/preferences`

**Headers**:
```
Authorization: Bearer <token>
```

**Response** (200 OK):
```json
{
  "vibes": {
    "chill_cafes": 0.8,
    "quick_bites": 0.6
  },
  "distance_limit_minutes": 20,
  "indoor_outdoor": "either"
}
```

---

#### Update User Preferences

Update user preferences.

**Endpoint**: `POST /api/user/preferences`

**Headers**:
```
Authorization: Bearer <token>
```

**Request Body**:
```json
{
  "distance_limit_minutes": 30,
  "indoor_outdoor": "indoor"
}
```

**Response** (200 OK):
```json
{
  "vibes": {...},
  "distance_limit_minutes": 30,
  "indoor_outdoor": "indoor"
}
```

---

#### Get User Settings

Get user settings.

**Endpoint**: `GET /api/user/settings`

**Headers**:
```
Authorization: Bearer <token>
```

**Response** (200 OK):
```json
{
  "notifications_enabled": true,
  "calendar_integration_enabled": false
}
```

---

#### Update User Settings

Update user settings.

**Endpoint**: `POST /api/user/settings`

**Headers**:
```
Authorization: Bearer <token>
```

**Request Body**:
```json
{
  "notifications_enabled": false
}
```

**Response** (200 OK):
```json
{
  "notifications_enabled": false,
  "calendar_integration_enabled": false
}
```

---

#### Log User Activity

Log user interaction for recommendation learning.

**Endpoint**: `POST /api/user/activity`

**Headers**:
```
Authorization: Bearer <token>
```

**Request Body**:
```json
{
  "type": "clicked_recommendation",
  "place_id": "ChIJ...",
  "name": "Café Name",
  "vibe": "chill",
  "score": 0.87
}
```

**Response** (200 OK):
```json
{
  "status": "ok"
}
```

**Error Responses**:
- `400`: Missing 'type' field
- `401`: Unauthorized
- `500`: Internal server error

---

#### Update Notification Token

Update push notification token.

**Endpoint**: `POST /api/user/notification_token`

**Headers**:
```
Authorization: Bearer <token>
```

**Request Body**:
```json
{
  "token": "ExponentPushToken[...]"
}
```

**Response** (200 OK):
```json
{
  "status": "ok"
}
```

**Error Responses**:
- `400`: Missing 'token' field
- `401`: Unauthorized
- `500`: Internal server error

---

### Chat & Recommendations

#### Send Chat Message

Send a message and get AI-powered recommendations.

**Endpoint**: `POST /api/chat`

**Headers** (optional):
```
Authorization: Bearer <token>
X-Session-ID: <session-id>
```

**Request Body**:
```json
{
  "message": "I want coffee",
  "latitude": 40.693393,
  "longitude": -73.98555
}
```

**Response** (200 OK):
```json
{
  "reply": "Here are some great coffee spots near you!",
  "places": [
    {
      "name": "Café Name",
      "address": "123 Main St, Brooklyn, NY",
      "walk_time": "5 min",
      "distance": "0.3 mi",
      "rating": 4.5,
      "location": {
        "lat": 40.693,
        "lng": -73.985
      },
      "photo_url": "https://maps.googleapis.com/...",
      "type": "place",
      "source": "google_places"
    }
  ],
  "vibe": "chill_cafes",
  "weather": {
    "temp_f": 72,
    "desc": "clear sky",
    "icon": "01d"
  },
  "debug_vibe": "chill_cafes",
  "latency": 2.34
}
```

**Error Responses**:
- `400`: Missing 'message' field
- `429`: Rate limit exceeded
- `500`: Internal server error

**Rate Limit**: 10 requests per minute

**Notes**:
- Conversation context is maintained per user (if authenticated) or session
- Location is optional but improves recommendations
- Response includes AI-generated reply and ranked recommendations

---

#### Get Quick Recommendations

Get quick recommendations by category.

**Endpoint**: `GET /api/quick_recs`

**Query Parameters**:
- `category` (optional): `quick_bites`, `chill_cafes`, `events`, `explore` (default: `explore`)
- `limit` (optional): Number of results (default: 10)

**Example**:
```
GET /api/quick_recs?category=chill_cafes&limit=5
```

**Response** (200 OK):
```json
{
  "category": "chill_cafes",
  "places": [
    {
      "name": "Café Name",
      "address": "123 Main St",
      "walk_time": "7 min",
      "distance": "0.4 mi",
      "rating": 4.2,
      "location": {
        "lat": 40.693,
        "lng": -73.985
      },
      "photo_url": "https://..."
    }
  ]
}
```

**Error Responses**:
- `500`: Internal server error

**Rate Limit**: 30 requests per minute

---

### Events

#### Get NYU Engage Events

Get upcoming NYU Engage events.

**Endpoint**: `GET /api/nyu_engage_events`

**Query Parameters**:
- `days` (optional): Number of days ahead to fetch (default: 7)

**Example**:
```
GET /api/nyu_engage_events?days=14
```

**Response** (200 OK):
```json
{
  "engage_events": [
    {
      "event_name": "Jazz Night",
      "event_start": "2025-01-15T20:00:00",
      "latitude": 40.693,
      "longitude": -73.985,
      "address": "123 Main St, Brooklyn, NY"
    }
  ]
}
```

**Error Responses**:
- `500`: Internal server error

---

### Directions

#### Get Walking Directions

Get walking directions from NYU Tandon (2 MetroTech) to a destination.

**Endpoint**: `GET /api/directions`

**Query Parameters**:
- `lat` (required): Destination latitude
- `lng` (required): Destination longitude

**Example**:
```
GET /api/directions?lat=40.6942&lng=-73.9866
```

**Response** (200 OK):
```json
{
  "duration_text": "7 min",
  "distance_text": "0.4 mi",
  "maps_link": "https://www.google.com/maps/dir/?api=1&origin=40.693393,-73.98555&destination=40.6942,-73.9866&travelmode=walking"
}
```

**Error Responses**:
- `400`: Invalid coordinates
- `500`: Directions failed

**Notes**:
- Origin is fixed at NYU Tandon (2 MetroTech: 40.693393, -73.98555)
- Returns walking directions only

---

### Health Check

#### Health Check

Check application health and connectivity.

**Endpoint**: `GET /health`

**Response** (200 OK):
```json
{
  "status": "ok",
  "database": "connected",
  "redis": "connected"
}
```

**Response** (503 Service Unavailable):
```json
{
  "status": "ok",
  "database": "disconnected",
  "redis": "connected"
}
```

**Status Values**:
- `ok`: Application is running
- `connected`: Component is connected and operational
- `disconnected`: Component connection failed
- `not_configured`: Component not configured (Redis optional)

**Notes**:
- Used by DigitalOcean App Platform for health checks
- Database connectivity is required
- Redis connectivity is optional but recommended

---

## Data Models

### User

```typescript
interface User {
  id: number;
  email: string;
  preferences: {
    vibes: Record<string, number>;
    distance_limit_minutes: number;
    indoor_outdoor: "indoor" | "outdoor" | "either";
  };
  settings: {
    notifications_enabled: boolean;
    calendar_integration_enabled: boolean;
  };
  recent_activity: Array<{
    type: string;
    place_id?: string;
    name?: string;
    vibe?: string;
    score?: number;
    timestamp: string;
  }>;
}
```

### Place

```typescript
interface Place {
  name: string;
  address: string;
  walk_time: string;
  distance: string;
  rating: number;
  location: {
    lat: number;
    lng: number;
  };
  photo_url?: string;
  type: "place" | "event";
  source: "google_places" | "nyu_engage" | "other";
}
```

### Chat Response

```typescript
interface ChatResponse {
  reply: string;
  places: Place[];
  vibe?: string;
  weather?: {
    temp_f: number;
    desc: string;
    icon: string;
  };
  debug_vibe?: string;
  latency: number;
}
```

## Examples

### cURL Examples

**Sign Up**:
```bash
curl -X POST https://your-app.ondigitalocean.app/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"secure123"}'
```

**Login**:
```bash
curl -X POST https://your-app.ondigitalocean.app/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"secure123"}'
```

**Get User Profile**:
```bash
curl -X GET https://your-app.ondigitalocean.app/api/user/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Send Chat Message**:
```bash
curl -X POST https://your-app.ondigitalocean.app/api/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"message":"I want coffee","latitude":40.693393,"longitude":-73.98555}'
```

### JavaScript/TypeScript Examples

**Fetch Chat Response**:
```typescript
const response = await fetch('https://your-app.ondigitalocean.app/api/chat', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  },
  body: JSON.stringify({
    message: 'I want coffee',
    latitude: 40.693393,
    longitude: -73.98555
  })
});

const data = await response.json();
```

**Get Quick Recommendations**:
```typescript
const response = await fetch(
  'https://your-app.ondigitalocean.app/api/quick_recs?category=chill_cafes&limit=5'
);
const data = await response.json();
```

## Versioning

Currently, the API does not use versioning. All endpoints are under `/api/`.

Future versions may use `/api/v1/`, `/api/v2/`, etc.

## Support

For issues or questions:
1. Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. Review application logs
3. Check health endpoint status

