#!/usr/bin/env bash
# Ставить Loaf Breathe - FM для поточного користувача (повторний запуск безпечний).
# Готові пакунки з релізу Loaf на Fedora 44 не запускаються (tarball/.deb/.pkg — несистемний Qt,
# AppImage — glibc 2.44), тож ставимо власну збірку під системний Qt.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

[ -x "$DIR/target/release/loaf" ] || "$DIR/build.sh"

mkdir -p ~/.local/bin ~/.local/share/applications ~/.local/share/icons/hicolor
ln -sfn "$DIR/target/release/loaf" ~/.local/bin/loaf-breathe
cp -r "$DIR/packaging/icons/hicolor/"* ~/.local/share/icons/hicolor/
# Hyprland і Quickshell запущені без ~/.local/bin у PATH — у пункті меню потрібен повний шлях
sed "s|^Exec=loaf-breathe|Exec=$HOME/.local/bin/loaf-breathe|" "$DIR/packaging/loaf-breathe-fm.desktop" > ~/.local/share/applications/loaf-breathe-fm.desktop
command -v update-desktop-database >/dev/null && update-desktop-database ~/.local/share/applications 2>/dev/null || true
command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor 2>/dev/null || true
echo "Loaf Breathe - FM встановлено. Запуск: loaf-breathe"
