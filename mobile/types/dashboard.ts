// mobile/types/dashboard.ts

export interface WeatherData {
  temp_f: number;
  desc: string;
  icon: string;
  error?: string;
}

export interface FreeTimeBlock {
  start: string; // ISO8601 date string
  end: string;   // ISO8601 date string
}

export interface SuggestionItem {
  name?: string;
  start?: string;  // ISO8601 for events
  location?: string;
  description?: string;
  address?: string;
  maps_link?: string;
  photo_url?: string;
}

export interface FreeTimeSuggestion {
  should_suggest: boolean;
  type: "event" | "place";
  suggestion: SuggestionItem;
  message: string;
}

export interface Recommendation {
  id: number;
  name: string;
  address?: string;
  walk_time?: string;
  distance?: string;
  rating?: number;
  location?: {
    lat: number;
    lng: number;
  };
  maps_link?: string;
  photo_url?: string;
  type?: string;
  source?: string;
  score?: number;
  top_category?: string;
}

export interface QuickRecommendations {
  quick_bites: Recommendation[];
  cozy_cafes: Recommendation[];
  explore: Recommendation[];
  events: Recommendation[];
}

export interface DashboardResponse {
  weather: WeatherData;
  calendar_linked: boolean;
  next_free: FreeTimeBlock | null;
  free_time_suggestion: FreeTimeSuggestion | null;
  quick_recommendations: QuickRecommendations;
}

export interface TopRecommendationsResponse {
  category: "top";
  places: Recommendation[];
}
