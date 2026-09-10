mod cli;
mod config;
mod legacy;
mod notification;
mod theme;

use config::AppConfig;
use notification::{MonitorInfo, NotificationSpec, NotificationState};
use theme::SystemTheme;
use tauri::menu::{Menu, MenuItem, PredefinedMenuItem};
use tauri::tray::TrayIconBuilder;
use tauri::{AppHandle, Emitter, Manager};
use tauri_plugin_autostart::{ManagerExt, MacosLauncher};
use tauri_plugin_log::{Target, TargetKind};

#[tauri::command]
async fn show_notification(app: AppHandle, spec: NotificationSpec) -> Result<String, String> {
    notification::show(&app, spec).map_err(|error| {
        log::error!("could not show notification: {error}");
        error.to_string()
    })
}

#[tauri::command]
async fn dismiss_notification(app: AppHandle, id: String) -> Result<(), String> {
    notification::dismiss(&app, &id).map_err(|error| {
        log::error!("could not dismiss notification {id}: {error}");
        error.to_string()
    })
}

#[tauri::command]
fn get_notification_spec(app: AppHandle, id: String) -> Option<NotificationSpec> {
    let state = app.state::<NotificationState>();
    let specs = state.specs.lock().unwrap();
    specs.get(&id).cloned()
}

/// Reports the host OS notification look (rounded vs. square corners, dark vs.
/// light theme) so notification windows can match it.
#[tauri::command]
fn get_system_theme(app: AppHandle) -> SystemTheme {
    theme::current(&app)
}

#[tauri::command]
fn get_config(app: AppHandle) -> AppConfig {
    config::load(&app)
}

#[tauri::command]
async fn set_config(app: AppHandle, config: AppConfig) -> Result<(), String> {
    config::save(&app, &config).map_err(|error| {
        log::error!("could not save the configuration: {error}");
        error.to_string()
    })?;
    notification::reposition_all(&app).map_err(|error| error.to_string())
}

/// True while the first-start assistant still has to be shown. Drives which
/// page the main window opens on (see App.tsx).
#[tauri::command]
fn is_first_run(app: AppHandle) -> bool {
    config::is_first_run(&app)
}

/// Records that the first-start assistant was completed or skipped. Passing
/// `completed: false` puts it back, which is how Settings offers to run it again.
#[tauri::command]
fn set_first_run_completed(app: AppHandle, completed: bool) -> Result<(), String> {
    config::set_first_run_completed(&app, completed).map_err(|error| {
        log::error!("could not store the first-run flag: {error}");
        error.to_string()
    })
}

/// Opens the folder the log file is written to, for when someone needs to
/// look at (or attach) it. Replaces the log path shown by _log.au3.
#[tauri::command]
fn open_log_dir(app: AppHandle) -> Result<(), String> {
    use tauri_plugin_opener::OpenerExt;

    let dir = app
        .path()
        .app_log_dir()
        .map_err(|error| format!("could not determine the log directory: {error}"))?;
    // The directory only exists once something has been logged to it.
    std::fs::create_dir_all(&dir).map_err(|error| error.to_string())?;
    app.opener()
        .open_path(dir.to_string_lossy(), None::<&str>)
        .map_err(|error| error.to_string())
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
async fn list_monitors(app: AppHandle) -> Vec<MonitorInfo> {
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

    result.map(|_| ()).map_err(|error| {
        log::error!("could not run command `{cmd}`: {error}");
        error.to_string()
    })
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
    if let Err(error) = notification::show(app, spec) {
        log::error!("could not show the test notification: {error}");
    }
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
    let builder = tauri::Builder::default()
        .plugin(
            // Replaces _log.au3: one rotating file in the OS log directory
            // (reachable from Settings), plus stdout when run from a terminal.
            tauri_plugin_log::Builder::new()
                .targets([
                    Target::new(TargetKind::Stdout),
                    Target::new(TargetKind::LogDir {
                        file_name: Some("fp-qui".into()),
                    }),
                ])
                .level(log::LevelFilter::Info)
                .max_file_size(512 * 1024)
                .rotation_strategy(tauri_plugin_log::RotationStrategy::KeepOne)
                .build(),
        )
        .plugin(tauri_plugin_single_instance::init(|app, args, _cwd| {
            if let Some(spec) = cli::parse_notify_arg(&args) {
                if let Err(error) = notification::show(app, spec) {
                    log::error!("could not show the requested notification: {error}");
                }
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
            get_system_theme,
            get_config,
            set_config,
            set_autostart,
            get_autostart,
            list_monitors,
            run_command,
            is_first_run,
            set_first_run_completed,
            open_log_dir,
        ])
        .setup(|app| {
            log::info!("FP-QUI {} starting", app.package_info().version);

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
            let check_updates =
                MenuItem::with_id(app, "check_updates", "Check for Updates", true, None::<&str>)?;
            let separator = PredefinedMenuItem::separator(app)?;
            let quit = MenuItem::with_id(app, "quit", "Quit", true, None::<&str>)?;

            let menu = Menu::with_items(
                app,
                &[
                    &open_settings,
                    &generate_code,
                    &test_notification,
                    &check_updates,
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
                    // The frontend turns this into "open Settings and check".
                    "check_updates" => show_main_window(app, Some("updates")),
                    "quit" => app.exit(0),
                    _ => {}
                })
                .build(app)?;

            // Handle `--notify <json>` passed on the initial launch (e.g. when
            // the app wasn't running yet and the OS started a fresh instance).
            let args: Vec<String> = std::env::args().collect();
            let notify_arg = cli::parse_notify_arg(&args);
            let handle = app.handle().clone();

            if let Some(spec) = notify_arg {
                if let Err(error) = notification::show(&handle, spec) {
                    log::error!("could not show the requested notification: {error}");
                }
            } else if config::is_first_run(&handle) {
                // Nothing is configured yet and the user launched the app
                // rather than sending a notification: walk them through the
                // essentials (see firstStartHandling.au3).
                show_main_window(&handle, None);
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
        });

    // Self-update is desktop-only; tauri-plugin-process supplies the restart
    // that has to follow an installed update.
    #[cfg(desktop)]
    let builder = builder
        .plugin(tauri_plugin_updater::Builder::new().build())
        .plugin(tauri_plugin_process::init());

    builder
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
