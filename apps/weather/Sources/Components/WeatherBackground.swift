import SwiftUI
import WeatherCore

/// Sky gradient behind a location's forecast, chosen from its current condition and time of day.
/// A decorative palette, so these are fixed colors rather than semantic ones.
struct WeatherBackground: View {
    var condition: Condition?
    var isDay = true

    var body: some View {
        LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }

    private var colors: [Color] {
        switch (condition, isDay) {
        case (.clear, true), (.mostlyClear, true), (.partlyCloudy, true), (nil, true):
            [
                Color(hue: 0.58, saturation: 0.65, brightness: 0.85),
                Color(hue: 0.57, saturation: 0.45, brightness: 0.95),
            ]
        case (.cloudy, true), (.fog, true):
            [Color(hue: 0.6, saturation: 0.2, brightness: 0.65), Color(hue: 0.6, saturation: 0.15, brightness: 0.8)]
        case (.snow, true), (.heavySnow, true):
            [Color(hue: 0.58, saturation: 0.2, brightness: 0.75), Color(hue: 0.58, saturation: 0.1, brightness: 0.9)]
        case (.thunderstorms, _), (.hail, _):
            [Color(hue: 0.72, saturation: 0.3, brightness: 0.3), Color(hue: 0.65, saturation: 0.25, brightness: 0.45)]
        case (_, true):
            [Color(hue: 0.6, saturation: 0.3, brightness: 0.45), Color(hue: 0.6, saturation: 0.2, brightness: 0.6)]
        case (_, false):
            [Color(hue: 0.65, saturation: 0.6, brightness: 0.18), Color(hue: 0.63, saturation: 0.45, brightness: 0.35)]
        }
    }
}

#Preview {
    WeatherBackground(condition: .partlyCloudy)
}
