#!/usr/bin/env bash
# Підключає Unia Breathe до системи симлінками (повторний запуск безпечний).
set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.config/quickshell ~/.config/unia-breathe
touch ~/.config/unia-breathe/hyprland.conf                # згенерований налаштуваннями; має існувати для source
ln -sfn "$REPO/quickshell" ~/.config/quickshell/unia      # запуск: qs -c unia
mkdir -p ~/.local/bin
for f in "$REPO"/bin/*; do ln -sfn "$f" ~/.local/bin/"$(basename "$f")"; done

HYPR=~/.config/hypr/hyprland.conf
LINE="source = $REPO/hypr/unia.conf"
grep -qxF "$LINE" "$HYPR" || printf '\n# Unia Breathe\n%s\n' "$LINE" >> "$HYPR"

echo "Unia Breathe підключено: $REPO"
