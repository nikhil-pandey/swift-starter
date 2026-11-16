import CoreLocation
import MapKit
import Observation

/// Finds the device's location once and names it, using CoreLocation's async APIs.
@Observable
final class LocationProvider {
    struct Place {
        let coordinate: CLLocationCoordinate2D
        let name: String
    }

    private(set) var isDenied = false
    /// Keeps the when-in-use authorization request alive while locating.
    private var session: CLServiceSession?

    func locate() async -> Place? {
        session = CLServiceSession(authorization: .whenInUse)
        defer { session = nil }
        do {
            for try await update in CLLocationUpdate.liveUpdates() {
                if update.authorizationDenied || update.authorizationDeniedGlobally {
                    isDenied = true
                    return nil
                }
                guard let location = update.location else { continue }
                isDenied = false
                return Place(coordinate: location.coordinate, name: await name(of: location))
            }
        } catch {
            return nil
        }
        return nil
    }

    private func name(of location: CLLocation) async -> String {
        let fallback = String(localized: "My Location")
        guard let request = MKReverseGeocodingRequest(location: location) else { return fallback }
        let mapItems = try? await request.mapItems
        return mapItems?.first?.addressRepresentations?.cityName ?? fallback
    }
}
