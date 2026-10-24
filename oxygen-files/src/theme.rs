//! System appearance: dark mode detection and wallpaper palettes
//! (matugen / pywal / quickshell), plus host information. Moved unchanged
//! from the original bridge.rs.

use std::fs;
use std::path::{Path, PathBuf};

fn run_cmd_stdout(cmd: &str, args: &[&str]) -> Option<String> {
    let output = std::process::Command::new(cmd).args(args).output().ok()?;
    if !output.status.success() {
        return None;
    }
    Some(String::from_utf8_lossy(&output.stdout).trim().to_string())
}

fn dark_from_gsettings() -> Option<bool> {
    let out = run_cmd_stdout("gsettings", &["get", "org.gnome.desktop.interface", "color-scheme"])?;
    let s = out.to_lowercase();
    if s.contains("prefer-dark") {
        Some(true)
    } else if s.contains("prefer-light") {
        Some(false)
    } else {
        // "default"/unset means "no preference": try the next source.
        None
    }
}

fn dark_from_portal() -> Option<bool> {
    let out = run_cmd_stdout(
        "gdbus",
        &[
            "call",
            "--session",
            "--dest",
            "org.freedesktop.portal.Desktop",
            "--object-path",
            "/org/freedesktop/portal/desktop",
            "--method",
            "org.freedesktop.portal.Settings.Read",
            "org.freedesktop.appearance",
            "color-scheme",
        ],
    )?;
    // Reply shape: (<uint32 1>,) where 0 = no preference, 1 = prefer dark, 2 = prefer light.
    if out.contains("uint32 1") {
        Some(true)
    } else if out.contains("uint32 2") {
        Some(false)
    } else {
        None
    }
}

fn dark_from_gtk_settings() -> Option<bool> {
    let home = std::env::var("HOME").unwrap_or_default();
    let candidates = [
        std::env::var("XDG_CONFIG_HOME").ok().map(|c| PathBuf::from(c).join("gtk-3.0/settings.ini")),
        std::env::var("XDG_CONFIG_HOME").ok().map(|c| PathBuf::from(c).join("gtk-4.0/settings.ini")),
        Some(PathBuf::from(&home).join(".config/gtk-3.0/settings.ini")),
        Some(PathBuf::from(&home).join(".config/gtk-4.0/settings.ini")),
    ];

    for candidate in candidates.into_iter().flatten() {
        let Ok(content) = fs::read_to_string(&candidate) else { continue };
        for line in content.lines() {
            let line = line.trim();
            let Some((key, value)) = line.split_once('=') else { continue };
            if key.trim() != "gtk-application-prefer-dark-theme" {
                continue;
            }
            let v = value.trim().to_lowercase();
            if v == "1" || v == "true" || v == "yes" || v == "on" {
                return Some(true);
            }
            if v == "0" || v == "false" || v == "no" || v == "off" {
                return Some(false);
            }
        }
    }
    None
}

/// Detection order: gsettings -> XDG desktop portal -> GTK settings.ini -> dark.
pub fn detect_system_dark_mode() -> bool {
    if let Some(dark) = dark_from_gsettings() {
        return dark;
    }
    if let Some(dark) = dark_from_portal() {
        return dark;
    }
    if let Some(dark) = dark_from_gtk_settings() {
        return dark;
    }
    true
}

pub fn read_system_hostname() -> String {
    if let Ok(s) = fs::read_to_string("/proc/sys/kernel/hostname") {
        let trimmed = s.trim();
        if !trimmed.is_empty() {
            return trimmed.to_string();
        }
    }
    "PC".to_string()
}

