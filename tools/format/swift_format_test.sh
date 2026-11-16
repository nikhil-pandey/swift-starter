#!/usr/bin/env bash
# Fails when Swift sources don't match .swift-format. Fix with `bazel run //tools/format`.
set -euo pipefail

config="$1"
shift
xcrun swift-format lint --strict --configuration "$config" "$@"
