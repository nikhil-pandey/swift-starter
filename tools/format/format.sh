#!/usr/bin/env bash
# Formats Swift with Apple's swift-format and Rust with rustfmt from the Bazel Rust toolchain.
set -euo pipefail

rustfmt="$PWD/$1"
cd "$BUILD_WORKSPACE_DIRECTORY"
xcrun swift-format format --in-place --recursive --parallel apps
"$rustfmt"
