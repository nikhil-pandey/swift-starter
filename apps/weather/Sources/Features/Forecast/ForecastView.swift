import SwiftUI
import WeatherCore

/// One location's page: header, then forecast cards. `RootView` draws the sky behind it.
struct ForecastView: View {
    let location: Location
    @Environment(WeatherModel.self) private var model

    var body: some View {
        let forecast = model.forecasts[location.id]
        ScrollView {
            VStack(spacing: 12) {
                ForecastHeader(location: location, forecast: forecast)
                if let forecast {
                    HourlyCard(forecast: forecast)
                    DailyCard(forecast: forecast)
                    PrecipitationCard(forecast: forecast)
                    DetailGrid(forecast: forecast)
                    Link("Weather data by Open-Meteo.com", destination: URL(string: "https://open-meteo.com")!)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.vertical)
                } else if let failure = model.failures[location.id] {
                    ContentUnavailableView {
                        Label("Weather Unavailable", systemImage: "icloud.slash")
                    } description: {
                        Text(failure.userMessage)
                    } actions: {
                        Button("Try Again") { Task { await model.refresh(location, force: true) } }
                    }
                } else {
                    ProgressView()
                        .padding(.top, 48)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .refreshable { await model.refresh(location, force: true) }
        .task(id: location.id) {
            // The device's location is refreshed by `locateDevice()` once it has coordinates.
            if !location.isCurrent { await model.refresh(location) }
        }
    }
}

/// City, current temperature, condition, and today's high and low.
struct ForecastHeader: View {
    let location: Location
    let forecast: Forecast?

    @ScaledMetric(relativeTo: .largeTitle) private var temperatureSize = 96

    var body: some View {
        VStack(spacing: 2) {
            Text(location.isCurrent ? "My Location" : location.name)
                .font(.largeTitle)
            if location.isCurrent {
                Text(location.name)
                    .font(.footnote.weight(.semibold))
                    .textCase(.uppercase)
            }
            if let forecast {
                Text(forecast.current.temperature.formattedTemperature)
                    .font(.system(size: temperatureSize, weight: .thin))
                    .contentTransition(.numericText())
                Text(forecast.current.condition.name)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(forecast.highLowText)
                    .font(.title3.weight(.medium))
            }
        }
        .padding(.top, 60)
        .padding(.bottom, 24)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ForecastView(location: .preview)
        .environment(WeatherModel())
}
