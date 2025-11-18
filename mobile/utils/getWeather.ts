export async function getWeather(lat: number, lon: number) {
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
