import Charts
import SwiftUI
import WeatherCore

/// Chance of precipitation over the next 24 hours, shown only when any is expected.
struct PrecipitationCard: View {
    let forecast: Forecast

    private var hours: [Hour] {
        forecast.hourly.compactMap { item in
            if case .hour(let hour) = item { hour } else { nil }
        }
    }

    var body: some View {
        if hours.contains(where: { ($0.precipitationProbability ?? 0) > 0 }) {
            WeatherCard(title: "Chance of Precipitation", systemImage: "umbrella.fill") {
                Chart(hours, id: \.time) { hour in
                    BarMark(
                        x: .value("Time", hour.time, unit: .hour),
                        y: .value("Chance", Double(hour.precipitationProbability ?? 0) / 100)
                    )
                    .foregroundStyle(.cyan.gradient)
                }
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(values: [0, 0.5, 1]) {
                        AxisGridLine()
                        AxisValueLabel(format: FloatingPointFormatStyle<Double>.Percent())
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 6)) {
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .environment(\.timeZone, forecast.timeZone)
                .frame(height: 140)
            }
        }
    }
}

#Preview {
    PrecipitationCard(forecast: .preview)
        .padding()
        .background(WeatherBackground(condition: .rain))
        .preferredColorScheme(.dark)
}
