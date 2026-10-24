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

Інтерфейс — QML у `qml/` (`Theme.qml` — кольори й токени, `main.qml` — вікно, `Sidebar.qml`, `FilePane.qml`,
`components/` — кнопки, меню, діалоги), логіка — `src/` (Rust) і `cpp/`. QML вкомпільовано в бінарник,
тож після змін треба перезібрати:

```bash
./build.sh
```

Оновити код з оригіналу: взяти свіжу гілку `dev`, перенести файли й записати коміт в `UPSTREAM`.
