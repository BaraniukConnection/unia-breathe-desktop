#!/usr/bin/env bash
# Ставить Oxygen Files для поточного користувача (повторний запуск безпечний).
# Готові пакунки з релізу Loaf на Fedora 44 не запускаються (tarball/.deb/.pkg — несистемний Qt,
# AppImage — glibc 2.44), тож ставимо власну збірку під системний Qt.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

[ -x "$DIR/target/release/loaf" ] || "$DIR/build.sh"

# прибрати попередню назву (Loaf Breathe - FM)
rm -f ~/.local/bin/loaf-breathe ~/.local/share/applications/loaf-breathe-fm.desktop

mkdir -p ~/.local/bin ~/.local/share/applications ~/.local/share/icons/hicolor
ln -sfn "$DIR/target/release/loaf" ~/.local/bin/oxygen-files
cp -r "$DIR/packaging/icons/hicolor/"* ~/.local/share/icons/hicolor/
# Hyprland і Quickshell запущені без ~/.local/bin у PATH — у пункті меню потрібен повний шлях
sed "s|^Exec=oxygen-files|Exec=$HOME/.local/bin/oxygen-files|" "$DIR/packaging/oxygen-files.desktop" > ~/.local/share/applications/oxygen-files.desktop
command -v update-desktop-database >/dev/null && update-desktop-database ~/.local/share/applications 2>/dev/null || true
command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor 2>/dev/null || true
echo "Oxygen Files встановлено. Запуск: oxygen-files"
