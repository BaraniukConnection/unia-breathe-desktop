# Unia Breathe Desktop: FAQ

Ready-made files for these answers live in [`system/`](../system). They are system settings, so they are installed
with `sudo` and outside `install.sh`, and only if you have the same problem.

---

## The screen hangs after sleep (NVIDIA)

**What it looks like.** After resume the last frame stays on screen: the lock screen is half transparent or frozen,
typing the password changes nothing, and there is no cursor. Restarting hyprlock from a console does not help,
because it is not the lock that hangs but the display output.

> The lock screen never shows a cursor: `hypr/hyprlock.conf` sets `hide_cursor = true`.
> On its own that is not a sign of a hang.

**How to check that the driver is the cause.** After a hang (from a console with Ctrl+Alt+F3, or after a
reboot with `-b -1`, the previous boot):

```bash
journalctl -b -1 -k | grep -E 'NVRM|nvidia-drm.*ERROR|PM: suspend'
```

Signs that this is it:

- `NVRM: … Out of memory [NV_ERR_NO_MEMORY]` next to `PM: suspend entry`. The driver did not have enough
  RAM to save video memory for the duration of sleep.
- `[nvidia-drm] … Failed to register auto-value-update on pre-wait value for sync` after resume.
  Hyprland can no longer present a new frame.

**The fix: save video memory to disk.**

1. Make sure the directory for the file is on disk, not in memory (tmpfs), and that it has at least as much
   free space as the card has video memory (`nvidia-smi --query-gpu=memory.total --format=csv`):

   ```bash
   findmnt -no FSTYPE -T /var/tmp   # must not be tmpfs
   df -h /var/tmp
   ```

2. Install the driver settings ([`system/nvidia-sleep.conf`](../system/nvidia-sleep.conf)). If `/var/tmp` does not
   fit, replace the path in the file with another directory on disk:

   ```bash
   sudo cp system/nvidia-sleep.conf /etc/modprobe.d/nvidia-sleep.conf
   ```

3. Rebuild the initramfs the way your distribution does it, and reboot:

   | Distribution | Command |
   |---|---|
   | Fedora, RHEL | `sudo dracut -f` |
   | Arch | `sudo mkinitcpio -P` |
   | Debian, Ubuntu | `sudo update-initramfs -u` |

4. Check that the driver picked the settings up:

   ```bash
   grep -E 'PreserveVideoMemoryAllocations|TemporaryFilePath' /proc/driver/nvidia/params
   # PreserveVideoMemoryAllocations: 1
   # TemporaryFilePath: "/var/tmp"
   ```

5. **Only on systems with SELinux** (Fedora, RHEL; check with `getenforce`, which prints `Enforcing`). If sleep is
   now cancelled and these lines show up in the journal:

   ```
   NVRM: The temporary file path specified via the NVreg_TemporaryFilePath module parameter could not be opened (error -13)
   NVRM: FBSR: could not reserve space for video memory preservation. Aborting suspend.
   ```

   then SELinux does not let the driver write the file: that happens on behalf of `systemd-sleep`.
   Make sure this is the denial:

   ```bash
   journalctl -b -1 | grep 'avc:  denied' | grep systemd-sleep
   # … scontext=…systemd_sleep_t… tcontext=…tmp_t… tclass=file
   ```

   Build and install a small rule ([`system/nvidia-sleep.te`](../system/nvidia-sleep.te)). It only lets
   `systemd-sleep` work with files in `/var/tmp`:

   ```bash
   cd /tmp && cp ~/unia-breathe/system/nvidia-sleep.te .
   checkmodule -M -m -o nvidia-sleep.mod nvidia-sleep.te
   semodule_package -o nvidia-sleep.pp -m nvidia-sleep.mod
   sudo semodule -i nvidia-sleep.pp      # no reboot needed
   ```

   If you picked another directory in step 2, its label may differ from `tmp_t`. Look it up
   (`ls -Zd /your/directory`) and replace `tmp_t` in the `.te` file. If the denial in your journal looks different, the rule
   can be generated from it: `journalctl -b -1 | grep 'avc:  denied' | audit2allow -M nvidia-sleep`
   (then `sudo semodule -i nvidia-sleep.pp`). Such a rule covers only the denial that already happened.
   For example, reading the file back after resume shows up in the journal only the next time, so the step
   may need repeating.
   To remove the rule: `sudo semodule -r nvidia-sleep`.

**And the Sleep button.** In Unia Breathe Desktop the Sleep button (control centre, the ⏻ menu) and automatic sleep
from hypridle go through `bin/unia-sleep`: the screen locks completely first, and only then does the system sleep. If your
config calls `systemctl suspend` directly, hyprlock starts in the middle of suspending, does not finish appearing,
and hangs the same way after resume.

---

## A wireless dongle stops working after sleep (keyboard, mouse…)

**What it looks like.** After resume a wireless keyboard or mouse does not respond, while the same device works
over a cable. Unplugging the dongle and plugging it back in also brings it back.

**Why.** During sleep the dongle loses power or its link to the device, but the kernel (USB persist) treats it as the
same, already configured device and does not reconnect it. To the system the dongle looks alive, but no input comes
through.

**The fix: reconnect the dongle after every resume.**

1. Find the dongle:

   ```bash
   lsusb
   # Bus 001 Device 002: ID 379a:1807 HATOR 2.4G 1K
   #                        ^^^^ ^^^^
   #                    idVendor idProduct
   ```

   Do not confuse the dongle with the device itself plugged in by cable: they may share an `idVendor` but have a
   different `idProduct` (for the HATOR: the dongle is `379a:1807`, the keyboard on a cable `379a:1806`). If unsure, run
   `lsusb` twice, with and without the dongle.

2. Put it into `DEVICES` in the script [`system/usb-dongle-reset`](../system/usb-dongle-reset). Separate several
   dongles with spaces:

   ```sh
   DEVICES="379a:1807 046d:c548"
   ```

3. Check by hand that reconnecting helps: while the dongle is dead after sleep, run

   ```bash
   sudo sh system/usb-dongle-reset post
   ```

   Within half a second the dongle should work. The journal (`journalctl -t usb-dongle-reset`) shows
   `reconnected 379a:1807`.

4. Install the script so systemd runs it after every resume:

   ```bash
   sudo install -m 755 system/usb-dongle-reset /usr/lib/systemd/system-sleep/usb-dongle-reset
   ```

   To remove it: `sudo rm /usr/lib/systemd/system-sleep/usb-dongle-reset`.
