import Foundation
import Observation

@Observable
final class WeatherManager {
    // Must use ChatWeather (the same type the dashboard returns)
    var weather: Weather?

    @MainActor
    func loadWeather() async {
        print("🌦️ WeatherManager.loadWeather() — public")

        do {
            let w = try await APIService.shared.getPublicWeather()
            self.weather = w
            print("✅ Public weather loaded:", w.tempF, w.emoji)
        } catch {
            print("❌ Public weather load failed:", error)
        }
    }
}
