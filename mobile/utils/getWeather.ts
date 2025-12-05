// mobile/utils/getWeather.ts
import { apiService } from "../services/apiService";
import { WeatherData } from "../types/dashboard";

const BACKEND_URL = process.env.EXPO_PUBLIC_API_URL || "http://localhost:5001";

export interface WeatherResult {
  temp: number;
  emoji: string;
}

/**
 * Get weather from backend API (preferred) or OpenWeather (fallback)
 */
export async function getWeather(lat: number, lon: number): Promise<WeatherResult | null> {
  // Try backend endpoint first
  try {
    const weather = await apiService.get<WeatherData>("/api/weather", {
      lat: lat.toString(),
      lon: lon.toString(),
    });

    if (weather && !weather.error && weather.temp_f) {
      // Convert condition to emoji
      const desc = weather.desc?.toLowerCase() || "";
      let emoji = "☀️";
      if (desc.includes("cloud")) emoji = "☁️";
      if (desc.includes("rain")) emoji = "🌧️";
      if (desc.includes("snow")) emoji = "❄️";
      if (desc.includes("storm")) emoji = "⛈️";

      return {
        temp: Math.round(weather.temp_f),
        emoji,
      };
    }
  } catch (error) {
    console.log("Backend weather unavailable, falling back to OpenWeather:", error);
  }

  // Fallback to OpenWeather API
  const apiKey = process.env.EXPO_PUBLIC_OPENWEATHER_KEY;
  if (!apiKey) return null;

  const url =
    `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${apiKey}&units=imperial`;

  try {
    const res = await fetch(url);
    const data = await res.json();

    const temp = Math.round(data.main.temp);
    const condition = data.weather[0].main.toLowerCase();

    let emoji = "☀️";
    if (condition.includes("cloud")) emoji = "☁️";
    if (condition.includes("rain")) emoji = "🌧️";
    if (condition.includes("snow")) emoji = "❄️";
    if (condition.includes("storm")) emoji = "⛈️";

    return { temp, emoji };
  } catch {
    return null;
  }
}

/**
 * Get simple weather from backend (no coordinates needed)
 */
export async function getSimpleWeather(): Promise<WeatherResult | null> {
  try {
    const weather = await apiService.get<WeatherData>("/api/weather");

    if (weather && !weather.error && weather.temp_f) {
      const desc = weather.desc?.toLowerCase() || "";
      let emoji = "☀️";
      if (desc.includes("cloud")) emoji = "☁️";
      if (desc.includes("rain")) emoji = "🌧️";
      if (desc.includes("snow")) emoji = "❄️";
      if (desc.includes("storm")) emoji = "⛈️";

      return {
        temp: Math.round(weather.temp_f),
        emoji,
      };
    }
  } catch (error) {
    console.error("Error fetching simple weather:", error);
  }

  return null;
}

