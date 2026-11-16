import Foundation
import WeatherCore

// Sample data for SwiftUI previews only; real forecasts come from Rust.

extension Location {
    static let preview = Location(
        id: "2988507", name: "Paris", region: "Île-de-France, France", latitude: 48.85, longitude: 2.35)
}

extension Forecast {
    static let preview: Forecast = {
        let now = Calendar.current.dateInterval(of: .hour, for: .now)!.start
        let conditions: [Condition] = [.clear, .partlyCloudy, .cloudy, .rain, .drizzle, .mostlyClear]
        let hours: [Hour] = (0..<24).map { (offset: Int) -> Hour in
            let chance: Int = max(0, 60 - abs(offset - 14) * 12)
            let temperature: Double = 12 + 6 * sin(Double(offset) / 4)
            return Hour(
                time: now + TimeInterval(offset) * 3600,
                condition: conditions[offset / 4],
                isDay: (6..<18).contains(offset),
                temperature: temperature,
                precipitationProbability: UInt8(chance)
            )
        }
        let days: [Day] = (0..<10).map { (offset: Int) -> Day in
            Day(
                date: now + TimeInterval(offset) * 86_400,
                condition: conditions[offset % conditions.count],
                low: 6 + Double(offset % 3),
                high: 15 + Double(offset % 4) * 2,
                precipitationProbability: UInt8(offset * 9),
                precipitationMm: Double(offset) / 2,
                uvIndexMax: 4,
                sunrise: now + 2 * 3600,
                sunset: now + 12 * 3600
            )
        }
        var hourly: [HourlyItem] = hours.map { HourlyItem.hour(hour: $0) }
        hourly.insert(.sunrise(time: now + 2 * 3600), at: 3)
        return Forecast(
            timezone: "Europe/Paris",
            fetchedAt: now,
            current: Current(
                time: now,
                condition: .partlyCloudy,
                isDay: true,
                temperature: 14,
                feelsLike: 12,
                feelsLikeReason: .wind,
                humidityPercent: 64,
                dewPoint: 7,
                precipitationMm: 0,
                pressureHpa: 1016,
                visibilityM: 24_000,
                uvIndex: 4,
                uvLevel: .moderate,
                wind: Wind(speedKmh: 18, gustsKmh: 31, directionDegrees: 225, compass: .sw)
            ),
            outlook: .precipitationStarting(condition: .rain, at: now + 12 * 3600),
            hourly: hourly,
            daily: days,
            dailyLow: 6,
            dailyHigh: 21,
            airQuality: AirQuality(usAqi: 42, level: .good)
        )
    }()
}
