//! Detection of the host system's notification look, so our own notification
//! windows blend in instead of always drawing the same rounded dark card.
//!
//! Two things are reported:
//!   * the corner style of the shell — Windows 11 rounds its toasts, Windows 10
//!     and earlier draw them square with a thin border;
//!   * whether the user runs the dark or the light system theme.

use serde::Serialize;
use tauri::{AppHandle, Manager, Theme};

/// First Windows 11 build. Windows 11 kept the 10.0 major/minor version, so the
/// build number is the only reliable way to tell the two apart.
#[cfg(windows)]
const WINDOWS_11_BUILD: u32 = 22000;

/// The parts of the system look a notification needs to match.
#[derive(Debug, Clone, Copy, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SystemTheme {
    /// True when the shell draws rounded window corners (Windows 11 and later).
    pub rounded: bool,
    /// Corner radius in CSS pixels, matching the shell's own notifications.
    pub corner_radius: u32,
    /// True when the user's apps are set to the dark system theme.
    pub dark: bool,
}

/// Reads the current system theme. Cheap enough to call per notification
/// window; the OS version part is constant, the dark/light part is not (the
/// user can flip it at any time, including while a notification is on screen).
pub fn current(app: &AppHandle) -> SystemTheme {
    let (rounded, corner_radius) = shell_corners();

    SystemTheme {
        rounded,
        corner_radius,
        dark: matches!(app_theme(app), Theme::Dark),
    }
}

/// The corner style of the host shell's own notifications.
fn shell_corners() -> (bool, u32) {
    #[cfg(windows)]
    {
        if os_build() >= WINDOWS_11_BUILD {
            // Windows 11 toasts use an 8px radius.
            (true, 8)
        } else {
            // Windows 10 and earlier: square toasts with a hairline border.
            (false, 0)
        }
    }

    #[cfg(target_os = "macos")]
    {
        (true, 12)
    }

    #[cfg(all(not(windows), not(target_os = "macos")))]
    {
        (true, 8)
    }
}

/// The light/dark theme the OS reports for this app. Tauri resolves this from
/// the platform's own setting (on Windows, `AppsUseLightTheme`), so we do not
/// have to read the registry ourselves.
fn app_theme(app: &AppHandle) -> Theme {
    app.get_webview_window("main")
        .or_else(|| app.webview_windows().into_values().next())
        .and_then(|window| window.theme().ok())
        .unwrap_or(Theme::Light)
}

/// The real OS build number.
///
/// `GetVersionEx` reports a capped version unless the executable carries a
/// compatibility manifest listing every Windows release, so `RtlGetVersion` —
/// which is not subject to that shimming — is used instead.
#[cfg(windows)]
fn os_build() -> u32 {
    use std::sync::OnceLock;

    #[repr(C)]
    struct OsVersionInfoW {
        os_version_info_size: u32,
        major_version: u32,
        minor_version: u32,
        build_number: u32,
        platform_id: u32,
        csd_version: [u16; 128],
    }

    #[link(name = "ntdll")]
    extern "system" {
        fn RtlGetVersion(info: *mut OsVersionInfoW) -> i32;
    }

    static BUILD: OnceLock<u32> = OnceLock::new();

    *BUILD.get_or_init(|| {
        let mut info = OsVersionInfoW {
            os_version_info_size: std::mem::size_of::<OsVersionInfoW>() as u32,
            major_version: 0,
            minor_version: 0,
            build_number: 0,
            platform_id: 0,
            csd_version: [0; 128],
        };

        // SAFETY: `info` is a correctly sized, fully initialised OSVERSIONINFOW,
        // which is all RtlGetVersion writes to. It cannot fail for a valid struct.
        let status = unsafe { RtlGetVersion(&mut info) };
        if status == 0 {
            info.build_number
        } else {
            0
        }
    })
}
