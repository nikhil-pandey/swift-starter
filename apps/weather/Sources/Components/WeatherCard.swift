import SwiftUI

/// Rounded, translucent container used for every forecast section, with an optional small caps header.
/// Content uses a material rather than Liquid Glass, which the HIG reserves for controls and navigation.
struct WeatherCard<Content: View>: View {
    var title: LocalizedStringKey?
    var systemImage: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title, let systemImage {
                Label(title, systemImage: systemImage)
                    .font(.footnote.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                    // Keep VoiceOver from reading the uppercased title letter by letter.
                    .accessibilityLabel(Text(title))
                    .accessibilityAddTraits(.isHeader)
            }
            content
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 20))
    }
}

#Preview {
    WeatherCard(title: "Humidity", systemImage: "humidity") {
        Text("64%").font(.largeTitle)
    }
    .padding()
    .background(.blue.gradient)
    .preferredColorScheme(.dark)
}
