#!/usr/bin/env bash
# Builds Oxygen Files from this code against the system Qt (output: target/release/loaf).
set -euo pipefail
cd "$(dirname "$0")"

missing=()
for c in cargo cmake ninja g++ pkg-config; do command -v "$c" >/dev/null || missing+=("$c"); done
[ -e /usr/lib64/cmake/Qt6Qml/Qt6QmlConfig.cmake ] || missing+=(qt6-devel)
if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing: ${missing[*]}. On Fedora:" >&2
    echo "  sudo dnf install cargo rust cmake ninja-build gcc-c++ pkgconf-pkg-config qt6-qtbase-devel qt6-qtbase-private-devel qt6-qtdeclarative-devel qt6-qtsvg-devel qt6-qtwayland-devel" >&2
    exit 1
fi

cargo build --release
echo "Built: $PWD/target/release/loaf. ./install.sh will now install this build"
