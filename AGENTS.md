# AGENTS.md

## Layout

- Bazel (bzlmod) monorepo for multiple apps; keep packages small and dependencies explicit.
- `apps/<app>/`: SwiftUI app declared with `ios_app` (`//tools/apple:defs.bzl`). Platform services and presentation
  only; business logic belongs in Rust.
- `crates/<domain>/`: plain Rust logic shared across apps. Public types derive UniFFI traits only behind the optional
  `uniffi` feature (`#[cfg_attr(feature = "uniffi", derive(...))]`), which Bazel enables through
  the workspace-unified features in `crate_data()`.
- `crates/<app>-ffi/`: the one `rust_static_library` an app links, with thin `uniffi::Object` wrappers and the app's
  Swift module (`uniffi_swift_library`). List every crate that exports UniFFI items in its `crates`.
- Swift settings (Swift 6, upcoming features, warnings as errors) come from `REPO.bazel`; don't repeat them as `copts`.
- Generated code (bindings, Xcode projects) is a build output; never check it in.

## Rust ↔ Swift boundary

- Rust returns metric values, `SystemTime` (Swift `Date`), and enums for meaning (`Outlook`, `UvLevel`). Swift owns
  wording, formatting (`Measurement`, `Date.FormatStyle`), SF Symbols, and colors.
- Objects take `&self`; constructors return `Arc<Self>`; async methods use `#[uniffi::export(async_runtime = "tokio")]`.
- Errors are `thiserror` enums with `#[uniffi(flat_error)]`; Swift maps cases to user-facing messages.
- Prefix names that collide in Swift (`Error`, `Result`, `Data`), e.g. `WeatherError`.

## Swift and Apple design

- Follow the [HIG](https://developer.apple.com/design/human-interface-guidelines); prefer system components (`List`,
  `Grid`, `Gauge`, `ContentUnavailableView`, `.searchable`, `.refreshable`, Swift Charts) over custom ones.
- Text styles for fonts (custom sizes only via `@ScaledMetric`); semantic colors and materials for UI; Liquid Glass for
  controls and navigation; touch targets of at least 44 pt.
- Label visual-only elements or mark them `.accessibilityHidden`; combine related text into one accessibility element.
- User-facing strings are localizable (`Text` literals, `String(localized:)`).
- One view per concern in `Sources/Features/<Feature>/`, shared views in `Sources/Components/`; every view has a
  `#Preview` using `PreviewData.swift`.

## Workflow

- Commands are in `README.md`. `bazel test //...` must pass: the UI accessibility audit, clippy
  (`-D warnings`), rustfmt, and swift-format. Fix formatting with `bazel run //tools/format`.
- Rust dependencies go in the Cargo workspace (`Cargo.toml`/`Cargo.lock`); Bazel modules and the Rust toolchain are
  pinned in `MODULE.bazel`.
- Keep `uniffi` (workspace) and `uniffi_bindgen` (`tools/uniffi`) on the same exact version.
- Keep `MINIMUM_OS_VERSION` and the simulator in `tools/apple` in step with Xcode.
