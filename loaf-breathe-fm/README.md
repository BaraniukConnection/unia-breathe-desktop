# Loaf Breathe - FM

Файловий менеджер для Unia Breathe — форк [Loaf](https://github.com/m-uvex/loaf-fm) (Rust + Qt6 Quick/QML,
Material 3 Expressive) від m_uvex. Автор дав згоду на форк для Oxygen Theme Family (розмова на Reddit).
Окремого файлу ліцензії в оригіналі немає, але його README заявляє MIT; оригінальний README — `UPSTREAM-README.md`,
звідки й на якому коміті взято код — `UPSTREAM`.

## Встановлення

Збирається з цього коду під системний Qt 6.11 (той самий, що в Quickshell). Готові пакунки з релізу Loaf
на Fedora 44 не запускаються: tarball, .deb і .pkg зібрані під несистемний Qt (`Qt_6_PRIVATE_API`),
а Qt усередині AppImage вимагає glibc 2.44 (у Fedora 44 — 2.43).

```bash
sudo dnf install cargo rust cmake ninja-build gcc-c++ pkgconf-pkg-config qt6-qtbase-devel qt6-qtbase-private-devel qt6-qtdeclarative-devel qt6-qtsvg-devel qt6-qtwayland-devel
./install.sh        # збирає, якщо ще не зібрано; команда loaf-breathe + пункт меню «Loaf Breathe - FM»
```

## Зміни під Unia Breathe

Інтерфейс — QML у `qml/` (`Theme.qml` — кольори й токени, `main.qml` — вікно, `components/` — кнопки, меню, діалоги),
логіка — `src/bridge.rs`. QML вкомпільовано в бінарник, тож після змін треба перезібрати:

```bash
./build.sh && ./install.sh
```
