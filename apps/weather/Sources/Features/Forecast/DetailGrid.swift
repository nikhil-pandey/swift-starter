import SwiftUI
import WeatherCore

/// Two-column grid of current-condition tiles, like the stock app's lower half.
struct DetailGrid: View {
    let forecast: Forecast

    private var current: Current { forecast.current }

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
            if let airQuality = forecast.airQuality {
                DetailTile("Air Quality", systemImage: "aqi.medium", value: "\(airQuality.usAqi)") {
                    Text(airQuality.level.name)
                }
            }
            DetailTile(
                "UV Index", systemImage: "sun.max.fill",
                value: current.uvIndex.formatted(.number.precision(.fractionLength(0)))
            ) {
                Text(current.uvLevel.name)
                Gauge(value: min(current.uvIndex, 11), in: 0...11) {}
                    .gaugeStyle(.accessoryLinear)
                    .tint(Gradient(colors: [.green, .yellow, .orange, .red, .purple]))
                    .accessibilityHidden(true)
            }
            DetailTile("Feels Like", systemImage: "thermometer.medium", value: current.feelsLike.formattedTemperature) {
                Text(current.feelsLikeReason.explanation)
            }
            DetailTile("Wind", systemImage: "wind", value: speed(current.wind.speedKmh)) {
                HStack {
                    Image(systemName: "location.north.fill")
                        .rotationEffect(.degrees(current.wind.directionDegrees + 180))
                        .accessibilityHidden(true)
                    Text("From \(current.wind.compass.abbreviation)")
                }
                Text("Gusts \(speed(current.wind.gustsKmh))")
            }
            if let event = nextSunEvent {
                DetailTile(
                    event.title, systemImage: event.symbol,
                    value: forecast.formatted(event.time, .dateTime.hour().minute())
                ) {
                    EmptyView()
                }
            }
            DetailTile(
                "Precipitation", systemImage: "drop.fill",
                value: millimeters(forecast.daily.first?.precipitationMm ?? 0)
            ) {
                Text("Expected today")
            }
            DetailTile(
                "Humidity", systemImage: "humidity",
                value: (current.humidityPercent / 100).formatted(.percent.precision(.fractionLength(0)))
            ) {
                Text("The dew point is \(current.dewPoint.formattedTemperature) right now.")
            }
            DetailTile(
                "Visibility", systemImage: "eye.fill",
                value: Measurement(value: current.visibilityM, unit: UnitLength.meters).formatted(
                    .measurement(
                        width: .abbreviated, usage: .road, numberFormatStyle: .number.precision(.fractionLength(0))))
            ) {
                EmptyView()
            }
            DetailTile(
                "Pressure", systemImage: "gauge.with.dots.needle.33percent",
                value: Measurement(value: current.pressureHpa, unit: UnitPressure.hectopascals).formatted(
                    .measurement(
                        width: .abbreviated, usage: .barometric,
                        numberFormatStyle: .number.precision(.fractionLength(0))))
            ) {
                EmptyView()
            }
        }
    }

    /// The first sunrise or sunset in the hourly items Rust interleaved.
    private var nextSunEvent: (title: LocalizedStringKey, symbol: String, time: Date)? {
        for item in forecast.hourly {
            switch item {
            case .sunrise(let time): return ("Sunrise", "sunrise.fill", time)
            case .sunset(let time): return ("Sunset", "sunset.fill", time)
            case .hour: continue
            }
        }
        return nil
    }

    private func speed(_ kmh: Double) -> String {
        Measurement(value: kmh, unit: UnitSpeed.kilometersPerHour)
            .formatted(
                .measurement(
                    width: .abbreviated, usage: .wind, numberFormatStyle: .number.precision(.fractionLength(0))))
    }

    private func millimeters(_ value: Double) -> String {
        Measurement(value: value, unit: UnitLength.millimeters)
            .formatted(
                .measurement(
                    width: .abbreviated, usage: .rainfall, numberFormatStyle: .number.precision(.fractionLength(0...1)))
            )
    }
}

/// A square-ish card with a headline value and optional supporting content.
private struct DetailTile<Content: View>: View {
    let title: LocalizedStringKey
    let systemImage: String
    let value: String
    @ViewBuilder let content: Content

    @ScaledMetric(relativeTo: .body) private var minHeight = 150

    init(_ title: LocalizedStringKey, systemImage: String, value: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.value = value
        self.content = content()
    }

    var body: some View {
        WeatherCard(title: title, systemImage: systemImage) {
            Text(value)
                .font(.largeTitle)
            Spacer(minLength: 0)
            content
                .font(.subheadline)
        }
        .frame(minHeight: minHeight)
        .accessibilityElement(children: .combine)
    }
}

extension UvLevel {
    var name: String {
        switch self {
        case .low: String(localized: "Low")
        case .moderate: String(localized: "Moderate")
        case .high: String(localized: "High")
        case .veryHigh: String(localized: "Very High")
        case .extreme: String(localized: "Extreme")
        }
    }
}

extension AirQualityLevel {
    var name: String {
        switch self {
        case .good: String(localized: "Good")
        case .moderate: String(localized: "Moderate")
        case .unhealthyForSensitiveGroups: String(localized: "Unhealthy for Sensitive Groups")
        case .unhealthy: String(localized: "Unhealthy")
        case .veryUnhealthy: String(localized: "Very Unhealthy")
        case .hazardous: String(localized: "Hazardous")
        }
    }
}

extension FeelsLikeReason {
    var explanation: String {
        switch self {
        case .similar: String(localized: "Similar to the actual temperature.")
        case .humidity: String(localized: "Humidity is making it feel warmer.")
        case .wind: String(localized: "Wind is making it feel cooler.")
        case .warmer: String(localized: "Feels warmer than the actual temperature.")
        case .colder: String(localized: "Feels cooler than the actual temperature.")
        }
    }
}

extension CompassPoint {
    var abbreviation: String {
        switch self {
        case .n: String(localized: "N")
        case .nne: String(localized: "NNE")
        case .ne: String(localized: "NE")
        case .ene: String(localized: "ENE")
        case .e: String(localized: "E")
        case .ese: String(localized: "ESE")
        case .se: String(localized: "SE")
        case .sse: String(localized: "SSE")
        case .s: String(localized: "S")
        case .ssw: String(localized: "SSW")
        case .sw: String(localized: "SW")
        case .wsw: String(localized: "WSW")
        case .w: String(localized: "W")
        case .wnw: String(localized: "WNW")
        case .nw: String(localized: "NW")
        case .nnw: String(localized: "NNW")
        }
    }
}

#Preview {
    ScrollView {
        DetailGrid(forecast: .preview)
            .padding()
    }
    .background(WeatherBackground(condition: .clear))
    .preferredColorScheme(.dark)
}
