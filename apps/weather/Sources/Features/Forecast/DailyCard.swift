import SwiftUI
import WeatherCore

/// Ten days of conditions with lows and highs on a shared scale.
struct DailyCard: View {
    let forecast: Forecast

    var body: some View {
        WeatherCard(title: "10-Day Forecast", systemImage: "calendar") {
            Grid(horizontalSpacing: 12, verticalSpacing: 0) {
                ForEach(Array(forecast.daily.enumerated()), id: \.offset) { index, day in
                    if index > 0 {
                        Divider().gridCellUnsizedAxes(.horizontal)
                    }
                    DailyRow(forecast: forecast, day: day, isToday: index == 0)
                }
            }
        }
    }
}

private struct DailyRow: View {
    let forecast: Forecast
    let day: Day
    let isToday: Bool

    var body: some View {
        GridRow {
            Text(isToday ? String(localized: "Today") : forecast.formatted(day.date, .dateTime.weekday(.abbreviated)))
                .font(.title3.weight(.medium))
                .padding(.vertical, 10)
                .gridColumnAlignment(.leading)
            VStack(spacing: 0) {
                Image(systemName: day.condition.symbolName())
                    .symbolRenderingMode(.multicolor)
                    .font(.title3)
                    .accessibilityLabel(day.condition.name)
                if let chance = day.precipitationProbability, chance >= 20 {
                    Text(Double(chance) / 100, format: .percent)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.cyan)
                }
            }
            .accessibilityElement(children: .combine)
            Text(day.low.formattedTemperature)
                .font(.title3.weight(.medium))
                .monospacedDigit()
                .fixedSize()
                .foregroundStyle(.secondary)
                .accessibilityLabel("Low \(day.low.formattedTemperature)")
            TemperatureRangeBar(
                range: forecast.dailyLow...forecast.dailyHigh,
                low: day.low,
                high: day.high,
                current: isToday ? forecast.current.temperature : nil
            )
            Text(day.high.formattedTemperature)
                .font(.title3.weight(.medium))
                .monospacedDigit()
                .fixedSize()
                .accessibilityLabel("High \(day.high.formattedTemperature)")
        }
    }
}

#Preview {
    DailyCard(forecast: .preview)
        .padding()
        .background(WeatherBackground(condition: .clear))
        .preferredColorScheme(.dark)
}
