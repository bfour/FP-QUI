use std::collections::HashMap;
use std::sync::Mutex;
use std::time::Duration;

use serde::{Deserialize, Serialize};
use tauri::{AppHandle, LogicalPosition, Manager, Monitor, WebviewUrl, WebviewWindowBuilder};
use uuid::Uuid;

use crate::config::{self, Corner};

/// A monitor as presented to the frontend for the "screen" setting.
#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct MonitorInfo {
    pub name: String,
    pub width: u32,
    pub height: u32,
    pub primary: bool,
}

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
///
/// The actual window is built on a freshly spawned thread, not the calling
/// thread: on Windows, `WebviewWindowBuilder::build()` deadlocks if called
/// synchronously from the main/event-loop thread (e.g. from a Tauri command
/// or the single-instance plugin's window-message handler), since WebView2
/// initialization needs that thread's message loop to be free
/// (see https://github.com/tauri-apps/wry/issues/583).
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
    let until_click = spec.until_click;
    let delay = spec.delay_ms.unwrap_or(config.default_duration_ms);

    log::info!(
        "showing notification {id} at ({x}, {y}) for {}",
        if until_click || delay == 0 {
            "until it is clicked".to_string()
        } else {
            format!("{delay} ms")
        }
    );

    let app_handle = app.clone();
    let id_for_thread = id.clone();
    std::thread::spawn(move || {
        let window = WebviewWindowBuilder::new(&app_handle, &label, WebviewUrl::App("index.html".into()))
            .title("FP-QUI Notification")
            .inner_size(width as f64, height as f64)
            .position(x, y)
            .decorations(false)
            .transparent(true)
            .always_on_top(true)
            .skip_taskbar(true)
            .shadow(false)
            .resizable(false)
            .focused(false)
            .visible(true)
            .build();

        match window {
            Ok(_) => {
                if !until_click && delay > 0 {
                    std::thread::sleep(Duration::from_millis(delay as u64));
                    if let Err(error) = dismiss(&app_handle, &id_for_thread) {
                        log::error!("could not dismiss notification {id_for_thread}: {error}");
                    }
                }
            }
            Err(error) => {
                log::error!("could not create the window for notification {id_for_thread}: {error}");
                // The notification never made it onto the screen, so drop it
                // from the stack instead of leaving a gap in the layout.
                if let Err(error) = dismiss(&app_handle, &id_for_thread) {
                    log::error!("could not clean up notification {id_for_thread}: {error}");
                }
            }
        }
    });

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
            if let Err(error) = window.set_position(LogicalPosition::new(x, y)) {
                log::warn!("could not reposition notification {id}: {error}");
            }
        }
    }

    Ok(())
}

/// Computes the top-left position (in logical pixels, matching
/// `WebviewWindowBuilder::position`/`inner_size`) for the notification at the
/// given stack index, anchored to the configured corner of the configured
/// monitor's work area (i.e. excluding the taskbar). This is the Rust
/// equivalent of _getOptimalPos() / $dispatcherArea in positioning.au3.
fn compute_position(
    app: &AppHandle,
    config: &config::AppConfig,
    corner_override: Option<Corner>,
    index: usize,
) -> (f64, f64) {
    let monitor = target_monitor(app, config);

    // Monitor geometry is reported in physical pixels; window position/size
    // are set in logical pixels, so convert using the monitor's scale factor.
    let (origin_x, origin_y, area_w, area_h) = match &monitor {
        Some(monitor) => {
            let scale = monitor.scale_factor();
            let work_area = monitor.work_area();
            (
                work_area.position.x as f64 / scale,
                work_area.position.y as f64 / scale,
                work_area.size.width as f64 / scale,
                work_area.size.height as f64 / scale,
            )
        }
        None => (0.0, 0.0, 1920.0, 1080.0),
    };

    let width = config.notification_width as f64;
    let height = config.notification_height as f64;
    let margin_x = config.margin_x as f64;
    let margin_y = config.margin_y as f64;
    let stack_offset = index as f64 * (height + config.gap as f64);
    let corner = corner_override.unwrap_or(config.corner);

    match corner {
        Corner::TopLeft => (origin_x + margin_x, origin_y + margin_y + stack_offset),
        Corner::TopRight => (
            origin_x + area_w - width - margin_x,
            origin_y + margin_y + stack_offset,
        ),
        Corner::BottomLeft => (
            origin_x + margin_x,
            origin_y + area_h - height - margin_y - stack_offset,
        ),
        Corner::BottomRight => (
            origin_x + area_w - width - margin_x,
            origin_y + area_h - height - margin_y - stack_offset,
        ),
    }
}

/// Resolves the monitor that notifications should be shown on, based on
/// `config.screen` (an index into `available_monitors()`, falling back to
/// the primary monitor if unset or out of range).
fn target_monitor(app: &AppHandle, config: &config::AppConfig) -> Option<Monitor> {
    let window = app.get_webview_window("main")?;
    let monitors = window.available_monitors().unwrap_or_default();

    if let Some(index) = config.screen {
        if let Some(monitor) = monitors.get(index) {
            return Some(monitor.clone());
        }
    }

    window
        .primary_monitor()
        .ok()
        .flatten()
        .or_else(|| monitors.into_iter().next())
}

/// Lists the available monitors, for the "screen" setting in the UI.
pub fn list_monitors(app: &AppHandle) -> Vec<MonitorInfo> {
    let Some(window) = app.get_webview_window("main") else {
        return Vec::new();
    };
    let monitors = window.available_monitors().unwrap_or_default();
    let primary_name = window.primary_monitor().ok().flatten().and_then(|m| m.name().cloned());

    monitors
        .iter()
        .enumerate()
        .map(|(i, monitor)| MonitorInfo {
            name: monitor
                .name()
                .cloned()
                .unwrap_or_else(|| format!("Screen {}", i + 1)),
            width: monitor.size().width,
            height: monitor.size().height,
            primary: monitor.name() == primary_name.as_ref(),
        })
        .collect()
}
