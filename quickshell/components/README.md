# Компоненти Unia Breathe

Частини, які плануються як окремі компоненти (не лише всередині Unia Breathe).
Розвиваються в гілці `components`, у `main` підключаються оболонкою.

| Компонент | Що це | Скрипти | Від оболонки бере |
|---|---|---|---|
| `tile-menu/` | **TileMenu** — меню програм: пошук, папки з плитками, «Усі програми», обрані (`Apps`, `Menu`) | — | `theme/`, `services/` (Popups, Media, Events, Prefs, Windows), `settings-box` |
| `settings-box/` | **SettingsBox** — налаштування: панель категорій, програми праворуч, власні сторінки (`Settings`, `HyprOpts`) | — | `theme/`, `services/` (Prefs, Popups), `popups/` |
| `window-drop/` | **WindowDrop** — виїмка-«крапля» посередині верхньої рамки вікна, росте з наближенням курсора: тягнути (вікно стає квадратом), меню — згорнути, на весь екран, закрити, на інший стіл (`Drops`) | — | `theme/`, `services/` (Windows) |
| `scenarios/` | **Scenarios** — сценарії столів: збереження/відкриття розкладок (`Scenarios`) | `bin/unia-scenario` | `theme/`, `services/` (Popups, Windows), `popups/` |

Щоб винести компонент окремо, йому знадобляться лише `theme/` і ті сервіси з колонки праворуч.
