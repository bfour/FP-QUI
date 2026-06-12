use serde::{Deserialize, Serialize};
use tauri::AppHandle;
use tauri_plugin_store::StoreExt;

const STORE_FILE: &str = "config.json";
const CONFIG_KEY: &str = "config";

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
    /// Default time a notification stays visible, in milliseconds. 0 = until clicked.
    pub default_duration_ms: u32,
    pub default_bg_color: String,
    pub default_text_color: String,
    pub sound_enabled: bool,
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
            default_duration_ms: 8000,
            default_bg_color: "#2b2b3a".into(),
            default_text_color: "#f5f5f5".into(),
            sound_enabled: true,
            tts_enabled: false,
            margin_x: 16,
            margin_y: 16,
            notification_width: 340,
            notification_height: 110,
            gap: 10,
        }
    }
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
