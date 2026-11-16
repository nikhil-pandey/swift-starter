import SwiftUI

@main
struct WeatherApp: App {
    @State private var model = WeatherModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                // Like the stock Weather app, the UI is dark-styled over its sky backgrounds.
                .preferredColorScheme(.dark)
        }
    }
}
