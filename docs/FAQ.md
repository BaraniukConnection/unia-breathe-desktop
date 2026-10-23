# Unia Breathe — FAQ

Готові файли до відповідей лежать у [`system/`](../system). Це системні налаштування, тож встановлюються
вони з `sudo` і поза `install.sh`, лише якщо у вас та сама проблема.

---

## Після сну екран завис (NVIDIA)

**Як виглядає.** Після пробудження висить останній кадр: екран блокування напівпрозорий або застиглий,
введення пароля нічого не змінює, курсора не видно. Перезапуск hyprlock з консолі не допомагає,
бо завис не замок, а вивід зображення.

> Курсора не видно на екрані блокування завжди: так задано в `hypr/hyprlock.conf` (`hide_cursor = true`).
> Сам собою це не ознака зависання.

**Як перевірити, що причина в драйвері.** Після зависання (з консолі Ctrl+Alt+F3 або вже після
перезавантаження: `-b -1` — попереднє завантаження):

```bash
journalctl -b -1 -k | grep -E 'NVRM|nvidia-drm.*ERROR|PM: suspend'
```

Ознаки, що це воно:

- `NVRM: … Out of memory [NV_ERR_NO_MEMORY]` біля `PM: suspend entry`. Драйверу не вистачило
  оперативної пам'яті, щоб зберегти відеопам'ять на час сну.
- `[nvidia-drm] … Failed to register auto-value-update on pre-wait value for sync` після пробудження.
  Hyprland більше не може вивести новий кадр.

**Що робити: зберігати відеопам'ять на диск.**

1. Переконайтесь, що каталог для файлу на диску, а не в пам'яті (tmpfs), і що на ньому вільного місця
   не менше, ніж відеопам'яті (`nvidia-smi --query-gpu=memory.total --format=csv`):

   ```bash
   findmnt -no FSTYPE -T /var/tmp   # не має бути tmpfs
   df -h /var/tmp
   ```

2. Поставте налаштування драйвера ([`system/nvidia-sleep.conf`](../system/nvidia-sleep.conf)). Якщо
   `/var/tmp` не підходить, у файлі замініть шлях на інший каталог на диску:

   ```bash
   sudo cp system/nvidia-sleep.conf /etc/modprobe.d/nvidia-sleep.conf
   ```

3. Перезберіть initramfs своїм дистрибутивом і перезавантажтесь:

   | Дистрибутив | Команда |
   |---|---|
   | Fedora, RHEL | `sudo dracut -f` |
   | Arch | `sudo mkinitcpio -P` |
   | Debian, Ubuntu | `sudo update-initramfs -u` |

4. Перевірте, що драйвер підхопив налаштування:

   ```bash
   grep -E 'PreserveVideoMemoryAllocations|TemporaryFilePath' /proc/driver/nvidia/params
   # PreserveVideoMemoryAllocations: 1
   # TemporaryFilePath: "/var/tmp"
   ```

5. **Лише для систем із SELinux** (Fedora, RHEL; перевірка: `getenforce` показує `Enforcing`). Якщо тепер
   сон скасовується й у журналі з'явились такі рядки:

   ```
   NVRM: The temporary file path specified via the NVreg_TemporaryFilePath module parameter could not be opened (error -13)
   NVRM: FBSR: could not reserve space for video memory preservation. Aborting suspend.
   ```

   значить, SELinux не дає драйверу писати файл: це відбувається від імені `systemd-sleep`.
   Переконайтесь, що відмова саме ця:

   ```bash
   journalctl -b -1 | grep 'avc:  denied' | grep systemd-sleep
   # … scontext=…systemd_sleep_t… tcontext=…tmp_t… tclass=file
   ```

   Зберіть і встановіть невелике правило ([`system/nvidia-sleep.te`](../system/nvidia-sleep.te)). Воно дозволяє
   `systemd-sleep` лише працювати з файлами в `/var/tmp`:

   ```bash
   cd /tmp && cp ~/unia-breathe/system/nvidia-sleep.te .
   checkmodule -M -m -o nvidia-sleep.mod nvidia-sleep.te
   semodule_package -o nvidia-sleep.pp -m nvidia-sleep.mod
   sudo semodule -i nvidia-sleep.pp      # перезавантаження не потрібне
   ```

   Якщо ви обрали в кроці 2 інший каталог, мітка в ньому може бути іншою, ніж `tmp_t`. Подивіться її
   (`ls -Zd /ваш/каталог`) і замініть `tmp_t` у `.te`. Якщо відмова в журналі виглядає інакше, правило
   можна згенерувати з неї: `journalctl -b -1 | grep 'avc:  denied' | audit2allow -M nvidia-sleep`
   (далі `sudo semodule -i nvidia-sleep.pp`). Таке правило покриває лише ту відмову, що вже сталась.
   Наприклад, читання файлу після пробудження з'явиться в журналі лише наступного разу, тож крок
   доведеться повторити.
   Прибрати правило: `sudo semodule -r nvidia-sleep`.

**А ще — кнопка «Сон».** У Unia Breathe кнопка «Сон» (панель керування, меню ⏻) і автоматичний сон з hypridle
йдуть через `bin/unia-sleep`: спершу екран повністю блокується, і лише потім система засинає. Якщо у вашому
конфігу сон викликається напряму через `systemctl suspend`, hyprlock запускається вже посеред засинання,
не встигає з'явитись і після пробудження зависає так само.

---

## Після сну не працює бездротовий донгл (клавіатура, миша…)

**Як виглядає.** Після пробудження бездротова клавіатура чи миша не реагує, а по кабелю той самий пристрій
працює. Якщо витягнути й вставити донгл, теж запрацює.

**Чому.** На час сну донгл втрачає живлення чи зв'язок із пристроєм, а ядро (USB persist) вважає його тим самим,
уже налаштованим, і заново не підключає. Для системи донгл «живий», але натиски від нього не надходять.

**Що робити: перепідключати донгл після кожного пробудження.**

1. Знайдіть донгл:

   ```bash
   lsusb
   # Bus 001 Device 002: ID 379a:1807 HATOR 2.4G 1K
   #                        ^^^^ ^^^^
   #                    idVendor idProduct
   ```

   Не плутайте донгл із самим пристроєм, підключеним кабелем: у них може бути той самий `idVendor`, але інший
   `idProduct` (у HATOR: донгл `379a:1807`, клавіатура по кабелю `379a:1806`). Якщо не певні, запустіть `lsusb`
   двічі: з донглом і без нього.

2. Впишіть його в `DEVICES` у скрипті [`system/usb-dongle-reset`](../system/usb-dongle-reset). Кілька донглів
   пишуться через пробіл:

   ```sh
   DEVICES="379a:1807 046d:c548"
   ```

3. Перевірте вручну, що перепідключення допомагає: поки донгл не працює після сну, запустіть

   ```bash
   sudo sh system/usb-dongle-reset post
   ```

   За пів секунди донгл має запрацювати. У журналі (`journalctl -t usb-dongle-reset`) з'явиться
   `reconnected 379a:1807`.

4. Встановіть скрипт, щоб systemd запускав його після кожного пробудження:

   ```bash
   sudo install -m 755 system/usb-dongle-reset /usr/lib/systemd/system-sleep/usb-dongle-reset
   ```

   Прибрати: `sudo rm /usr/lib/systemd/system-sleep/usb-dongle-reset`.
