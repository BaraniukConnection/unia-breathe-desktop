# Компоненти Unia Breathe

Частини, які плануються як окремі компоненти (не лише всередині Unia Breathe).
Розвиваються в гілці `components`, у `main` підключаються оболонкою.

| Компонент | Що це | Скрипти | Від оболонки бере |
|---|---|---|---|
| `app-menu/` | Меню програм: пошук, папки з плитками, «Усі програми», обрані (`Apps`, `Menu`) | — | `theme/`, `services/` (Popups, Media, Events, Prefs, Windows), `settings` |
| `settings/` | Налаштування: панель категорій, програми праворуч, власні сторінки (`Settings`, `HyprOpts`) | — | `theme/`, `services/` (Prefs, Popups), `popups/` |
| `scenarios/` | Сценарії столів: збереження/відкриття розкладок (`Scenarios`) | `bin/unia-scenario` | `theme/`, `services/` (Popups, Windows), `popups/` |

Щоб винести компонент окремо, йому знадобляться лише `theme/` і ті сервіси з колонки праворуч.
