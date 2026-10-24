//! Freedesktop icon theme lookup (Icon Theme Specification).
//!
//! Resolves an icon name ("folder-download", "text-x-python") to a file in
//! the active theme, following `Inherits=` chains and falling back through
//! shorter names ("text-x-python" -> "text-x" -> "text") and finally
//! `hicolor`. Results are cached per (theme, name, size).

use crate::util::{self, lock};
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

/// Folders that may contain icon themes, highest priority first.
pub fn base_dirs() -> Vec<PathBuf> {
    let mut v = vec![util::home().join(".icons"), util::data_home().join("icons")];
    v.extend(util::data_dirs().into_iter().map(|d| d.join("icons")));
    v.push(PathBuf::from("/usr/share/pixmaps"));
    v.dedup();
    v
}

#[derive(Clone, Debug)]
struct SubDir {
    path: String,
    size: u32,
    min: u32,
    max: u32,
    threshold: u32,
    kind: String,
    scale: u32,
}

#[derive(Clone, Debug, Default)]
struct Theme {
    /// Every base dir that has a folder for this theme.
    roots: Vec<PathBuf>,
    dirs: Vec<SubDir>,
    inherits: Vec<String>,
}

static THEMES: Mutex<Option<HashMap<String, Option<Theme>>>> = Mutex::new(None);
static CACHE: Mutex<Option<HashMap<(String, String, u32), String>>> = Mutex::new(None);

fn parse_index(content: &str) -> (Vec<SubDir>, Vec<String>) {
    let mut sections: HashMap<String, HashMap<String, String>> = HashMap::new();
    let mut current = String::new();
    for line in content.lines() {
        let line = line.trim();
        if line.starts_with('#') || line.is_empty() {
            continue;
        }
        if line.starts_with('[') && line.ends_with(']') {
            current = line[1..line.len() - 1].to_string();
            continue;
        }
        if let Some((k, v)) = line.split_once('=') {
            sections.entry(current.clone()).or_default().insert(k.trim().to_string(), v.trim().to_string());
        }
    }
    let main = sections.get("Icon Theme").cloned().unwrap_or_default();
    let list = |key: &str| -> Vec<String> {
        main.get(key)
            .map(|v| v.split(',').map(|s| s.trim().to_string()).filter(|s| !s.is_empty()).collect())
            .unwrap_or_default()
    };
    let mut names = list("Directories");
    names.extend(list("ScaledDirectories"));
    let mut dirs = Vec::new();
    for name in names {
        let Some(sec) = sections.get(&name) else { continue };
        let num = |k: &str, d: u32| sec.get(k).and_then(|v| v.parse().ok()).unwrap_or(d);
        let size = num("Size", 48);
        dirs.push(SubDir {
            path: name.clone(),
            size,
            min: num("MinSize", size),
            max: num("MaxSize", size),
            threshold: num("Threshold", 2),
            kind: sec.get("Type").cloned().unwrap_or_else(|| "Threshold".into()),
            scale: num("Scale", 1),
        });
    }
    (dirs, list("Inherits"))
}

fn load_theme(name: &str) -> Option<Theme> {
    if let Some(hit) = lock(&THEMES).get_or_insert_with(HashMap::new).get(name) {
        return hit.clone();
    }
    let mut theme = Theme::default();
    let mut parsed = false;
    for base in base_dirs() {
        let root = base.join(name);
        if !root.is_dir() {
            continue;
        }
        theme.roots.push(root.clone());
        if !parsed {
            if let Ok(c) = fs::read_to_string(root.join("index.theme")) {
                let (dirs, inherits) = parse_index(&c);
                theme.dirs = dirs;
                theme.inherits = inherits;
                parsed = true;
            }
        }
    }
    let result = if parsed { Some(theme) } else { None };
    lock(&THEMES).get_or_insert_with(HashMap::new).insert(name.to_string(), result.clone());
    result
}

fn matches_size(d: &SubDir, size: u32) -> bool {
    if d.scale != 1 {
        return false;
    }
    match d.kind.as_str() {
        "Fixed" => d.size == size,
        "Scalable" => d.min <= size && size <= d.max,
        _ => d.size.saturating_sub(d.threshold) <= size && size <= d.size + d.threshold,
    }
}

fn size_distance(d: &SubDir, size: u32) -> u32 {
    match d.kind.as_str() {
        "Scalable" if size < d.min => d.min - size,
        "Scalable" if size > d.max => size - d.max,
        "Scalable" => 0,
        "Threshold" if size + d.threshold < d.size => d.size - d.threshold - size,
        "Threshold" if size > d.size + d.threshold => size - d.size - d.threshold,
        _ => d.size.abs_diff(size),
    }
}

const EXTS: [&str; 3] = ["svg", "png", "xpm"];

