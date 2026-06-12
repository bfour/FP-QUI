mod cli;
mod config;
mod legacy;
mod notification;

use config::AppConfig;
use notification::{MonitorInfo, NotificationSpec, NotificationState};
use tauri::menu::{Menu, MenuItem, PredefinedMenuItem};
use tauri::tray::TrayIconBuilder;
use tauri::{AppHandle, Emitter, Manager};
use tauri_plugin_autostart::{ManagerExt, MacosLauncher};

#[tauri::command]
fn show_notification(app: AppHandle, spec: NotificationSpec) -> Result<String, String> {
    notification::show(&app, spec).map_err(|e| e.to_string())
}

#[tauri::command]
fn dismiss_notification(app: AppHandle, id: String) -> Result<(), String> {
    notification::dismiss(&app, &id).map_err(|e| e.to_string())
}

#[tauri::command]
fn get_notification_spec(app: AppHandle, id: String) -> Option<NotificationSpec> {
    let state = app.state::<NotificationState>();
    let specs = state.specs.lock().unwrap();
    specs.get(&id).cloned()
}

#[tauri::command]
fn get_config(app: AppHandle) -> AppConfig {
    config::load(&app)
}

#[tauri::command]
fn set_config(app: AppHandle, config: AppConfig) -> Result<(), String> {
    config::save(&app, &config).map_err(|e| e.to_string())?;
    notification::reposition_all(&app).map_err(|e| e.to_string())
}

#[tauri::command]
fn set_autostart(app: AppHandle, enabled: bool) -> Result<(), String> {
    let manager = app.autolaunch();
    if enabled {
        manager.enable().map_err(|e| e.to_string())
    } else {
        manager.disable().map_err(|e| e.to_string())
    }
}

#[tauri::command]
fn get_autostart(app: AppHandle) -> Result<bool, String> {
    app.autolaunch().is_enabled().map_err(|e| e.to_string())
}

#[tauri::command]
fn list_monitors(app: AppHandle) -> Vec<MonitorInfo> {
    notification::list_monitors(&app)
}

/// Runs a notification button's command. Replaces executeCommand.au3 / doRun.au3.
#[tauri::command]
async fn run_command(app: AppHandle, cmd: String) -> Result<(), String> {
    use tauri_plugin_shell::ShellExt;

    #[cfg(target_os = "windows")]
    let result = app.shell().command("cmd").args(["/C", &cmd]).spawn();
    #[cfg(not(target_os = "windows"))]
    let result = app.shell().command("sh").args(["-c", &cmd]).spawn();

    result.map(|_| ()).map_err(|e| e.to_string())
}

fn show_demo_notification(app: &AppHandle) {
    let spec = NotificationSpec {
        id: String::new(),
        title: Some("FP-QUI".into()),
        text: "This is a test notification.".into(),
        text_color: None,
        bk_color: None,
        icon: None,
        sound: None,
        talk: None,
        delay_ms: None,
        until_click: false,
        buttons: vec![],
        corner: None,
    };
    let _ = notification::show(app, spec);
}

fn show_main_window(app: &AppHandle, navigate_to: Option<&str>) {
    if let Some(window) = app.get_webview_window("main") {
        let _ = window.show();
        let _ = window.set_focus();
        if let Some(target) = navigate_to {
            let _ = window.emit("navigate", target);
        }
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_single_instance::init(|app, args, _cwd| {
            if let Some(spec) = cli::parse_notify_arg(&args) {
                let _ = notification::show(app, spec);
            } else {
                show_main_window(app, None);
            }
        }))
        .plugin(tauri_plugin_store::Builder::default().build())
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_autostart::init(
            MacosLauncher::LaunchAgent,
            None,
        ))
        .plugin(tauri_plugin_opener::init())
        .manage(NotificationState::default())
        .invoke_handler(tauri::generate_handler![
            show_notification,
            dismiss_notification,
            get_notification_spec,
            get_config,
            set_config,
            set_autostart,
            get_autostart,
            list_monitors,
            run_command,
        ])
        .setup(|app| {
            let open_settings = MenuItem::with_id(app, "open_settings", "Settings", true, None::<&str>)?;
            let generate_code =
                MenuItem::with_id(app, "generate_code", "Generate Code", true, None::<&str>)?;
            let test_notification = MenuItem::with_id(
                app,
                "test_notification",
                "Send Test Notification",
                true,
                None::<&str>,
            )?;
            let separator = PredefinedMenuItem::separator(app)?;
            let quit = MenuItem::with_id(app, "quit", "Quit", true, None::<&str>)?;

            let menu = Menu::with_items(
                app,
                &[
                    &open_settings,
                    &generate_code,
                    &test_notification,
                    &separator,
                    &quit,
                ],
            )?;

            TrayIconBuilder::new()
                .icon(app.default_window_icon().unwrap().clone())
                .menu(&menu)
                .show_menu_on_left_click(true)
                .tooltip("FP-QUI")
                .on_menu_event(|app, event| match event.id.as_ref() {
                    "open_settings" => show_main_window(app, Some("settings")),
                    "generate_code" => show_main_window(app, Some("codegen")),
                    "test_notification" => show_demo_notification(app),
                    "quit" => app.exit(0),
                    _ => {}
                })
                .build(app)?;

            // Handle `--notify <json>` passed on the initial launch (e.g. when
            // the app wasn't running yet and the OS started a fresh instance).
            let args: Vec<String> = std::env::args().collect();
            if let Some(spec) = cli::parse_notify_arg(&args) {
                let handle = app.handle().clone();
                let _ = notification::show(&handle, spec);
            }

            Ok(())
        })
        .on_window_event(|window, event| {
            if window.label() == "main" {
                if let tauri::WindowEvent::CloseRequested { api, .. } = event {
                    api.prevent_close();
                    let _ = window.hide();
                }
            }
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
