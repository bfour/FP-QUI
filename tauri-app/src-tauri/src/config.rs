use serde::{Deserialize, Serialize};
use tauri::AppHandle;
use tauri_plugin_store::StoreExt;

const STORE_FILE: &str = "config.json";
const CONFIG_KEY: &str = "config";
/// Set once the first-start assistant has been completed or skipped, so it is
/// only shown to a fresh configuration (see firstStartHandling.au3).
const FIRST_RUN_KEY: &str = "firstRunCompleted";

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Corner {
    TopLeft,
    TopRight,
    BottomLeft,
    BottomRight,
}

/// User-configurable behaviour, persisted to `config.json` via tauri-plugin-store.
/// Mirrors the settings previously spread across initializeDefaults.au3 /
/// setConfiguration.au3 / setBehaviour.au3 / initializeColors.au3.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AppConfig {
    pub corner: Corner,
    /// Index into the list returned by `list_monitors`, selecting which
    /// screen notifications are shown on. `None` = primary monitor.
    #[serde(default)]
    pub screen: Option<usize>,
    /// Default time a notification stays visible, in milliseconds. 0 = until clicked.
    pub default_duration_ms: u32,
    /// When true, notifications take their colours from the Windows light/dark
    /// theme instead of `default_bg_color`/`default_text_color`. A colour set on
    /// an individual notification still wins over both. The corner style always
    /// follows the shell, independently of this setting.
    #[serde(default = "default_true")]
    pub use_system_theme: bool,
    pub default_bg_color: String,
    pub default_text_color: String,
    pub sound_enabled: bool,
    /// Sound played for notifications that don't bring their own. Either a
    /// bundled preset (`preset:<id>`, see src/lib/presets.ts), a file path or
    /// a URL. Empty = stay silent unless a notification asks for a sound.
    #[serde(default = "default_sound")]
    pub default_sound: String,
    pub tts_enabled: bool,
    pub margin_x: i32,
    pub margin_y: i32,
    pub notification_width: u32,
    pub notification_height: u32,
    pub gap: i32,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            corner: Corner::BottomRight,
            screen: None,
            default_duration_ms: 8000,
            use_system_theme: true,
            default_bg_color: "#2b2b3a".into(),
            default_text_color: "#f5f5f5".into(),
            sound_enabled: true,
            default_sound: default_sound(),
            tts_enabled: false,
            margin_x: 16,
            margin_y: 16,
            notification_width: 340,
            notification_height: 110,
            gap: 10,
        }
    }
}

fn default_true() -> bool {
    true
}

fn default_sound() -> String {
    "preset:chime".into()
}

pub fn load(app: &AppHandle) -> AppConfig {
    let store = match app.store(STORE_FILE) {
        Ok(store) => store,
        Err(_) => return AppConfig::default(),
    };

    match store.get(CONFIG_KEY) {
        Some(value) => serde_json::from_value(value).unwrap_or_default(),
        None => AppConfig::default(),
    }
}

pub fn save(app: &AppHandle, config: &AppConfig) -> tauri_plugin_store::Result<()> {
    let store = app.store(STORE_FILE)?;
    store.set(CONFIG_KEY, serde_json::to_value(config).expect("AppConfig is serializable"));
    store.save()?;
    Ok(())
}

/// True until the first-start assistant has been completed or skipped once.
/// A store that can't be opened counts as "not the first run", so a broken
/// store doesn't put the assistant in the user's way on every launch.
pub fn is_first_run(app: &AppHandle) -> bool {
    match app.store(STORE_FILE) {
        Ok(store) => !matches!(store.get(FIRST_RUN_KEY), Some(serde_json::Value::Bool(true))),
        Err(error) => {
            log::warn!("could not read the first-run flag: {error}");
            false
        }
    }
}

pub fn set_first_run_completed(app: &AppHandle, completed: bool) -> tauri_plugin_store::Result<()> {
    let store = app.store(STORE_FILE)?;
    store.set(FIRST_RUN_KEY, serde_json::Value::Bool(completed));
    store.save()?;
    Ok(())
}
