import SwiftUI

/// A day's low-to-high span drawn within the whole forecast's range, so rows are comparable.
/// Decorative: the row's text carries the same values for VoiceOver.
struct TemperatureRangeBar: View {
    let range: ClosedRange<Double>
    let low: Double
    let high: Double
    /// Marks the current temperature on today's bar.
    var current: Double?

    @ScaledMetric(relativeTo: .body) private var thickness = 5

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let start = position(of: low) * width
            let end = position(of: high) * width
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.teal, .green, .yellow, .orange], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: max(end - start, thickness))
                    .offset(x: start)
                if let current {
                    Circle()
                        .fill(.white)
                        .stroke(.black.opacity(0.3), lineWidth: 1)
                        .frame(width: thickness + 2, height: thickness + 2)
                        .offset(x: position(of: current) * width - (thickness + 2) / 2)
                }
            }
        }
        .frame(height: thickness)
        .accessibilityHidden(true)
    }

    private func position(of value: Double) -> Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return min(max((value - range.lowerBound) / span, 0), 1)
    }
}

#Preview {
    TemperatureRangeBar(range: 2...24, low: 9, high: 18, current: 14)
        .frame(width: 120)
        .padding()
}
