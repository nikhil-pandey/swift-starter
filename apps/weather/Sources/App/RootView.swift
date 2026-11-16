import SwiftUI
import WeatherCore

/// Pages through locations like the stock Weather app, with the location list behind the toolbar button.
struct RootView: View {
    @Environment(WeatherModel.self) private var model
    @State private var showsLocations = false

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            Group {
                if model.locations.isEmpty {
                    emptyState
                } else {
                    TabView(selection: $model.selectedLocationID) {
                        ForEach(model.locations, id: \.id) { location in
                            ForecastView(location: location)
                                .tag(Optional(location.id))
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .ignoresSafeArea(edges: .top)
                }
            }
            .background {
                let forecast = model.selectedLocationID.flatMap { model.forecasts[$0] }
                WeatherBackground(condition: forecast?.current.condition, isDay: forecast?.current.isDay ?? true)
                    .animation(.easeInOut, value: model.selectedLocationID)
            }
            .toolbar {
                ToolbarSpacer(.flexible, placement: .bottomBar)
                if model.locations.count > 1 {
                    ToolbarItem(placement: .bottomBar) {
                        PageIndicator(locations: model.locations, selectedID: model.selectedLocationID)
                    }
                    .sharedBackgroundVisibility(.hidden)
                    ToolbarSpacer(.flexible, placement: .bottomBar)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("Locations", systemImage: "list.bullet") { showsLocations = true }
                }
            }
        }
        .sheet(isPresented: $showsLocations) {
            LocationsView()
        }
        .task { await model.locateDevice() }
    }

    @ViewBuilder
    private var emptyState: some View {
        if model.locationProvider.isDenied {
            ContentUnavailableView {
                Label("Location Unavailable", systemImage: "location.slash")
            } description: {
                Text("Allow location access in Settings, or add a city to see its weather.")
            } actions: {
                Button("Add a City") { showsLocations = true }
                    .buttonStyle(.borderedProminent)
            }
        } else {
            ProgressView("Finding Your Location…")
        }
    }
}

#Preview {
    RootView()
        .environment(WeatherModel())
}
