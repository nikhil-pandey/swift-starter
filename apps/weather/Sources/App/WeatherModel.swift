import Foundation
import Observation
import WeatherCore

/// What the UI shows, plus user intents. Fetching, interpreting, caching, and persisting weather all
/// happen in Rust (`WeatherService`); this type only holds results and forwards calls.
@Observable
final class WeatherModel {
    private(set) var currentLocation: Location?
    private(set) var savedLocations: [Location] = []
    private(set) var forecasts: [String: Forecast] = [:]
    private(set) var failures: [String: WeatherError] = [:]
    var selectedLocationID: String?

    let locationProvider = LocationProvider()
    private let service: WeatherService

    /// Pages in display order: the device's location first, then saved cities.
    var locations: [Location] { [currentLocation].compactMap(\.self) + savedLocations }

    init() {
        let directory = URL.applicationSupportDirectory.appending(path: "Weather")
        // Fails only if Application Support can't be created, which leaves the app nothing to do.
        service = try! WeatherService(dataDir: directory.path(percentEncoded: false))
        savedLocations = (try? service.savedLocations()) ?? []
        for id in [Location.currentID] + savedLocations.map(\.id) {
            forecasts[id] = service.cachedForecast(locationId: id)
        }
        selectedLocationID = savedLocations.first?.id
    }

    func locateDevice() async {
        guard let place = await locationProvider.locate() else { return }
        let location = Location(
            id: Location.currentID,
            name: place.name,
            region: nil,
            latitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude
        )
        currentLocation = location
        if selectedLocationID == nil || selectedLocationID == savedLocations.first?.id {
            selectedLocationID = location.id
        }
        await refresh(location)
    }

    /// Loads a forecast; Rust serves a fresh cached copy unless `force` is set.
    func refresh(_ location: Location, force: Bool = false) async {
        do {
            forecasts[location.id] = try await service.forecast(location: location, forceRefresh: force)
            failures[location.id] = nil
        } catch let error as WeatherError {
            failures[location.id] = error
        } catch {
            preconditionFailure("WeatherService only throws WeatherError: \(error)")
        }
    }

    func search(_ query: String) async throws -> [Location] {
        let language = Locale.current.language.languageCode?.identifier ?? "en"
        return try await service.search(query: query, language: language)
    }

    func add(_ location: Location) {
        savedLocations = (try? service.addLocation(location: location)) ?? savedLocations
        selectedLocationID = location.id
        Task { await refresh(location) }
    }

    func remove(_ location: Location) {
        savedLocations = (try? service.removeLocation(id: location.id)) ?? savedLocations
        forecasts[location.id] = nil
        if selectedLocationID == location.id {
            selectedLocationID = locations.first?.id
        }
    }
}

extension Location {
    static let currentID = "current"

    var isCurrent: Bool { id == Self.currentID }
}
