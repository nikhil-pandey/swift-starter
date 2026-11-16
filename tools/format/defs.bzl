"""Formatting checks that run with `bazel test`."""

load("@rules_shell//shell:sh_test.bzl", "sh_test")

def swift_format_test(name, srcs, **kwargs):
    """Fails if `srcs` aren't formatted according to the repository's .swift-format.

    Args:
        name: Test name.
        srcs: Swift files to check.
        **kwargs: Passed to sh_test.
    """
    native.filegroup(name = name + "_srcs", srcs = srcs, testonly = True)
    sh_test(
        name = name,
        srcs = ["//tools/format:swift_format_test.sh"],
        args = ["$(rootpath //:.swift-format)", "$(rootpaths :{}_srcs)".format(name)],
        data = ["//:.swift-format", ":{}_srcs".format(name)],
        # Uses the Xcode toolchain's swift-format.
        tags = ["no-sandbox"],
        **kwargs
    )
