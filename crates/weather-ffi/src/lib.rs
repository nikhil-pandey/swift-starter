//! The static library linked into the app. Domain crates derive their UniFFI types behind a `uniffi`
//! feature; this crate enables it and exports the objects Swift talks to.

uniffi::setup_scaffolding!();

mod weather;
