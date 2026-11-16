import SwiftUI
import WeatherCore

/// Toolbar page dots, with a location arrow for the device's location, like the stock Weather app.
struct PageIndicator: View {
    let locations: [Location]
    let selectedID: String?

    @ScaledMetric(relativeTo: .caption) private var dotSize = 7

    var body: some View {
        HStack(spacing: dotSize) {
            ForEach(locations, id: \.id) { location in
                Group {
                    if location.isCurrent {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                    } else {
                        Circle()
                            .frame(width: dotSize, height: dotSize)
                    }
                }
                .foregroundStyle(location.id == selectedID ? .primary : .tertiary)
            }
        }
        // Toolbar content needs the HIG's 44 pt minimum target, even when only informational.
        .padding(.horizontal)
        .frame(minHeight: 44)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let index = (locations.firstIndex { $0.id == selectedID } ?? 0) + 1
        return String(localized: "Page \(index) of \(locations.count)")
    }
}

#Preview {
    PageIndicator(locations: [.preview, .preview], selectedID: Location.preview.id)
        .padding()
        .preferredColorScheme(.dark)
}
