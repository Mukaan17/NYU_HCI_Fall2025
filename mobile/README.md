# VioletVibes Mobile App (React Native/Expo)

## Overview

React Native mobile application built with Expo for iOS and Android platforms.

## Backend Configuration

The app connects to the Flask backend API. Configure the backend URL using environment variables.

### Environment Variables

Create a `.env` file in the `mobile/` directory:

```bash
EXPO_PUBLIC_API_URL=https://your-app-name.ondigitalocean.app
```

**For Local Development:**
```bash
EXPO_PUBLIC_API_URL=http://localhost:5001
```

**For Production:**
```bash
EXPO_PUBLIC_API_URL=https://violetvibes-backend.ondigitalocean.app
```

### Files Using Backend URL

The following files use `EXPO_PUBLIC_API_URL`:

- `app/(tabs)/chat.tsx` - Chat API calls
- `app/(tabs)/map.tsx` - Directions API calls
- `app/quick/[category].tsx` - Quick recommendations API calls

### Setting Environment Variables

**Option 1: .env file (Recommended)**

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Update `.env` with your backend URL:
   ```
   EXPO_PUBLIC_API_URL=https://your-app-name.ondigitalocean.app
   ```

3. Restart Expo development server:
   ```bash
   npm start
   ```

**Option 2: Expo Config Plugin**

Environment variables can also be set in `app.json` using Expo's config plugins, but `.env` is simpler.

**Option 3: Build-time Configuration**

For production builds, set environment variables during build:
```bash
EXPO_PUBLIC_API_URL=https://your-app.ondigitalocean.app expo build
```

### Verifying Configuration

After setting the environment variable, verify it's loaded:

1. Check the app logs when it starts
2. Test an API call (e.g., send a chat message)
3. Check network requests in developer tools

## Development

### Prerequisites

- Node.js 18+
- Expo CLI
- iOS Simulator (for iOS) or Android Emulator (for Android)

### Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Configure backend URL (see above)

3. Start development server:
   ```bash
   npm start
   ```

4. Run on iOS:
   ```bash
   npm run ios
   ```

5. Run on Android:
   ```bash
   npm run android
   ```

## API Integration

The app makes API calls to the following endpoints:

- `POST /api/chat` - Send chat messages
- `GET /api/quick_recs` - Get quick recommendations
- `GET /api/directions` - Get walking directions
- `GET /api/nyu_engage_events` - Get events

All endpoints use the base URL from `EXPO_PUBLIC_API_URL`.

## Troubleshooting

### Backend Connection Issues

1. **Check Environment Variable**:
   - Verify `.env` file exists and has correct URL
   - Restart Expo server after changing `.env`

2. **Check Backend Status**:
   - Verify backend is running and accessible
   - Test backend health endpoint: `curl https://your-app.ondigitalocean.app/health`

3. **CORS Issues**:
   - Ensure backend CORS is configured for your frontend domain
   - Check `ALLOWED_ORIGINS` in backend configuration

4. **Network Issues**:
   - For localhost: Ensure device/simulator can reach your machine
   - For production: Verify HTTPS is working

### Common Errors

**"Network request failed"**:
- Backend URL incorrect or backend not running
- CORS not configured correctly
- Network connectivity issues

**"Invalid response"**:
- Backend returned error
- Check backend logs
- Verify API endpoint is correct

## Production Build

### iOS

1. Configure backend URL in `.env`
2. Build:
   ```bash
   expo build:ios
   ```

### Android

1. Configure backend URL in `.env`
2. Build:
   ```bash
   expo build:android
   ```

## Notes

- Environment variables prefixed with `EXPO_PUBLIC_` are available in the app
- Changes to `.env` require restarting Expo server
- For production, consider using Expo's environment-specific configs

