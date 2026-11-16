# Weather

A weather app for iPhone, modeled on the stock Weather app, with forecasts from [Open-Meteo](https://open-meteo.com).

It doubles as a sample and template for new iOS apps: SwiftUI for the UI, Rust for the business logic (bridged with
[UniFFI](https://mozilla.github.io/uniffi-rs/)), and [Bazel](https://bazel.build) building everything in one graph.
New apps live alongside it in `apps/`.

## Requirements

- An Apple silicon Mac with Xcode 27 or later selected as the active developer directory
- The iOS Simulator runtime paired with that Xcode release, including an iPhone 18 Pro simulator for UI tests
- [mise](https://mise.jdx.dev), which installs `bazelisk`; Bazel fetches everything else, including Rust

The app targets iOS 27 or later. The Bazel Rust toolchains currently support Apple silicon hosts, the arm64 iOS
Simulator, and arm64 iOS devices. No API key is needed to run the sample.

## Usage

```sh
mise install                                         # install bazelisk
bazel run //apps/weather:Weather                     # build and launch in the Simulator
bazel test //...                                     # UI accessibility audit and lints
bazel run //tools/format                             # format Swift and Rust
bazel run //:xcodeproj                               # generate Apps.xcodeproj for Xcode
bazel build //apps/weather:Weather --config=device   # build for iPhone hardware
```

The first build downloads the pinned build tools and dependencies. The UI accessibility test fetches a live forecast
for Cupertino, so it needs internet access and an available weather service. `bazel test //...` also checks clippy,
rustfmt, and swift-format; there are currently no Rust unit test targets.

## Customizing the sample

The app uses the example bundle identifier `org.example.weather`. Before signing or distributing your own app, replace
it in `apps/weather/BUILD.bazel` and update `LOG_SUBSYSTEM` in `crates/weather-ffi/src/weather.rs` to match.
Device builds also need your own Apple signing configuration.

Keep machine-specific Bazel flags and signing settings in `user.bazelrc`, which `.bazelrc` imports when present and Git
ignores. Generated Xcode projects, bindings, build outputs, and signing credentials should stay out of version control.

## Data and location

Forecasts, air quality, and place searches use [Open-Meteo](https://open-meteo.com). Device coordinates are sent to its
forecast and air-quality APIs when location access is granted. Apple's location and MapKit services find and name the
device's location. Saved cities and cached forecasts are stored in the app's local Application Support directory.
The forecast screen includes the Open-Meteo attribution link.

## Layout

```
apps/<app>/          iOS app: Sources/, Resources/, UITests/, Info.plist
crates/<domain>/     Rust business logic, shared across apps
crates/<app>-ffi/    The Rust library an app links, exposed to Swift
tools/               Build tooling: ios_app macro, UniFFI bindings, formatting
```

## Adding an app

1. Create `crates/<app>-ffi` with a `rust_static_library` and a `uniffi_swift_library`, like `crates/weather-ffi`.
2. Create `apps/<app>` with a `BUILD.bazel` calling `ios_app`, like `apps/weather`.
3. Add it to `xcodeproj` in the root `BUILD.bazel`.

## License

This project's source code is available under the [MIT License](LICENSE).
