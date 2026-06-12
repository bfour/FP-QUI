use std::collections::HashMap;
use std::sync::Mutex;
use std::time::Duration;

use serde::{Deserialize, Serialize};
use tauri::{AppHandle, Manager, PhysicalPosition, PhysicalSize, WebviewUrl, WebviewWindowBuilder};
use uuid::Uuid;

use crate::config::{self, Corner};

/// A clickable action shown on a notification.
/// Mirrors the `<button><IDn><label>...</label><cmd>...</cmd></IDn></button>` tags
/// of the legacy AutoIt notification DSL.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct NotificationButton {
    pub label: String,
    /// Shell command to run when the button is clicked.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub cmd: Option<String>,
    /// URL to open when the button is clicked.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub url: Option<String>,
}

/// Describes a single notification to be shown.
/// Roughly equivalent to the tag-based "code" string previously sent to
/// FP-QUI via the command line or named pipes (see splashNotification.au3).
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct NotificationSpec {
    #[serde(default)]
    pub id: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub title: Option<String>,
    pub text: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub text_color: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub bk_color: Option<String>,
    /// Path or URL to an icon image.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub icon: Option<String>,
    /// Path or URL to a sound file to play when the notification is shown.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub sound: Option<String>,
    /// Text to read out via text-to-speech. If empty and tts is enabled, `text` is used.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub talk: Option<String>,
    /// Time the notification stays visible, in milliseconds.
    /// If `None`, the configured default duration is used.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub delay_ms: Option<u32>,
    /// If true, the notification stays open until the user clicks it/a button,
    /// regardless of `delay_ms`.
    #[serde(default)]
    pub until_click: bool,
    #[serde(default)]
    pub buttons: Vec<NotificationButton>,
    /// Overrides the configured screen corner for this notification only.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub corner: Option<Corner>,
}

/// Tracks currently visible notifications so they can be stacked and
/// repositioned as they appear/disappear (see positioning.au3 / _reflow).
#[derive(Default)]
pub struct NotificationState {
    pub specs: Mutex<HashMap<String, NotificationSpec>>,
    pub order: Mutex<Vec<String>>,
}

fn window_label(id: &str) -> String {
    format!("notif-{id}")
}

/// Creates and shows a new notification window, returning its id.
pub fn show(app: &AppHandle, mut spec: NotificationSpec) -> tauri::Result<String> {
    if spec.id.is_empty() {
        spec.id = Uuid::new_v4().to_string();
    }
    let id = spec.id.clone();
    let label = window_label(&id);

    let config = config::load(app);

    let index = {
        let state = app.state::<NotificationState>();
        let mut order = state.order.lock().unwrap();
        order.push(id.clone());
        let index = order.len() - 1;
        state.specs.lock().unwrap().insert(id.clone(), spec.clone());
        index
    };

    let (x, y) = compute_position(app, &config, spec.corner, index);
    let (width, height) = (config.notification_width, config.notification_height);

    WebviewWindowBuilder::new(app, &label, WebviewUrl::App("index.html".into()))
        .title("FP-QUI Notification")
        .inner_size(width as f64, height as f64)
        .position(x as f64, y as f64)
        .decorations(false)
        .transparent(true)
        .always_on_top(true)
        .skip_taskbar(true)
        .shadow(false)
        .resizable(false)
        .focused(false)
        .visible(true)
        .build()?;

    if !spec.until_click {
        let delay = spec.delay_ms.unwrap_or(config.default_duration_ms);
        if delay > 0 {
            let app_handle = app.clone();
            let id_for_timeout = id.clone();
            std::thread::spawn(move || {
                std::thread::sleep(Duration::from_millis(delay as u64));
                let _ = dismiss(&app_handle, &id_for_timeout);
            });
        }
    }

    Ok(id)
}

/// Closes a notification window and reflows the remaining ones into its place,
/// equivalent to _reflow() in positioning.au3.
pub fn dismiss(app: &AppHandle, id: &str) -> tauri::Result<()> {
    if let Some(window) = app.get_webview_window(&window_label(id)) {
        window.close()?;
    }

    let state = app.state::<NotificationState>();
    state.specs.lock().unwrap().remove(id);
    state.order.lock().unwrap().retain(|existing| existing != id);

    reposition_all(app)
}

/// Re-applies the stacked layout to all currently open notifications.
pub fn reposition_all(app: &AppHandle) -> tauri::Result<()> {
    let config = config::load(app);
    let state = app.state::<NotificationState>();

    let order = state.order.lock().unwrap().clone();
    let specs = state.specs.lock().unwrap().clone();

    for (index, id) in order.iter().enumerate() {
        if let Some(window) = app.get_webview_window(&window_label(id)) {
            let corner_override = specs.get(id).and_then(|spec| spec.corner);
            let (x, y) = compute_position(app, &config, corner_override, index);
            let _ = window.set_position(PhysicalPosition::new(x, y));
        }
    }

    Ok(())
}

/// Computes the top-left position for the notification at the given stack
/// index, anchored to the configured corner of the primary monitor.
/// This is the Rust equivalent of _getOptimalPos() in positioning.au3.
fn compute_position(
    app: &AppHandle,
    config: &config::AppConfig,
    corner_override: Option<Corner>,
    index: usize,
) -> (i32, i32) {
    let (screen_w, screen_h) = primary_monitor_size(app);

    let width = config.notification_width as i32;
    let height = config.notification_height as i32;
    let stack_offset = index as i32 * (height + config.gap);
    let corner = corner_override.unwrap_or(config.corner);

    match corner {
        Corner::TopLeft => (config.margin_x, config.margin_y + stack_offset),
        Corner::TopRight => (
            screen_w - width - config.margin_x,
            config.margin_y + stack_offset,
        ),
        Corner::BottomLeft => (
            config.margin_x,
            screen_h - height - config.margin_y - stack_offset,
        ),
        Corner::BottomRight => (
            screen_w - width - config.margin_x,
            screen_h - height - config.margin_y - stack_offset,
        ),
    }
}

fn primary_monitor_size(app: &AppHandle) -> (i32, i32) {
    app.get_webview_window("main")
        .and_then(|w| w.primary_monitor().ok().flatten())
        .map(|monitor| {
            let size: &PhysicalSize<u32> = monitor.size();
            (size.width as i32, size.height as i32)
        })
        .unwrap_or((1920, 1080))
}
