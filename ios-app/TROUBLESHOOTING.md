# Troubleshooting Guide

## Network Connection Errors

If you're seeing errors like "A server with the specified hostname could not be found":

### 1. Check if Server is Running

```bash
cd /Users/mukaan/Classes/NYU_HCI_Fall2025/server
python app.py
```

You should see: `Running on http://0.0.0.0:5001`

### 2. Configure API URL

The app needs to know where your server is:

**Option A: Create Config.plist (Recommended)**

1. In Xcode, right-click `VioletVibes` folder → New File → Property List
2. Name it `Config.plist`
3. Add this content:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>API_URL</key>
    <string>http://localhost:5001</string>
</dict>
</plist>
```

**For Physical Device:**
Replace `localhost` with your Mac's IP address:
- Find your Mac's IP: System Settings → Network → Wi-Fi → Details
- Use: `http://192.168.1.XXX:5001` (replace XXX with your IP)

**Option B: Set Environment Variable**

In Xcode: Edit Scheme → Run → Arguments → Environment Variables
- Name: `API_URL`
- Value: `http://localhost:5001` (or your Mac's IP for physical device)

### 3. Test Server Connection

```bash
curl http://localhost:5001/health
```

Should return: `{"status": "ok"}`

## Black Screen Issues

If the dashboard shows a black screen:

1. **Check Console Logs**: Look for specific errors
2. **Verify Location Permission**: The app needs location to load weather
3. **Check Network**: API failures won't crash the app, but content may not load

## Common Issues

### Issue: "Failed to locate resource named 'default.csv'"
- **Solution**: This is a harmless warning from MapKit. Can be ignored.

### Issue: "CAMetalLayer ignoring invalid setDrawableSize"
- **Solution**: This is a simulator rendering issue. Try on a physical device or different simulator.

### Issue: Network errors on physical device
- **Solution**: Use your Mac's IP address instead of `localhost` in Config.plist

## Quick Fix Checklist

- [ ] Server is running on port 5001
- [ ] Config.plist exists with correct API_URL
- [ ] For physical device: Using Mac's IP address, not localhost
- [ ] Location permission granted
- [ ] Clean build: Product → Clean Build Folder (Cmd+Shift+K)