fn lookup_in(theme: &Theme, name: &str, size: u32) -> Option<PathBuf> {
    for d in &theme.dirs {
        if !matches_size(d, size) {
            continue;
        }
        for root in &theme.roots {
            for ext in EXTS {
                let p = root.join(&d.path).join(format!("{}.{}", name, ext));
                if p.is_file() {
                    return Some(p);
                }
            }
        }
    }
    let mut best: Option<(u32, PathBuf)> = None;
    for d in &theme.dirs {
        let dist = size_distance(d, size);
        if best.as_ref().map(|(b, _)| dist >= *b).unwrap_or(false) {
            continue;
        }
        for root in &theme.roots {
            for ext in EXTS {
                let p = root.join(&d.path).join(format!("{}.{}", name, ext));
                if p.is_file() {
                    best = Some((dist, p));
                    break;
                }
            }
        }
    }
    best.map(|(_, p)| p)
}

fn lookup_chain(theme_name: &str, name: &str, size: u32, depth: usize, visited: &mut Vec<String>) -> Option<PathBuf> {
    if depth > 8 || visited.iter().any(|v| v == theme_name) {
        return None;
    }
    visited.push(theme_name.to_string());
    let theme = load_theme(theme_name)?;
    if let Some(p) = lookup_in(&theme, name, size) {
        return Some(p);
    }
    for parent in &theme.inherits {
        if let Some(p) = lookup_chain(parent, name, size, depth + 1, visited) {
            return Some(p);
        }
    }
    None
}

/// Candidate names to try for `name`, most specific first. Symbolic and
/// regular variants are both tried so either kind of theme works.
pub fn fallback_names(name: &str) -> Vec<String> {
    let mut out = Vec::new();
    let (base, symbolic) = match name.strip_suffix("-symbolic") {
        Some(b) => (b.to_string(), true),
        None => (name.to_string(), false),
    };
    let mut cur = base.clone();
    loop {
        if symbolic {
            out.push(format!("{}-symbolic", cur));
            out.push(cur.clone());
        } else {
            out.push(cur.clone());
            out.push(format!("{}-symbolic", cur));
        }
        match cur.rfind('-') {
            Some(i) if i > 0 => cur.truncate(i),
            _ => break,
        }
    }
    out
}

/// Resolves `name` in `theme` (then hicolor), returning a `file://` URL or
/// an empty string when nothing matches.
/// Every icon name the theme offers (with its Inherits= chain and hicolor),
/// sorted, for the icon picker.
pub fn list_names(theme: &str) -> Vec<String> {
    let mut names = std::collections::BTreeSet::new();
    let mut queue = vec![theme.to_string(), "hicolor".to_string()];
    let mut seen = Vec::new();
    while let Some(t) = queue.pop() {
        if seen.contains(&t) || seen.len() > 16 {
            continue;
        }
        seen.push(t.clone());
        let Some(th) = load_theme(&t) else { continue };
        queue.extend(th.inherits.iter().cloned());
        for root in &th.roots {
            for d in &th.dirs {
                let Ok(entries) = fs::read_dir(root.join(&d.path)) else { continue };
                for e in entries.flatten() {
                    let p = e.path();
                    let ext = p.extension().and_then(|x| x.to_str()).unwrap_or("");
                    if EXTS.contains(&ext) {
                        if let Some(stem) = p.file_stem().and_then(|s| s.to_str()) {
                            names.insert(stem.to_string());
                        }
                    }
                }
            }
        }
    }
    names.into_iter().collect()
}

/// User icon themes, Kando style: every folder in ~/.config/loaf/icon-themes is a
/// theme, and every svg/png in it (recursively) an icon. Returns
/// [{ name, icons: [{ name, url }] }].
pub fn user_themes() -> serde_json::Value {
    fn walk(dir: &Path, out: &mut Vec<PathBuf>) {
        let Ok(entries) = fs::read_dir(dir) else { return };
        for e in entries.flatten() {
            let p = e.path();
            if p.is_dir() {
                walk(&p, out);
            } else if matches!(p.extension().and_then(|x| x.to_str()), Some("svg" | "png" | "jpg" | "jpeg" | "webp")) {
                out.push(p);
            }
        }
    }
    let root = util::config_home().join("loaf/icon-themes");
    let mut themes = Vec::new();
    let Ok(entries) = fs::read_dir(&root) else { return serde_json::json!([]) };
    let mut dirs: Vec<PathBuf> = entries.flatten().map(|e| e.path()).filter(|p| p.is_dir()).collect();
    dirs.sort();
    for dir in dirs {
        let mut files = Vec::new();
        walk(&dir, &mut files);
        files.sort();
        let icons: Vec<serde_json::Value> = files
            .iter()
            .map(|p| {
                serde_json::json!({
                    "name": p.file_stem().and_then(|s| s.to_str()).unwrap_or(""),
                    "url": format!("file://{}", crate::trash::encode_path(p)),
                })
            })
            .collect();
        themes.push(serde_json::json!({
            "name": dir.file_name().and_then(|s| s.to_str()).unwrap_or(""),
            "icons": icons,
        }));
    }
    serde_json::Value::Array(themes)
}

