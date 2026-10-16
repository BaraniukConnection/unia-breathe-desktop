#!/usr/bin/env bash
# Підключає Unia Breathe до системи симлінками (повторний запуск безпечний).
set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.config/quickshell ~/.config/unia-breathe
touch ~/.config/unia-breathe/hyprland.conf                # згенерований налаштуваннями; має існувати для source
ln -sfn "$REPO/quickshell" ~/.config/quickshell/unia      # запуск: qs -c unia
mkdir -p ~/.local/bin
for f in "$REPO"/bin/* "$REPO"/quickshell/components/*/bin/*; do ln -sfn "$f" ~/.local/bin/"$(basename "$f")"; done

# екран блокування (hyprlock читає ~/.config/hypr/hyprlock.conf)
ln -sfn "$REPO/hypr/hyprlock.conf" ~/.config/hypr/hyprlock.conf

# GTK: тема adw-gtk3-dark + палітра Unia Breathe
# якщо nwg-look поставив gtk.css симлінком на тему — підключаємо ту тему першою, а палітру Unia поверх неї
for v in 3 4; do
    f=~/.config/gtk-$v.0/gtk.css
    mkdir -p "$(dirname "$f")"
    base=""
    if [ -L "$f" ]; then base=$(readlink -f "$f"); rm "$f"; fi
    {
        echo "/* Unia Breathe */"
        [ -n "$base" ] && echo "@import url(\"file://$base\");"
        echo "@import url(\"file://$REPO/gtk/gtk$v.css\");"
    } > "$f"
done
gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
for f in ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini; do
    [ -f "$f" ] || printf '[Settings]\n' > "$f"
    sed -i '/^gtk-theme-name=/d; /^gtk-application-prefer-dark-theme=/d' "$f"
    sed -i 's/^\[Settings\]$/[Settings]\ngtk-theme-name=adw-gtk3-dark\ngtk-application-prefer-dark-theme=true/' "$f"
done

# kitty: палітра
grep -qF "unia-theme.conf" ~/.config/kitty/kitty.conf 2>/dev/null || printf '\n# Unia Breathe\ninclude %s/kitty/unia-theme.conf\n' "$REPO" >> ~/.config/kitty/kitty.conf

HYPR=~/.config/hypr/hyprland.conf
LINE="source = $REPO/hypr/unia.conf"
grep -qxF "$LINE" "$HYPR" || printf '\n# Unia Breathe\n%s\n' "$LINE" >> "$HYPR"

echo "Unia Breathe підключено: $REPO"
