import SwiftUI
import WeatherCore

/// Saved locations as weather cards, with city search to add more.
struct LocationsView: View {
    @Environment(WeatherModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [Location] = []
    @State private var searchError: WeatherError?

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    savedLocations
                } else {
                    searchResults
                }
            }
            .listStyle(.plain)
            .navigationTitle("Weather")
            .searchable(text: $query, prompt: "Search for a city")
            .task(id: query) { await search() }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", role: .confirm) { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var savedLocations: some View {
        if let current = model.currentLocation {
            row(for: current)
        }
        ForEach(model.savedLocations, id: \.id) { location in
            row(for: location)
        }
        .onDelete { offsets in
            offsets.map { model.savedLocations[$0] }.forEach(model.remove)
        }
    }

    private func row(for location: Location) -> some View {
        Button {
            model.selectedLocationID = location.id
            dismiss()
        } label: {
            LocationRow(location: location, forecast: model.forecasts[location.id])
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }

    @ViewBuilder
    private var searchResults: some View {
        if let searchError {
            ContentUnavailableView(
                "Search Unavailable", systemImage: "wifi.slash", description: Text(searchError.userMessage))
        } else if results.isEmpty {
            ContentUnavailableView.search(text: query)
        } else {
            ForEach(results, id: \.id) { result in
                Button {
                    model.add(result)
                    dismiss()
                } label: {
                    VStack(alignment: .leading) {
                        Text(result.name)
                        if let region = result.region {
                            Text(region)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func search() async {
        // Debounce typing; a newer query cancels this task.
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        do {
            results = try await model.search(query)
            searchError = nil
        } catch let error as WeatherError {
            searchError = error
        } catch {
            preconditionFailure("WeatherService only throws WeatherError: \(error)")
        }
    }
}

/// A saved location as a small weather card: name, local time or place, condition, and temperatures.
struct LocationRow: View {
    let location: Location
    let forecast: Forecast?

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(location.isCurrent ? "My Location" : location.name)
                    .font(.title2.bold())
                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                Spacer(minLength: 16)
                if let forecast {
                    Text(forecast.current.condition.name)
                        .font(.subheadline.weight(.medium))
                }
            }
            Spacer()
            if let forecast {
                VStack(alignment: .trailing) {
                    Text(forecast.current.temperature.formattedTemperature)
                        .font(.largeTitle.weight(.light))
                    Spacer(minLength: 16)
                    Text(forecast.highLowText)
                        .font(.subheadline.weight(.medium))
                }
            }
        }
        .foregroundStyle(.primary)
        .padding()
        .background {
            WeatherBackground(condition: forecast?.current.condition, isDay: forecast?.current.isDay ?? true)
                .clipShape(.rect(cornerRadius: 20))
        }
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        if location.isCurrent { return location.name }
        guard let forecast else { return location.region ?? "" }
        var style = Date.FormatStyle.dateTime.hour().minute()
        style.timeZone = forecast.timeZone
        return Date.now.formatted(style)
    }
}

#Preview {
    LocationRow(location: .preview, forecast: .preview)
        .padding()
}
