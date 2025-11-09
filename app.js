// Access Firebase modules exposed globally by index.html
const { 
    initializeApp, getAuth, signInAnonymously, signInWithCustomToken, onAuthStateChanged, 
    getFirestore, collection, addDoc, serverTimestamp, setLogLevel, query, orderBy, limit, onSnapshot 
} = window.firebase;

// --- GLOBAL FIREBASE/APP VARIABLES (MANDATORY USE) ---
const appId = typeof __app_id !== 'undefined' ? __app_id : 'default-hci-concierge';
const firebaseConfig = typeof __firebase_config !== 'undefined' ? JSON.parse(__firebase_config) : {};
const initialAuthToken = typeof __initial_auth_token !== 'undefined' ? __initial_auth_token : null;

// Set log level for debugging
setLogLevel('error');

// --- API & CONFIGURATION ---
const GEMINI_API_URL = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=`;
// NEW: Define the local Flask backend endpoint
const FLASK_API_URL = '/api/status'; 

// PROACTIVE EVENT MOCK (client-side for display logic)
const PROACTIVE_EVENT = { 
    name: "Sephora Sample Sale", 
    location: "Dekalb Market Hall", 
    time: 1030, // Corresponds to mock time in app.py
    end: 1100,
    message: "Hey, there's a **Sephora sample sale** going on right now at the Dekalb Market Hall! It's a quick 5-minute dash."
};

// --- STATE & INITIALIZATION ---
let db, auth;
let userId = 'loading'; // Will be set after auth
let isAuthReady = false;

// DOM Element references
const chatMessagesEl = document.getElementById('chat-messages');
const chatInputEl = document.getElementById('chat-input');
const chatFormEl = document.getElementById('chat-form');
const downtimeCardEl = document.getElementById('downtime-card');
const recommendationListEl = document.getElementById('recommendation-list');

function initFirebase() {
    try {
        const app = initializeApp(firebaseConfig);
        db = getFirestore(app);
        auth = getAuth(app);

        onAuthStateChanged(auth, async (user) => {
            if (user) {
                userId = user.uid;
            } else {
                await signInAnonymously(auth);
                userId = auth.currentUser.uid;
            }
            isAuthReady = true;
            document.getElementById('user-id-display').textContent = `User ID: ${userId.substring(0, 8)}...`;
            setupRealTimeListeners();
            // Initial call to fetch status from the new Flask backend
            fetchConciergeStatus(); 
        });

        if (initialAuthToken) {
            signInWithCustomToken(auth, initialAuthToken).catch(e => {
                console.error("Custom token sign-in failed, falling back to anonymous:", e);
                signInAnonymously(auth);
            });
        }
    } catch (e) {
        console.error("Firebase initialization failed:", e);
        document.getElementById('user-id-display').textContent = `Firebase Error: Check console.`;
    }
}

// --- FIRESTORE FUNCTIONS (UNCHANGED) ---

const getChatCollectionRef = () => {
    // Path: /artifacts/{appId}/users/{userId}/dumbo_concierge_chat
    return collection(db, `artifacts/${appId}/users/${userId}/dumbo_concierge_chat`);
};

function setupRealTimeListeners() {
    if (!isAuthReady || !db) return;

    // Listen for new chat messages
    const q = query(getChatCollectionRef(), orderBy("timestamp", "desc"), limit(50));
    onSnapshot(q, (snapshot) => {
        let messages = [];
        snapshot.forEach(doc => {
            messages.push(doc.data());
        });
        displayChatMessages(messages.reverse()); // Reverse to show chronologically
    }, (error) => {
        console.error("Error setting up chat listener:", error);
    });
}

async function sendMessage(text, role, sources = []) {
    if (!isAuthReady) {
        console.error("Auth not ready. Cannot send message.");
        return;
    }
    try {
        await addDoc(getChatCollectionRef(), {
            text: text,
            role: role,
            timestamp: serverTimestamp(),
            sources: sources
        });
    } catch (e) {
        console.error("Error adding document: ", e);
    }
}

// --- NEW BACKEND COMMUNICATION FUNCTION ---

async function fetchConciergeStatus() {
    try {
        const response = await fetch(FLASK_API_URL);
        if (!response.ok) {
            throw new Error(`Server returned status: ${response.status}`);
        }
        const data = await response.json();
        
        // Use the data returned by the Flask server
        updateConciergeUI(data.status, data.recommendations);
        
    } catch (error) {
        console.error("Failed to fetch concierge status from Flask server:", error);
        downtimeCardEl.innerHTML = `
            <div class="p-4 bg-red-800 rounded-xl shadow-lg text-white">
                <p>⚠️ Error: Could not connect to backend server. Is Flask running?</p>
            </div>
        `;
        recommendationListEl.innerHTML = '';
    }
}

// --- UI & RECOMMENDATION LOGIC (UPDATED TO USE FLASK DATA) ---

function formatTime(time24) {
    const hours = Math.floor(time24 / 100);
    const minutes = time24 % 100;

    let period = hours >= 12 ? 'PM' : 'AM';
    let formattedHours = hours % 12;
    formattedHours = formattedHours ? formattedHours : 12; // the hour '0' should be '12'
    const formattedMinutes = minutes < 10 ? '0' + minutes : minutes;
    
    return `${formattedHours}:${formattedMinutes} ${period}`;
}

function updateConciergeUI(status, recommendations) {
    let downtimeContent;
    let isProactiveAlert = false;
    
    // Check for proactive alert based on Flask's mocked current time
    if (status.is_downtime && status.current_time >= PROACTIVE_EVENT.time && status.current_time < PROACTIVE_EVENT.end) {
        isProactiveAlert = true;
        downtimeContent = `
            <div class="p-6 bg-red-600 rounded-2xl shadow-2xl border-4 border-red-300 text-white animate-pulse">
                <div class="flex items-center justify-between mb-2">
                    <h3 class="text-2xl font-black flex items-center">
                        <svg class="w-8 h-8 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                        HIGH-PRIORITY ALERT
                    </h3>
                    <span class="text-xs font-semibold bg-white text-red-600 px-2 py-1 rounded-full">LIMITED TIME</span>
                </div>
                <p class="text-lg font-semibold mt-1 leading-snug">${PROACTIVE_EVENT.message}</p>
                <button onclick="console.log('Directions clicked')" class="mt-4 text-sm font-bold w-full px-4 py-2 bg-white text-red-600 rounded-lg hover:bg-gray-100 transition shadow-lg">
                    Get Directions to ${PROACTIVE_EVENT.location}
                </button>
            </div>
        `;
    } else {
        // Display Standard Status Card
        const nextCommitmentTime = formatTime(status.until);
        const currentDisplayedTime = formatTime(status.current_time);
        
        downtimeContent = `
            <div class="p-4 bg-gray-700 rounded-xl shadow-lg border-2 ${status.is_downtime ? 'border-green-400' : 'border-red-400'}">
                <h3 class="text-xl font-bold mb-1 flex items-center text-white">
                    <svg class="w-6 h-6 mr-2 ${status.is_downtime ? 'text-green-400' : 'text-red-400'}" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                    ${status.is_downtime ? 'Downtime Detected!' : 'Currently Busy'}
                </h3>
                <p class="text-sm text-gray-300">
                    ${status.is_downtime 
                        ? `You are near **${status.location}**. Your next commitment is at ${nextCommitmentTime}.` 
                        : `You are in **${status.event}** (${status.location}) until ${nextCommitmentTime}.`}
                </p>
                <p class="text-xs mt-2 text-gray-400">Mock Time (From Server): ${currentDisplayedTime}</p>
            </div>
        `;
    }

    downtimeCardEl.innerHTML = downtimeContent;

    // Update Recommendations based on downtime
    if (status.is_downtime && !isProactiveAlert) {
        displayRecommendations(recommendations);
    } else if (!status.is_downtime) {
        recommendationListEl.innerHTML = `
            <div class="p-4 text-center text-gray-400 bg-gray-700 rounded-xl shadow-md">
                You're currently in class (${status.event}). Hang in there! No immediate recommendations.
            </div>
        `;
    } else if (isProactiveAlert) {
        recommendationListEl.innerHTML = `
            <div class="p-4 text-center text-red-300 font-semibold bg-gray-700 rounded-xl shadow-md">
                Focus on the time-sensitive alert above!
            </div>
        `;
    }
}

function displayRecommendations(filteredLocations) {
    // This logic is simplified as the server now handles the filtering/ranking
    let html = '<p class="text-lg font-semibold mb-3 text-white flex items-center"><span class="mr-2 text-green-400 text-xl">✓</span> Context-Aware Suggestions (Live Busyness)</p>';

    if (filteredLocations.length === 0) {
        html += '<div class="p-4 text-center text-gray-400 bg-gray-700 rounded-xl shadow-md">No suitable recommendations found right now.</div>';
    } else {
        filteredLocations.forEach((loc, index) => {
            let busynessColor;
            if (loc.busyness === "Low") busynessColor = "text-green-400";
            else if (loc.busyness === "Medium") busynessColor = "text-yellow-400";
            else if (loc.busyness === "High") busynessColor = "text-red-400";
            else busynessColor = "text-gray-400";
    
            const busynessText = loc.busyness ? `<span class="${busynessColor} ml-2 font-bold">${loc.busyness} Busyness</span>` : '';
            
            html += `
                <li class="bg-gray-800 p-4 rounded-xl mb-3 flex items-center shadow-md transition hover:bg-gray-700 border-l-4 border-indigo-500">
                    <div class="flex-shrink-0 w-10 h-10 bg-indigo-600 rounded-full flex items-center justify-center text-white font-bold text-sm mr-4">
                        ${index + 1}
                    </div>
                    <div>
                        <p class="text-lg font-bold text-white">${loc.name} - ${loc.type} ${busynessText}</p>
                        <p class="text-sm text-gray-400">${loc.vibe}</p>
                        <p class="text-xs text-indigo-300 mt-1">
                            <svg class="w-3 h-3 inline-block mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.828 0l-4.243-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                            ${loc.walk} walk
                        </p>
                    </div>
                </li>
            `;
        });
    }
    
    recommendationListEl.innerHTML = `<ul class="list-none p-0">${html}</ul>`;
}

function displayChatMessages(messages) {
    chatMessagesEl.innerHTML = messages.map(msg => {
        const isUser = msg.role === 'user';
        let sourceHtml = '';
        if (msg.sources && msg.sources.length > 0) {
            sourceHtml = `<p class="text-xs text-gray-500 mt-2 italic">Sources: ${msg.sources.slice(0, 2).map(s => `<a href="${s.uri}" target="_blank" class="text-blue-400 hover:text-blue-300 truncate inline-block max-w-full">${s.title}</a>`).join(', ')}</p>`;
        }
        
        return `
            <div class="flex ${isUser ? 'justify-end' : 'justify-start'} mb-4">
                <div class="max-w-xs md:max-w-md lg:max-w-xl p-3 rounded-xl shadow-lg ${isUser ? 'bg-indigo-600 text-white rounded-br-none' : 'bg-gray-700 text-white rounded-tl-none'}">
                    <p class="text-sm">${msg.text}</p>
                    ${sourceHtml}
                </div>
            </div>
        `;
    }).join('');
    chatMessagesEl.scrollTop = chatMessagesEl.scrollHeight;
}

// --- GEMINI API CALL (KEPT CLIENT-SIDE FOR SANDBOX FUNCTIONALITY) ---

async function callGemini(userQuery) {
    const systemPrompt = "You are the DUMBO Concierge, a friendly, ultra-local assistant. Your goal is to suggest the absolute best 'next thing to do' in the DUMBO area of Brooklyn (near NYU Tandon/Brooklyn Tech Triangle). Keep responses concise (max 3 sentences) and focused on immediate activities, like food, coffee, short breaks, or nearby shops/parks. When appropriate, simulate checking local conditions (like busyness or short travel time) and always conclude by offering the next step (e.g., 'Want me to give you directions?'). For example, if asked for a chill drink spot, check 'busyness' and suggest 'Bill's Bar isn't too busy right now, want me to give you directions?'. Base suggestions on the DUMBO neighborhood.";
    
    const payload = {
        contents: [{ parts: [{ text: userQuery }] }],
        tools: [{ "google_search": {} }],
        systemInstruction: { parts: [{ text: systemPrompt }] },
    };
    
    let attempt = 0;
    const maxRetries = 3;
    
    while (attempt < maxRetries) {
        try {
            const response = await fetch(GEMINI_API_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);

            const result = await response.json();
            const candidate = result.candidates?.[0];

            if (candidate && candidate.content?.parts?.[0]?.text) {
                const text = candidate.content.parts[0].text;
                let sources = [];
                const groundingMetadata = candidate.groundingMetadata;

                if (groundingMetadata && groundingMetadata.groundingAttributions) {
                    sources = groundingMetadata.groundingAttributions
                        .map(attribution => ({
                            uri: attribution.web?.uri,
                            title: attribution.web?.title,
                        }))
                        .filter(source => source.uri && source.title);
                }
                return { text, sources };
            } else {
                throw new Error("Gemini response was empty or malformed.");
            }
        } catch (error) {
            attempt++;
            console.error(`Attempt ${attempt} failed: ${error.message}`);
            if (attempt < maxRetries) {
                const delay = Math.pow(2, attempt) * 1000; // Exponential backoff (1s, 2s, 4s)
                await new Promise(resolve => setTimeout(resolve, delay));
            } else {
                return { text: "I'm having trouble connecting to my service right now. Please try again in a moment.", sources: [] };
            }
        }
    }
}

// --- EVENT LISTENERS ---

chatFormEl.addEventListener('submit', async (e) => {
    e.preventDefault();
    const userQuery = chatInputEl.value.trim();
    if (!userQuery) return;

    // 1. Display user message
    sendMessage(userQuery, 'user');
    chatInputEl.value = '';

    // 2. Add loading indicator
    const loadingId = 'loading-' + Date.now();
    const loadingEl = document.createElement('div');
    loadingEl.id = loadingId;
    loadingEl.className = 'flex justify-start mb-4';
    loadingEl.innerHTML = `
        <div class="p-3 rounded-xl bg-gray-700 text-white rounded-tl-none animate-pulse">
            <p class="text-sm">Concierge is thinking...</p>
        </div>
    `;
    chatMessagesEl.appendChild(loadingEl);
    chatMessagesEl.scrollTop = chatMessagesEl.scrollHeight;

    // 3. Call Gemini API
    const { text: geminiResponse, sources } = await callGemini(userQuery);

    // 4. Remove loading indicator and send response to Firestore
    document.getElementById(loadingId)?.remove();
    await sendMessage(geminiResponse, 'assistant', sources);
});

// --- START APP ---
window.onload = function() {
    initFirebase();
    // Fetch status every minute
    setInterval(fetchConciergeStatus, 60000); 
};
