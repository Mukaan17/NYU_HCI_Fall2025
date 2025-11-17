# VioletVibes Demo Setup Guide

This guide will help you set up and run the VioletVibes demo.

## Prerequisites

- Node.js 18 or 20
- npm (not yarn/pnpm)
- Python 3.13+ (or compatible version)
- Xcode (for iOS development)
- API Keys:
  - `GEMINI_API_KEY` - Google Gemini API key
  - `OPENWEATHER_API_KEY` - OpenWeatherMap API key
  - `GOOGLE_PLACES_API_KEY` - Google Places API key

## Step 1: Mobile App Setup

1. Navigate to the mobile directory:
   ```bash
   cd mobile
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Build and run the iOS app:
   ```bash
   npx expo run:ios
   ```
   (First time takes ~10-20 minutes)

4. Start Metro bundler:
   ```bash
   npx expo start --clear
   ```

## Step 2: Backend Server Setup

1. Navigate to the server directory:
   ```bash
   cd server
   ```

2. Activate Python virtual environment (if using the one in `hci/`):
   ```bash
   source ../hci/bin/activate
   ```
   Or create a new one:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

3. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Set up environment variables:
   Create a `.env` file in the `server/` directory with:
   ```
   GEMINI_API_KEY=your_gemini_api_key_here
   OPENWEATHER_API_KEY=your_openweather_api_key_here
   GOOGLE_PLACES_API_KEY=your_google_places_api_key_here
   ```

5. Install Node.js dependencies for Puppeteer (for BPL scraping):
   ```bash
   npm install
   ```

6. Start the Flask server:
   ```bash
   python app.py
   ```
   The server will run on `http://localhost:5001` (port 5001 is used because 5000 is often occupied by AirPlay Receiver on macOS)

## Step 3: Connect Mobile App to Backend (Optional)

To enable real API calls in the Chat screen:

1. Open `mobile/screens/Chat.js`
2. Update the `API_BASE_URL` constant:
   - For iOS Simulator: `'http://localhost:5001'`
   - For physical device: Use your computer's local IP (e.g., `'http://192.168.1.100:5001'`)
3. Set `USE_API = true` to enable real API calls

## Step 4: Demo Flow

### Onboarding
1. Launch the app - it will start at the Welcome screen
2. Tap "Let's Go" to proceed to Permissions
3. Grant Location, Calendar, and Notification permissions
4. App transitions to the main Dashboard

### Dashboard
- View context badges (weather, schedule, mood)
- Try Quick Actions (Find Food, Events, Cafés, Explore)
- Browse Top Recommendations
- **Notification Demo**: After 3 seconds, a notification modal appears showing a calendar-based suggestion

### Chat
- Tap the Chat tab
- Type a message like "Find quiet café" or "What's happening tonight?"
- See AI responses (simulated by default, real API if enabled)
- Scroll through recommendation cards below

### Map
- Tap the Map tab
- View Downtown Brooklyn area centered on NYU Tandon (2 MetroTech Center)
- See location pins for nearby places
- Tap pins to see recommendation cards in the bottom sheet

### Safety
- Tap the Safety tab
- Test emergency buttons (NYU Public Safety, 911)
- View safety features (Share Location, Safe Route Home)

## Step 5: Backend API Testing

Test the Flask endpoints directly:

### Events API
```bash
curl http://localhost:5001/api/events
```
Returns JSON with events from TimeOut NYC, Downtown Brooklyn, and Brooklyn Public Library.

### Chat API
```bash
curl -X POST http://localhost:5001/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Find quiet café"}'
```
Returns AI-generated response with nearby places and walking directions.

## Demo Narrative

1. **Context Awareness**: Show how VioletVibes reads schedule, weather, and location
2. **Smart Notifications**: Notification appears when free time is detected
3. **Conversational Interface**: Chat with Violet to find personalized recommendations
4. **Visual Discovery**: Map view shows all nearby options with walking times
5. **Safety First**: Quick access to emergency contacts and safe routes

## Troubleshooting

### Mobile App Issues
- If bundling errors occur: `rm -rf node_modules && npm install && npx expo run:ios`
- If simulator doesn't open: Press `i` in the Metro bundler terminal

### Backend Issues
- Ensure all API keys are set in `.env`
- Check that port 5001 is not in use (port 5000 is often used by AirPlay Receiver on macOS)
- Verify CORS is enabled (already configured in `app.py`)

### API Connection Issues
- For physical devices, ensure phone and computer are on the same WiFi network
- Check firewall settings allow connections on port 5001
- Verify Flask server is running and accessible on port 5001

## Key Features Demonstrated

✅ Onboarding flow with permission requests
✅ Context-aware dashboard with weather/schedule/mood
✅ Smart notification system (demo modal)
✅ AI chat concierge interface
✅ Interactive map with location pins
✅ Safety center with emergency contacts
✅ Glassmorphic design with NYU violet branding
✅ Backend API integration (Flask + Gemini + Google APIs)

