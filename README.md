🌙 VioletVibes – NYU Nightlife & Events Discovery App

VioletVibes is your personal NYU nightlife and campus discovery concierge — powered by SwiftUI, Expo/React Native, Python Flask, Google APIs, and the Gemini AI model.
It helps NYU students instantly find the best places, events, vibes, and routes, with a friendly conversational interface.

🏗️ Project Architecture

VioletVibes is a multi-platform, AI-powered system with three major components:

📱 Native iOS App — Swift 6.2, SwiftUI, MapKit, MVVM

📱 React Native / Expo App — Expo SDK 54, TypeScript

🖥️ Python Flask Backend — Gemini LLM, Google Places, Directions, Weather, NYC Events

Everything works together via a unified API layer.

📱 iOS Native App Architecture (Primary)

The iOS app uses MVVM, Swift 6.2’s @Observable model, and async/await concurrency.

Technology Stack

Language: Swift 6.2

UI Framework: SwiftUI

State Management: @Observable macro

Concurrency: async/await, actors

Design: iOS 18 Liquid Glass aesthetic

Map: MapKit + MapCameraPosition

Networking: URLSession + structured concurrency

📁 Project Structure (ios-app/)
ios-app/VioletVibes/
├── VioletVibesApp.swift          
├── Models/
│   ├── UserAccount.swift        
│   ├── UserPreferences.swift    
│   ├── Recommendation.swift     
│   ├── ChatMessage.swift        
│   ├── Weather.swift            
│   └── ...
│
├── ViewModels/
│   ├── OnboardingViewModel.swift
│   ├── ChatViewModel.swift      
│   ├── DashboardViewModel.swift 
│   ├── MapViewModel.swift       
│   ├── PlaceViewModel.swift     
│   ├── LocationManager.swift    
│   └── WeatherManager.swift     
│
├── Services/
│   ├── APIService.swift           
│   ├── LocationService.swift      
│   ├── StorageService.swift       
│   ├── WeatherService.swift       
│   ├── CalendarService.swift      
│   ├── ContactsService.swift      
│   ├── NotificationService.swift  
│   └── ...
│
├── Views/
│   ├── Onboarding/               
│   ├── Dashboard/                
│   ├── Chat/                     
│   ├── Map/                      
│   ├── Quick/                    
│   ├── Safety/                   
│   ├── Settings/                 
│   └── MainTabView.swift         
│
├── Components/
│   ├── InputField.swift          
│   ├── PrimaryButton.swift       
│   ├── RecommendationCard.swift  
│   └── LocationPickerView.swift  
│
├── Resources/
│   └── Theme.swift               
│
└── Utilities/
    ├── Extensions/               
    ├── Helpers/                  
    └── ViewModifiers/

⚙️ Architecture Patterns
1. MVVM with @Observable

ViewModels store business logic & state

Views remain stateless

Auto UI updates with Swift 6.2 observation system

2. Service Layer

Encapsulated logic:

API fetchers

location, storage, calendar

Weather / preferences / notifications

3. Dependency Injection

SwiftUI’s @Environment distributes shared state.

4. Structured Concurrency

async/await

Task

actors for thread safety

5. Navigation Flow
RootView
→ Welcome
→ Permissions
→ Login/Sign-up
→ Onboarding Survey
→ MainTabView (Dashboard, Chat, Map, Safety, Settings)

📱 React Native / Expo App (Secondary)

Cross-platform (iOS + Android) implementation via Expo SDK 54.

Technology Stack

React Native 0.81

Expo Router 3.5 (file-based routing)

TypeScript

React Context for state

Expo modules for sensors, maps, etc.

📁 Project Structure (mobile/)
mobile/
├── app/
│   ├── _layout.tsx
│   ├── welcome.tsx
│   ├── permissions.tsx
│   ├── (tabs)/
│   │   ├── dashboard.tsx
│   │   ├── chat.tsx
│   │   ├── map.tsx
│   │   └── safety.tsx
│   └── quick/[category].tsx
│
├── components/
├── context/
│   ├── ChatContext.tsx
│   └── PlaceContext.tsx
│
├── hooks/
│   └── useLocation.ts
│
├── constants/theme.ts
└── utils/

