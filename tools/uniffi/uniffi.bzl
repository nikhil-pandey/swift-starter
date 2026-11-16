"""Swift bindings for a Rust static library that exports a UniFFI API."""

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_swift//swift:swift_interop_hint.bzl", "swift_interop_hint")
load("@rules_swift//swift:swift_library.bzl", "swift_library")

def uniffi_swift_library(name, library, crates, visibility = None):
    """Generates Swift bindings for `library` and exposes them as the Swift module `name`.

    Args:
        name: Target and Swift module name, e.g. "WeatherCore".
        library: The `rust_static_library` the app links.
        crates: Crate names in `library` that export UniFFI items; each yields `<crate>.swift` and `<crate>FFI.h`.
        visibility: Visibility of the Swift module.
    """
    swift_srcs = [crate + ".swift" for crate in crates]
    headers = [crate + "FFI.h" for crate in crates]
    native.genrule(
        name = name + "_bindings",
        srcs = [library],
        outs = swift_srcs + headers,
        cmd = "$(execpath //tools/uniffi:uniffi-swift-bindgen) $(execpath {}) $(RULEDIR)".format(library),
        tools = ["//tools/uniffi:uniffi-swift-bindgen"],
    )

    # Each crate's Swift file imports its own C module, `<crate>FFI`.
    ffi_modules = []
    for crate in crates:
        swift_interop_hint(
            name = "{}_{}_module".format(name, crate),
            module_name = crate + "FFI",
        )
        cc_library(
            name = "{}_{}_ffi".format(name, crate),
            hdrs = [crate + "FFI.h"],
            aspect_hints = [":{}_{}_module".format(name, crate)],
        )
        ffi_modules.append(":{}_{}_ffi".format(name, crate))

    swift_library(
        name = name,
        srcs = swift_srcs,
        module_name = name,
        visibility = visibility,
        deps = ffi_modules + [library],
    )
