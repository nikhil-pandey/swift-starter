"""The standard layout of an iOS app in apps/<app>."""

load("@rules_apple//apple:ios.bzl", "ios_application", "ios_ui_test")
load("@rules_swift//swift:swift_library.bzl", "swift_library")
load("//tools/format:defs.bzl", "swift_format_test")

# Every app ships for the same iOS release; keep in step with Xcode and the simulator runner below.
MINIMUM_OS_VERSION = "27.0"

def ios_app(name, bundle_id, deps = []):
    """An iPhone app built from Sources/, Resources/, Info.plist, and UITests/ in the calling package.

    Declares `<name>` (the app), `<name>App` (its Swift module), `<name>UITests`, and `swift_format`.

    Args:
        name: App and product name, e.g. "Weather".
        bundle_id: Bundle identifier.
        deps: Libraries the app's Swift module imports, typically its `uniffi_swift_library`.
    """
    swift_library(
        name = name + "App",
        srcs = native.glob(["Sources/**/*.swift"]),
        # Xcode's new-project default; not expressible as a rules_swift feature.
        copts = ["-default-isolation", "MainActor"],
        target_compatible_with = ["@platforms//os:ios"],
        deps = deps,
    )

    ios_application(
        name = name,
        bundle_id = bundle_id,
        families = ["iphone"],
        infoplists = ["Info.plist"],
        minimum_os_version = MINIMUM_OS_VERSION,
        resources = native.glob(["Resources/**"]),
        visibility = ["//visibility:public"],
        deps = [name + "App"],
    )

    swift_library(
        name = name + "UITestsLib",
        testonly = True,
        srcs = native.glob(["UITests/**/*.swift"]),
        module_name = name + "UITests",
        target_compatible_with = ["@platforms//os:ios"],
    )

    ios_ui_test(
        name = name + "UITests",
        minimum_os_version = MINIMUM_OS_VERSION,
        runner = "//tools/apple:ios_simulator",
        test_host = name,
        visibility = ["//visibility:public"],
        deps = [name + "UITestsLib"],
    )

    swift_format_test(
        name = "swift_format",
        srcs = native.glob(["**/*.swift"]),
    )