pub fn normalize_wallpaper_colors(content: &str) -> String {
    let Ok(val) = serde_json::from_str::<serde_json::Value>(content) else {
        return content.to_string();
    };

    if val.get("primary").and_then(|v| v.as_str()).is_some()
        && val.get("background").and_then(|v| v.as_str()).is_some()
    {
        return content.to_string();
    }

    if let Some(colors) = val.get("colors") {
        let special = val.get("special");
        let bg = special.and_then(|s| s.get("background")).and_then(|v| v.as_str())
            .or_else(|| colors.get("color0").and_then(|v| v.as_str()))
            .unwrap_or("#121214");
        let fg = special.and_then(|s| s.get("foreground")).and_then(|v| v.as_str())
            .or_else(|| colors.get("color7").and_then(|v| v.as_str()))
            .unwrap_or("#e4e2de");
        let primary = colors.get("color4").and_then(|v| v.as_str())
            .or_else(|| colors.get("color1").and_then(|v| v.as_str()))
            .unwrap_or("#a3c9fe");
        let secondary = colors.get("color2").and_then(|v| v.as_str())
            .or_else(|| colors.get("color6").and_then(|v| v.as_str()))
            .unwrap_or("#89b4fa");
        let surface_container = colors.get("color0").and_then(|v| v.as_str()).unwrap_or("#18191a");
        let surface_container_high = colors.get("color8").and_then(|v| v.as_str()).unwrap_or("#282a2b");
        let outline = colors.get("color8").and_then(|v| v.as_str()).unwrap_or("#8d9199");

        let mut out = serde_json::Map::new();
        out.insert("primary".to_string(), serde_json::json!(primary));
        out.insert("on_primary".to_string(), serde_json::json!(bg));
        out.insert("primary_container".to_string(), serde_json::json!(primary));
        out.insert("on_primary_container".to_string(), serde_json::json!(fg));
        out.insert("secondary_container".to_string(), serde_json::json!(secondary));
        out.insert("on_secondary_container".to_string(), serde_json::json!(fg));
        out.insert("background".to_string(), serde_json::json!(bg));
        out.insert("on_background".to_string(), serde_json::json!(fg));
        out.insert("surface".to_string(), serde_json::json!(bg));
        out.insert("on_surface".to_string(), serde_json::json!(fg));
        out.insert("on_surface_variant".to_string(), serde_json::json!(fg));
        out.insert("surface_container".to_string(), serde_json::json!(surface_container));
        out.insert("surface_container_high".to_string(), serde_json::json!(surface_container_high));
        out.insert("surface_container_highest".to_string(), serde_json::json!(surface_container_high));
        out.insert("surface_container_low".to_string(), serde_json::json!(surface_container));
        out.insert("surface_container_lowest".to_string(), serde_json::json!(bg));
        out.insert("outline".to_string(), serde_json::json!(outline));
        out.insert("outline_variant".to_string(), serde_json::json!(surface_container_high));

        return serde_json::to_string(&out).unwrap_or_else(|_| content.to_string());
    }

    content.to_string()
}

/// Returns (source_path, content, mtime_secs) for the first readable color source.
pub fn read_wallpaper_colors_source() -> Option<(String, String, u64)> {
    let home = std::env::var("HOME").unwrap_or_default();
    let candidates = [
        format!("{}/.local/state/quickshell/user/generated/colors.json", home),
        format!("{}/.cache/wal/colors.json", home),
        format!("{}/.cache/matugen/colors.json", home),
        format!("{}/.config/matugen/colors.json", home),
        format!("{}/.cache/DankMaterialShell/dms-colors.json", home),
        format!("{}/.cache/current_wallpaper_palette.json", home),
    ];

    for path_str in candidates {
        let path = Path::new(&path_str);
        let Ok(raw_content) = fs::read_to_string(path) else { continue };
        let is_object = serde_json::from_str::<serde_json::Value>(&raw_content)
            .ok()
            .map(|v| v.is_object() && v.as_object().map(|o| !o.is_empty()).unwrap_or(false))
            .unwrap_or(false);
        if !is_object {
            continue;
        }
        let content = normalize_wallpaper_colors(&raw_content);
        let mtime = fs::metadata(path)
            .and_then(|m| m.modified())
            .ok()
            .and_then(|t| t.duration_since(std::time::UNIX_EPOCH).ok())
            .map(|d| d.as_secs())
            .unwrap_or(0);
        return Some((path_str, content, mtime));
    }
    None
}

pub fn read_wallpaper_colors() -> String {
    read_wallpaper_colors_source()
        .map(|(_, content, _)| content)
        .unwrap_or_else(|| "{}".to_string())
}


/// Whether the compositor blurs behind translucent windows (Hyprland's `decoration:blur:enabled`,
/// which Unia's "Blur" switch sets). Glass without blur is merely see-through, so the window goes
/// solid then. Asks Hyprland over its socket; anything else is assumed to blur.
pub fn detect_compositor_blur() -> bool {
    use std::io::{Read, Write};
    let (Ok(run), Ok(sig)) = (std::env::var("XDG_RUNTIME_DIR"), std::env::var("HYPRLAND_INSTANCE_SIGNATURE")) else {
        return true;
    };
    let Ok(mut sock) = std::os::unix::net::UnixStream::connect(format!("{run}/hypr/{sig}/.socket.sock")) else {
        return true;
    };
    let _ = sock.set_read_timeout(Some(std::time::Duration::from_millis(300)));
    if sock.write_all(b"j/getoption decoration:blur:enabled").is_err() {
        return true;
    }
    let mut out = String::new();
    let _ = sock.read_to_string(&mut out);
    serde_json::from_str::<serde_json::Value>(&out)
        .ok()
        .and_then(|v| v["int"].as_i64())
        .map(|i| i != 0)
        .unwrap_or(true)
}

pub fn detect_device_type() -> &'static str {
    if let Ok(chassis) = fs::read_to_string("/sys/class/dmi/id/chassis_type") {
        match chassis.trim() {
            "8" | "9" | "10" | "11" | "14" | "30" | "31" | "32" => return "laptop",
            _ => {}
        }
    }
    if Path::new("/sys/class/power_supply/BAT0").exists() || Path::new("/sys/class/power_supply/BAT1").exists() {
        return "laptop";
    }
    "desktop"
}
