# Баги Loaf: прив'язка до системи автора

Оригінальний Loaf писався під NixOS автора (користувач `m_uvex`, англійські теки, свої програми й тема іконок).
Тут — місця, де це ламає роботу на іншій системі. Номери рядків — на коміті, де файл створено.

## Вирішені

1. **Стандартні теки з англійськими назвами в коді.** «Documents», «Downloads», «Pictures», «Music», «Videos»
   завжди вели на `~/Documents` тощо, а не на теки системи. На українській системі «Documents» відкривав
   майже порожню `~/Documents` замість `~/Документи`. Тепер шляхи беруться з XDG user-dirs
   (`~/.config/user-dirs.dirs`) через `user_dir()` у `src/bridge.rs`. Так працюють ліва панель, «This PC»,
   часті теки й рядок шляху.
2. **«Home» вела на `/home/m_uvex`.** Домашня тека обчислювалась із поточного шляху
   (`"/home/" + …split("/")[2] || "m_uvex"`): поза `/home` (у `/`, на іншому диску) «Home» відкривала теку
   автора. Тепер це `$HOME` (`qml/main.qml`, `qml/PCView.qml`).
3. **«Відкрити термінал» шукав kitty/foot у профілі NixOS автора** (`/etc/profiles/per-user/m_uvex/bin/…`),
   тож на будь-якій іншій системі вони не знаходились. Тепер пробує kitty, foot, потім `xdg-terminal-exec`
   через звичайний PATH (`open_terminal` у `src/bridge.rs`).

## Відкриті

1. **Системні іконки не шукаються в системі** (`resolve_system_icon`, `src/bridge.rs:214`). Шукає лише в
   `~/.local/share/icons`, `~/.icons` і `/run/current-system/sw/share/icons` (шлях NixOS), без
   `/usr/share/icons` і без `XDG_DATA_DIRS`. Теми іконок задані списком
   (`WhiteSur`, `Adwaita`, `Papirus`, `hicolor`) замість теми користувача (тут `breeze`). На Fedora стиль іконок
   «System» (експериментальний, у налаштуваннях) лишається без іконок.
2. **«Projects» у лівій панелі веде на `~/Projects`** (`qml/main.qml:1449`, `qml/PCView.qml:458`, `:522`).
   Це тека автора, стандартної такої немає; тут її нема, тож пункт відкриває неіснуючу теку.
3. **Часті теки за замовчуванням — тека проєкту автора**: `~/Projects/loaf` з найвищою вагою
   (`get_frequent_dirs`, `src/bridge.rs:1674`), а також `~/Projects` і `Pictures/Wallpapers`.
   Показуються лише якщо теки існують, тож нічого не ламають, але це підбірка під автора.
4. **Кольори зі шпалер — лише з pywal або matugen** (`~/.cache/wal/colors.json`, `~/.cache/matugen/colors.json`,
   `src/bridge.rs:364`). Без цих програм палітра «Wallpaper» стоїть на запасних кольорах. Для Unia Breathe
   це місце, куди можна підставити нашу палітру.

Не баги, а запасні шляхи для NixOS, які на Fedora просто нічого не знаходять: пошук програм у `/nix/store`,
`/run/current-system/sw/bin` та профілях Nix (`resolve_binary`, після звичайного PATH) і пропуск `/nix/store`
у списку дисків.
