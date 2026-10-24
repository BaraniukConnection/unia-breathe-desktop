# Oxygen Files [loaf fm fork]

Файловий менеджер для Unia Breathe та Oxygen Theme Family — форк [Loaf](https://github.com/m-uvex/loaf-fm)
(Rust + Qt6 Quick/QML, Material 3 Expressive) від m_uvex. Автор дав згоду на форк (розмова на Reddit).
Окремого файлу ліцензії в оригіналі немає, але його README заявляє MIT; оригінальний README — `UPSTREAM-README.md`,
звідки й на якому коміті взято код — `UPSTREAM`.

Код береться з гілки `dev` оригіналу: туди автор зливає всі зміни, а `main` стоїть на релізі v0.1.0.
У `dev` уже виправлено прив'язку до системи автора, яку ми знайшли у v0.1.0: стандартні теки з англійськими
назвами замість XDG, «Home» на `/home/m_uvex`, термінал і системні іконки лише з шляхів NixOS, «Projects»
і `~/Projects/loaf` у частих теках.

## Встановлення

Збирається з цього коду під системний Qt 6.11 (той самий, що в Quickshell). Готові пакунки з релізу Loaf
на Fedora 44 не запускаються: tarball, .deb і .pkg зібрані під несистемний Qt (`Qt_6_PRIVATE_API`),
а Qt усередині AppImage вимагає glibc 2.44 (у Fedora 44 — 2.43).

```bash
sudo dnf install cargo rust cmake ninja-build gcc-c++ pkgconf-pkg-config qt6-qtbase-devel qt6-qtbase-private-devel qt6-qtdeclarative-devel qt6-qtsvg-devel qt6-qtwayland-devel
./install.sh        # збирає, якщо ще не зібрано; команда oxygen-files + пункт меню «Oxygen Files»
```

## Зміни під Unia Breathe

- **Палітра «Unia»** (типова): темна — з оболонки (`quickshell/theme/Theme.qml`: тло `#0b2a26`, акцент `#10b981`),
  світла — з Vision DesignSystem. `qml/Theme.qml`, палітра `unia`.
- **Скло**: тло вікна й панелі напівпрозорі, Hyprland розмиває те, що за вікном. Налаштування → Interface →
  Transparency (Off · Low · Medium · Unia = 0.35, як у оболонки). Меню й діалоги лишаються щільними: розмиття діє
  лише на те, що за вікном, а не на вміст під меню. Прозорий буфер вмикає `cpp/native.cpp`.
- **Шрифт Manrope** (за Vision DesignSystem) вбудований і ставиться шрифтом застосунку в `cpp/native.cpp`.
- **Значок Oxygen Files** з Vision DesignSystem (`assets/oxygen-files.svg`): шапка бічної панелі, «About», пункт меню.
  `app_id` вікна — `oxygen-files`.
- **Disks** на сторінці «This PC», між Places і Frequent: картка на кожен диск (`qml/components/DiskCard.qml`) —
  велика іконка, назва, вільно, зайнято / всього, шкала. Клік відкриває диск (або монтує), права кнопка — меню диска.
  Старі секції Internal / External Storage типово сховані.
- **Власні значки** (як у Kando): права кнопка на теці, пункті бічної панелі чи диску → Change Icon…
  Набори: системна тема значків, Simple Icons (просто або в кольорах брендів), Material Symbols, emoji,
  власні теми (теки з SVG/PNG у `~/.config/loaf/icon-themes/<тема>/`) і будь-яке зображення за шляхом, URL
  чи data: URI. Значок теки видно в сітці, списку й бічній панелі. Набори вбудовані (`assets/icon-sets/`), вибір
  зберігається в налаштуваннях (`customIcons`).
- Декоративні плями на тлі показуються лише без скла (Transparency: Off).
- Меню View відкривається під кнопкою: позиція рахувалась від стрілки, а не від кнопки (баг оригіналу).
- Диски тепер зчитуються одразу при запуску (`src/core.rs`); в оригіналі — лише після зміни пристроїв,
  тож «This PC» після старту був без дисків.


Інтерфейс — QML у `qml/` (`Theme.qml` — кольори й токени, `main.qml` — вікно, `Sidebar.qml`, `FilePane.qml`,
`components/` — кнопки, меню, діалоги), логіка — `src/` (Rust) і `cpp/`. QML вкомпільовано в бінарник,
тож після змін треба перезібрати:

```bash
./build.sh
```

Оновити код з оригіналу: взяти свіжу гілку `dev`, перенести файли й записати коміт в `UPSTREAM`.

## Можливі внески в оригінал

Баги Loaf, виправлені в нас, які можуть знадобитися й автору. Спершу перевірити, чи їх уже не виправив хтось у гілці
`dev` (користувач відкриває дискусію); якщо ні — підготувати PR.

- **Диски не зчитуються при запуску** (знайдено на `dev` 8877dc1). `load_drives()` викликав лише DeviceWatcher при
  зміні пристроїв, тож «This PC» після старту був без дисків, поки щось не підключиш. Фікс — один виклик
  `self.as_mut().load_drives();` в `initialize()` у `src/core.rs`.
- **Меню View з'їжджає вбік** (`dev` 8877dc1). У `qml/main.qml` позиція рахується `mapToItem` від MouseArea
  стрілки, а не від `viewDropdownButton`, тож меню зміщене на відстань від краю кнопки до стрілки. Фікс —
  `viewDropdownButton.mapToItem(...)`.
