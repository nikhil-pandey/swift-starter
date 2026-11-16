//! Generates UniFFI Swift sources and C headers from a Rust static library.
//!
//! Unlike the stock `uniffi-bindgen-swift`, this never runs `cargo metadata`, so it works in Bazel's sandbox.
//! Usage: `uniffi-swift-bindgen <library.a> <out-dir>`

use anyhow::{Context, bail};
use camino::Utf8PathBuf;
use uniffi_bindgen::bindings::{SwiftBindingsOptions, generate_swift_bindings};

fn main() -> anyhow::Result<()> {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let [library, out_dir] = args.as_slice() else {
        bail!("usage: uniffi-swift-bindgen <library.a> <out-dir>");
    };
    generate_swift_bindings(SwiftBindingsOptions {
        generate_swift_sources: true,
        generate_headers: true,
        source: Utf8PathBuf::from(library),
        out_dir: Utf8PathBuf::from(out_dir),
        ..Default::default()
    })
    .with_context(|| format!("generating Swift bindings for {library}"))
}
