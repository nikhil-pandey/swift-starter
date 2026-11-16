import CoreLocation
import XCTest

/// Runs Apple's automated accessibility audit (Dynamic Type, clipping, labels, hit targets, traits) on the forecast.
final class AccessibilityAuditTests: XCTestCase {
    @MainActor
    func testForecastPassesAccessibilityAudit() throws {
        // Fresh simulators have no location; simulate Cupertino so the forecast loads.
        XCUIDevice.shared.location = XCUILocation(location: CLLocation(latitude: 37.3349, longitude: -122.0090))
        let app = XCUIApplication()
        app.launch()

        let allowLocation = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Allow While Using App"]
        // The alert can resolve on its own if permission was already granted, so only tap a live button.
        if allowLocation.waitForExistence(timeout: 5), allowLocation.isHittable {
            allowLocation.tap()
        }
        XCTAssertTrue(app.staticTexts["Today"].waitForExistence(timeout: 30), "Forecast never loaded")

        // Excluded, and checked by hand in Accessibility Inspector instead:
        // - contrast: misreads light text over the translucent cards and sky gradients.
        // - elementDetection: reports text with no element attached (system UI), so there is nothing to fix.
        try app.performAccessibilityAudit(for: .all.subtracting([.contrast, .elementDetection]))
    }
}