🖥️ Backend API Architecture (Python Flask)

This is where the core intelligence lives:

Gemini-powered chat

Google Places search

Walking routes

Weather

NYC permitted events

Embedding-based scoring

Conversation memory

Technology Stack

Flask (REST API)

Google Generative AI (Gemini 2.5 Flash)

Google Places API

Google Directions API

OpenWeatherMap

NYC Open Data

Python 3.10+

📁 Project Structure (server/)
server/
├── app.py
│
├── services/
│   ├── recommendation/
│   │   ├── driver.py
│   │   ├── intent.py
│   │   ├── llm_reply.py
│   │   ├── scoring.py
│   │   ├── context.py
│   │   ├── places.py
│   │   ├── events.py
│   │   ├── event_filter.py
│   │   ├── event_normalizer.py
│   │   └── ...
│   ├── places_service.py
│   ├── directions_service.py
│   ├── weather_service.py
│   ├── popularity_service.py
│   ├── nyc_events_service.py
│   └── vibes.py
│
├── utils/
│   ├── cache.py
│   ├── chat_memory.py
│   ├── helpers.py
│   └── ...
│
├── static/events.json
└── requirements.txt

🧠 Backend Flow (End-to-End)
1. Intent Classification

Determines the user’s purpose:

new recommendation

follow-up details

alternative options

general chatting

2. Vibe Classification

Uses message → vibe → Google place types.

3. Google Places Search

Nearby + open_now filtering.

4. Walking Route

Via Google Directions.

5. Busyness Score

Heuristic + ratings.

6. Events

Fetched from:

NYC Permitted Events API

Static cached files

7. Normalization

Places & events → unified card format.

8. Scoring

Gemini embedding comparison:

query relevance

vibe match

popularity/rating

distance/walk time

busyness

9. Conversation Memory

Tracks:

last_places

last_results

last_query

Enables natural follow-ups:

“What is Wiki Wiki?”
“Tell me more about #2”
“Show me similar spots”

10. LLM Response

Gemini writes:

place descriptions

comparison summaries

follow-up explanations

Never invents places.

🔥 API Endpoints
POST /api/chat

Returns reply + place cards + weather.

GET /api/quick_recs?category=<>&limit=10

Used by Dashboard Quick Actions.

GET /api/directions?lat=&lng=

Returns:

polyline

walk time

distance

step-by-step directions

GET /api/events

NYC permitted events near Tandon.

GET /api/top_recommendations

Main dashboard recommendations.

GET /health

Health check.

⚙️ Backend Configuration

Environment variables:

GOOGLE_API_KEY=
OPENWEATHER_API_KEY=
GEMINI_API_KEY=
FLASK_ENV=development

▶️ Running the Backend
cd server
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python app.py


Local API root:

http://127.0.0.1:5001

🚀 React Native Setup Guide (Important)
Requirements

Node 18 or 20

npm (NOT yarn)

Xcode installed

iOS simulator installed

Install dependencies
npm install

Build the iOS dev client (must do once)
npx expo run:ios

Start app
npx expo start --clear

If you break dependencies:
rm -rf node_modules
rm package-lock.json
npm install
npx expo run:ios
npx expo start --clear

🎨 iOS Development Guidelines

Use Swift 6.2 features

Follow MVVM strictly

UI materials must use .regularMaterial, .ultraThinMaterial

Throttle location updates

Use actors for thread-safe services

Use @MainActor for UI

🛠 Backend Development Guidelines

All APIs RESTful

Clear error responses

Avoid unnecessary external calls (use caching)

Never invent LLM facts

Always normalize place/event data

Keep scoring deterministic

📚 Additional Docs

ios-app/SETUP_GUIDE.md

ios-app/SERVER_CONNECTION.md

ios-app/TROUBLESHOOTING.md
