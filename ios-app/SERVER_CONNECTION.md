# How the iOS App Connects to the Server

## Overview

The iOS app uses `APIService` to communicate with your Flask backend server. The server remains **completely unchanged** - all endpoints work exactly as before.

## Server URL Configuration

The app determines the server URL in this priority order:

1. **Environment Variable** (highest priority)
   - Set `API_URL` in Xcode scheme environment variables
   - Used for development/testing

2. **Config.plist File**
   - Create `Config.plist` in the Xcode project
   - Add `API_URL` key with your server URL

3. **Default** (fallback)
   - Uses `http://localhost:5000` if nothing else is configured

### Example Config.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>API_URL</key>
    <string>http://localhost:5000</string>
    <!-- Or use your server's IP/domain -->
    <!-- <string>http://192.168.1.100:5000</string> -->
    <!-- <string>https://your-server.com</string> -->
</dict>
</plist>
```

## API Endpoints Used

The iOS app calls these endpoints from your Flask server:

### 1. Chat Endpoint
**Server:** `POST /api/chat`  
**iOS:** `APIService.sendChatMessage()`

**Request:**
```json
{
  "message": "I want coffee",
  "latitude": 40.693393,  // optional
  "longitude": -73.98555   // optional
}
```

**Response:**
```json
{
  "reply": "Here are some great coffee spots...",
  "places": [
    {
      "name": "Café Name",
      "address": "123 Main St",
      "walk_time": "5 min",
      "distance": "0.3 mi",
      "rating": 4.5,
      "location": {"lat": 40.693, "lng": -73.985},
      "photo_url": "https://..."
    }
  ],
  "vibe": "chill_cafes",
  "weather": {...}
}
```

**Used in:** `ChatView` → `ChatViewModel.sendMessage()`

---

### 2. Quick Recommendations
**Server:** `GET /api/quick_recs?category={category}&limit={limit}`  
**iOS:** `APIService.getQuickRecommendations()`

**Request:**
- `category`: `quick_bites`, `chill_cafes`, `events`, or `explore`
- `limit`: Number of results (default: 10)

**Response:**
```json
{
  "category": "quick_bites",
  "places": [
    {
      "name": "Restaurant Name",
      "address": "123 Main St",
      "walk_time": "7 min",
      "distance": "0.4 mi",
      "rating": 4.2,
      "location": {"lat": 40.693, "lng": -73.985},
      "photo_url": "https://..."
    }
  ]
}
```

**Used in:** `QuickResultsView` when user taps a quick action card

---

### 3. Directions
**Server:** `GET /api/directions?lat={lat}&lng={lng}`  
**iOS:** `APIService.getDirections()`

**Request:**
- `lat`: Destination latitude
- `lng`: Destination longitude
- Origin is hardcoded to 2 MetroTech (40.693393, -73.98555)

**Response:**
```json
{
  "distance_text": "0.4 mi",
  "duration_text": "7 min",
  "maps_link": "https://www.google.com/maps/dir/...",
  "polyline": [[40.693, -73.985], [40.694, -73.986], ...]
}
```

**Used in:** `MapView` → `MapViewModel.fetchRoute()` when a place is selected

---

### 4. Events
**Server:** `GET /api/events`  
**iOS:** `APIService.getEvents()`

**Response:**
```json
{
  "nyc_permitted": [
    {
      "event_name": "Jazz Night",
      "event_start": "2025-01-15T20:00:00",
      "latitude": 40.693,
      "longitude": -73.985,
      "address": "123 Main St"
    }
  ]
}
```

**Used in:** Can be called from any view that needs event data

---

## Network Configuration

### For Simulator (localhost)

The app can connect to `localhost:5000` when running on the iOS Simulator if:
- Your Flask server is running on your Mac
- Server is bound to `0.0.0.0` (which it is: `app.run(host="0.0.0.0", port=5000)`)
- No additional configuration needed

### For Physical Device

When testing on a physical iPhone/iPad:

1. **Find your Mac's IP address:**
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
   Example: `192.168.1.100`

2. **Update Config.plist:**
   ```xml
   <key>API_URL</key>
   <string>http://192.168.1.100:5000</string>
   ```

3. **Ensure Mac and iPhone are on same WiFi network**

4. **Update Info.plist App Transport Security** (already configured):
   - Allows HTTP connections for development
   - For production, use HTTPS

### For Production/Deployment

1. **Use HTTPS:**
   ```xml
   <key>API_URL</key>
   <string>https://your-production-server.com</string>
   ```

2. **Update Info.plist** to remove localhost exception
3. **Ensure server has valid SSL certificate**

## Code Flow Example

Here's how a chat message flows from UI to server:

```
User types message in ChatView
    ↓
ChatView calls ChatViewModel.sendMessage()
    ↓
ChatViewModel calls APIService.sendChatMessage()
    ↓
APIService creates HTTP POST request to {baseURL}/api/chat
    ↓
URLSession sends request to Flask server
    ↓
Flask server processes via /api/chat route
    ↓
Server returns JSON response
    ↓
APIService decodes response into ChatAPIResponse
    ↓
ChatViewModel updates @Published messages array
    ↓
ChatView automatically updates UI (SwiftUI reactive)
```

## Error Handling

The app handles these error cases:

- **Invalid URL**: Server URL not configured properly
- **Invalid Response**: Server returned non-200 status
- **Decoding Error**: Server response doesn't match expected format
- **Server Error**: Server returned error message in JSON

All errors are caught and displayed to the user via UI.

## Testing the Connection

1. **Start your Flask server:**
   ```bash
   cd server
   python app.py
   ```

2. **Verify server is running:**
   ```bash
   curl http://localhost:5000/health
   # Should return: {"status":"ok"}
   ```

3. **Run the iOS app** in simulator or device

4. **Test chat functionality** - send a message and verify it reaches the server

## CORS Configuration

Your Flask server already has CORS enabled:
```python
CORS(app, resources={r"/api/*": {"origins": "*"}})
```

This allows the iOS app to make requests from any origin. For production, you may want to restrict this.

## Summary

- ✅ Server code remains **100% unchanged**
- ✅ All existing endpoints work as-is
- ✅ iOS app uses standard HTTP/JSON communication
- ✅ Configuration via Config.plist or environment variables
- ✅ Works with localhost (simulator) or IP address (device)
- ✅ Error handling built-in
- ✅ Async/await for non-blocking network calls

