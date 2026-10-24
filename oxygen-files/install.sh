#!/usr/bin/env bash
# Installs Oxygen Files for the current user (safe to run again).
# The ready packages from the Loaf release do not start on Fedora 44 (tarball/.deb/.pkg: a non-system Qt;
# AppImage: glibc 2.44), so we install our own build against the system Qt.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

[ -x "$DIR/target/release/loaf" ] || "$DIR/build.sh"

# remove the previous name (Loaf Breathe - FM) and the Loaf icons
rm -f ~/.local/bin/loaf-breathe ~/.local/share/applications/loaf-breathe-fm.desktop
rm -f ~/.local/share/icons/hicolor/*/apps/loaf.png ~/.local/share/icons/hicolor/scalable/apps/loaf.svg

mkdir -p ~/.local/bin ~/.local/share/applications ~/.local/share/icons/hicolor
ln -sfn "$DIR/target/release/loaf" ~/.local/bin/oxygen-files
cp -r "$DIR/packaging/icons/hicolor/"* ~/.local/share/icons/hicolor/
# Hyprland and Quickshell run without ~/.local/bin in PATH, so the menu entry needs the full path
sed "s|^Exec=oxygen-files|Exec=$HOME/.local/bin/oxygen-files|" "$DIR/packaging/oxygen-files.desktop" > ~/.local/share/applications/oxygen-files.desktop
command -v update-desktop-database >/dev/null && update-desktop-database ~/.local/share/applications 2>/dev/null || true
command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor 2>/dev/null || true
echo "Oxygen Files is installed. Run: oxygen-files"
