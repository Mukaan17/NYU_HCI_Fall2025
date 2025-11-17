# VioletVibes Demo - Quick Start

## 🚀 Quick Setup (5 minutes)

### Mobile App
```bash
cd mobile
npm install
npx expo run:ios
# In another terminal:
npx expo start --clear
```

### Backend Server
```bash
cd server
source ../hci/bin/activate  # or create new venv
pip install -r requirements.txt
npm install  # for Puppeteer
# Create .env with API keys
python app.py
```

## 🎯 Demo Flow Checklist

- [ ] **Welcome Screen** - Show brand identity and onboarding
- [ ] **Permissions** - Grant Location, Calendar, Notifications
- [ ] **Dashboard** - Context badges, Quick Actions, Recommendations
  - [ ] Wait 3 seconds for notification modal to appear
- [ ] **Chat** - Send message, see AI response, view recommendations
- [ ] **Map** - View location, tap pins, see bottom sheet cards
- [ ] **Safety** - Test emergency buttons (NYU Public Safety, 911)

## 🧪 Test Backend APIs

```bash
# Events API
curl http://localhost:5001/api/events

# Chat API
curl -X POST http://localhost:5001/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Find quiet café"}'

# Or use the test script:
cd server
./test_api.sh
```

## 📱 Enable Real API in Chat

Edit `mobile/screens/Chat.js`:
- Set `USE_API = true`
- Update `API_BASE_URL`:
  - Simulator: `'http://localhost:5001'`
  - Device: `'http://YOUR_IP:5001'` (find IP with `ifconfig` or `ipconfig`)

## 🎬 Demo Narrative Points

1. **Context Awareness**: "Violet reads your schedule, weather, and location"
2. **Smart Notifications**: "Detects free time and suggests activities"
3. **Conversational AI**: "Chat naturally to find what you need"
4. **Visual Discovery**: "Map shows all options with walking times"
5. **Safety First**: "Quick access to emergency contacts"

## ⚠️ Troubleshooting

- **App won't build**: `rm -rf node_modules && npm install`
- **API connection fails**: Check Flask is running on `0.0.0.0:5001` (port 5001 because 5000 is often used by AirPlay Receiver)
- **CORS errors**: Already configured in `app.py`
- **Notification not showing**: Wait 3 seconds on Dashboard

## 📋 Key Features to Highlight

✅ Glassmorphic NYU violet design
✅ Context-aware recommendations
✅ Multi-source intelligence (Weather, Places, Events, Directions)
✅ Campus-specific AI personality
✅ Safety-first approach

