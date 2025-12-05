# Google Calendar OAuth Setup Guide

This document describes how to set up Google Calendar OAuth for the VioletVibes app.

## Backend Configuration

### 1. Google Cloud Console Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google Calendar API
4. Go to "Credentials" → "Create Credentials" → "OAuth 2.0 Client ID"
5. Configure OAuth consent screen:
   - User Type: External (or Internal for Google Workspace)
   - Scopes: `https://www.googleapis.com/auth/calendar.readonly`
6. Create OAuth 2.0 Client ID:
   - Application type: Web application
   - Authorized redirect URIs: 
     - For production: `https://your-backend-domain.com/api/calendar/oauth/callback`
     - For development: `http://localhost:5001/api/calendar/oauth/callback`
7. Save the Client ID and Client Secret

### 2. Environment Variables

Add these to your `.env` file:

```bash
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
GOOGLE_OAUTH_REDIRECT_URI=https://your-backend-domain.com/api/calendar/oauth/callback
```

For local development:
```bash
GOOGLE_OAUTH_REDIRECT_URI=http://localhost:5001/api/calendar/oauth/callback
```

### 3. OAuth Flow

1. **Authorization**: `GET /api/calendar/oauth/authorize` (requires JWT)
   - Returns `authorization_url` and `state`
   - Client opens this URL in a web browser

2. **Callback**: `GET /api/calendar/oauth/callback?code=...&state=...`
   - Google redirects here after user authorizes
   - Backend exchanges code for tokens
   - Stores refresh token in user's `google_refresh_token` field
   - Redirects to iOS app: `violetvibes://calendar-oauth?status=success`

3. **Unlink**: `POST /api/calendar/oauth/unlink` (requires JWT)
   - Removes Google Calendar connection

## iOS App Configuration

### 1. URL Scheme

The app is configured with URL scheme `violetvibes://` in `Info.plist`:
- Handles callbacks: `violetvibes://calendar-oauth?status=success`

### 2. OAuth Flow

1. User taps "Connect Google Calendar" in onboarding
2. App calls `GET /api/calendar/oauth/authorize` with JWT
3. App opens authorization URL in `ASWebAuthenticationSession`
4. User authorizes on Google
5. Google redirects to backend callback
6. Backend processes and redirects to `violetvibes://calendar-oauth?status=success`
7. iOS app intercepts the deep link and completes onboarding

## Testing

### Local Development

1. Use `http://localhost:5001/api/calendar/oauth/callback` as redirect URI
2. Ensure backend is accessible from the device/simulator
3. Test OAuth flow end-to-end

### Production

1. Use your production backend URL as redirect URI
2. Ensure HTTPS is enabled
3. Test with real Google accounts

## Troubleshooting

- **"Invalid redirect URI"**: Check that redirect URI in Google Console matches exactly
- **"No refresh token"**: Ensure `prompt='consent'` is used to force consent screen
- **Deep link not working**: Verify URL scheme is configured in Info.plist
- **Callback not intercepted**: Check that backend redirects to `violetvibes://` scheme
