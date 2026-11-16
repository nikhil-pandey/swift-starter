import SwiftUI
import WeatherCore

/// Outlook headline plus a horizontally scrolling 24-hour strip with sunrise and sunset.
struct HourlyCard: View {
    let forecast: Forecast

    var body: some View {
        WeatherCard {
            Text(outlook)
                .font(.subheadline)
            Divider()
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 22) {
                    ForEach(Array(forecast.hourly.enumerated()), id: \.offset) { index, item in
                        HourlyCell(forecast: forecast, item: item, isNow: index == 0)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var outlook: String {
        switch forecast.outlook {
        case .continuing(let condition):
            String(localized: "\(condition.name) conditions expected for the next 24 hours.")
        case .precipitationStarting(let condition, let at):
            String(localized: "\(condition.name) expected around \(forecast.formatted(at, .dateTime.hour())).")
        case .precipitationEnding(let at):
            String(localized: "Precipitation ending around \(forecast.formatted(at, .dateTime.hour())).")
        }
    }
}

private struct HourlyCell: View {
    let forecast: Forecast
    let item: HourlyItem
    let isNow: Bool

    var body: some View {
        VStack(spacing: 10) {
            Text(label)
                .font(.subheadline.weight(.semibold))
            VStack(spacing: 2) {
                Image(systemName: symbol)
                    .symbolRenderingMode(.multicolor)
                    .font(.title3)
                if case .hour(let hour) = item, let chance = hour.precipitationProbability, chance >= 20 {
                    Text(Double(chance) / 100, format: .percent)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.cyan)
                }
            }
            .frame(minHeight: 36)
            Text(value)
                .font(.title3.weight(.medium))
        }
        .accessibilityElement(children: .combine)
    }

    private var label: String {
        switch item {
        case .hour(let hour): isNow ? String(localized: "Now") : forecast.formatted(hour.time, .dateTime.hour())
        case .sunrise(let time), .sunset(let time): forecast.formatted(time, .dateTime.hour().minute())
        }
    }

    private var symbol: String {
        switch item {
        case .hour(let hour): hour.condition.symbolName(isDay: hour.isDay)
        case .sunrise: "sunrise.fill"
        case .sunset: "sunset.fill"
        }
    }

    private var value: String {
        switch item {
        case .hour(let hour): hour.temperature.formattedTemperature
        case .sunrise: String(localized: "Sunrise")
        case .sunset: String(localized: "Sunset")
        }
    }
}

#Preview {
    HourlyCard(forecast: .preview)
        .padding()
        .background(WeatherBackground(condition: .clear))
        .preferredColorScheme(.dark)
}