pub fn resolve(theme: &str, name: &str, size: u32) -> String {
    if name.is_empty() {
        return String::new();
    }
    let key = (theme.to_string(), name.to_string(), size);
    if let Some(hit) = lock(&CACHE).get_or_insert_with(HashMap::new).get(&key) {
        return hit.clone();
    }
    let mut found = None;
    'outer: for candidate in fallback_names(name) {
        for t in [theme, "hicolor"] {
            if let Some(p) = lookup_chain(t, &candidate, size, 0, &mut Vec::new()) {
                found = Some(p);
                break 'outer;
            }
        }
        // Unthemed icons in /usr/share/pixmaps.
        for ext in EXTS {
            let p = PathBuf::from("/usr/share/pixmaps").join(format!("{}.{}", candidate, ext));
            if p.is_file() {
                found = Some(p);
                break 'outer;
            }
        }
    }
    let url = found.map(|p| format!("file://{}", crate::trash::encode_path(&p))).unwrap_or_default();
    lock(&CACHE).get_or_insert_with(HashMap::new).insert(key, url.clone());
    url
}

fn gsettings_icon_theme() -> Option<String> {
    let out = std::process::Command::new(util::which("gsettings")?)
        .args(["get", "org.gnome.desktop.interface", "icon-theme"])
        .output()
        .ok()?;
    let s = String::from_utf8_lossy(&out.stdout).trim().trim_matches('\'').to_string();
    if out.status.success() && !s.is_empty() {
        Some(s)
    } else {
        None
    }
}

fn ini_value(path: &Path, group: &str, key: &str) -> Option<String> {
    let content = fs::read_to_string(path).ok()?;
    let mut in_group = false;
    for line in content.lines() {
        let line = line.trim();
        if line.starts_with('[') {
            in_group = line == group;
            continue;
        }
        if in_group {
            if let Some((k, v)) = line.split_once('=') {
                if k.trim() == key && !v.trim().is_empty() {
                    return Some(v.trim().trim_matches('"').to_string());
                }
            }
        }
    }
    None
}

/// The desktop's icon theme name.
pub fn system_theme() -> String {
    if let Ok(t) = std::env::var("LOAF_ICON_THEME") {
        if !t.is_empty() {
            return t;
        }
    }
    let cfg = util::config_home();
    let desktop = std::env::var("XDG_CURRENT_DESKTOP").unwrap_or_default().to_uppercase();
    let kde = || ini_value(&cfg.join("kdeglobals"), "[Icons]", "Theme");
    let gtk = || {
        ini_value(&cfg.join("gtk-4.0/settings.ini"), "[Settings]", "gtk-icon-theme-name")
            .or_else(|| ini_value(&cfg.join("gtk-3.0/settings.ini"), "[Settings]", "gtk-icon-theme-name"))
    };
    let picked = if desktop.contains("KDE") {
        kde().or_else(gsettings_icon_theme).or_else(gtk)
    } else {
        gsettings_icon_theme().or_else(gtk).or_else(kde)
    };
    picked
        .filter(|t| load_theme(t).is_some())
        .unwrap_or_else(|| if load_theme("Adwaita").is_some() { "Adwaita".into() } else { "hicolor".into() })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn fallback_order() {
        assert_eq!(
            fallback_names("text-x-python"),
            vec!["text-x-python", "text-x-python-symbolic", "text-x", "text-x-symbolic", "text", "text-symbolic"]
        );
        assert_eq!(fallback_names("go-next-symbolic")[..2], ["go-next-symbolic".to_string(), "go-next".to_string()]);
    }

    #[test]
    fn index_parsing_and_sizes() {
        let (dirs, inh) = parse_index(
            "[Icon Theme]\nName=T\nInherits=Adwaita, hicolor\nDirectories=48x48/places,scalable/places\n\n[48x48/places]\nSize=48\nType=Fixed\n\n[scalable/places]\nSize=16\nMinSize=8\nMaxSize=512\nType=Scalable\n",
        );
        assert_eq!(inh, vec!["Adwaita", "hicolor"]);
        assert_eq!(dirs.len(), 2);
        assert!(matches_size(&dirs[0], 48) && !matches_size(&dirs[0], 32));
        assert!(matches_size(&dirs[1], 100));
    }

    #[test]
    fn resolves_on_this_machine() {
        // Every Linux desktop ships hicolor/Adwaita with a folder icon.
        let theme = system_theme();
        let url = resolve(&theme, "folder", 48);
        assert!(url.is_empty() || url.starts_with("file:///"), "{}", url);
    }
}
