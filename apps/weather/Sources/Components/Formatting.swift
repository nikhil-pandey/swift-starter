import Foundation
import SwiftUI
import WeatherCore

// Rust hands over metric values and dates; these helpers present them in the user's locale and units.

extension Double {
    /// A temperature in the user's preferred unit, e.g. "21°".
    var formattedTemperature: String {
        Measurement(value: self, unit: UnitTemperature.celsius)
            .formatted(
                .measurement(width: .narrow, usage: .weather, numberFormatStyle: .number.precision(.fractionLength(0))))
    }
}

extension Forecast {
    var timeZone: TimeZone { TimeZone(identifier: timezone) ?? .current }

    /// Formats a date in the forecast location's time zone.
    func formatted(_ date: Date, _ style: Date.FormatStyle) -> String {
        var style = style
        style.timeZone = timeZone
        return date.formatted(style)
    }

    var highLowText: String {
        guard let today = daily.first else { return "" }
        return String(localized: "H:\(today.high.formattedTemperature)  L:\(today.low.formattedTemperature)")
    }
}

extension Condition {
    var name: String {
        switch self {
        case .clear: String(localized: "Clear")
        case .mostlyClear: String(localized: "Mostly Clear")
        case .partlyCloudy: String(localized: "Partly Cloudy")
        case .cloudy: String(localized: "Cloudy")
        case .fog: String(localized: "Foggy")
        case .drizzle: String(localized: "Drizzle")
        case .rain: String(localized: "Rain")
        case .heavyRain: String(localized: "Heavy Rain")
        case .freezingRain: String(localized: "Freezing Rain")
        case .snow: String(localized: "Snow")
        case .heavySnow: String(localized: "Heavy Snow")
        case .thunderstorms: String(localized: "Thunderstorms")
        case .hail: String(localized: "Hail")
        }
    }

    func symbolName(isDay: Bool = true) -> String {
        switch self {
        case .clear: isDay ? "sun.max.fill" : "moon.stars.fill"
        case .mostlyClear: isDay ? "sun.max.fill" : "moon.fill"
        case .partlyCloudy: isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case .cloudy: "cloud.fill"
        case .fog: "cloud.fog.fill"
        case .drizzle: "cloud.drizzle.fill"
        case .rain: "cloud.rain.fill"
        case .heavyRain: "cloud.heavyrain.fill"
        case .freezingRain: "cloud.sleet.fill"
        case .snow, .heavySnow: "cloud.snow.fill"
        case .thunderstorms: "cloud.bolt.rain.fill"
        case .hail: "cloud.hail.fill"
        }
    }
}

extension WeatherError {
    var userMessage: String {
        switch self {
        case .Network: String(localized: "Check your internet connection and try again.")
        case .Storage, .Corrupted: String(localized: "Weather data couldn't be saved on this device.")
        }
    }
}
