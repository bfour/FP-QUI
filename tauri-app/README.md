# FP-QUI (Tauri rewrite)

A cross-platform, TypeScript/Rust rewrite of [FP-QUI](../readme.md), the
Windows-only AutoIt notification tool. The goal is to keep the same core
idea — a background tray app that shows highly customizable popup
notifications, controllable from the command line so it can be wired up to
other programs (Thunderbird, scripts, cron jobs, etc.) — while making it run
on Windows, macOS and Linux and be maintainable in TypeScript/Rust instead of
AutoIt + Delphi.

## Status

This is the initial scaffold and core notification pipeline:

- ✅ System tray icon with a menu (Settings, Generate Code, Send Test
  Notification, Quit)
- ✅ Frameless, transparent, always-on-top notification popups, stacked in a
  configurable corner of a configurable screen (work area, i.e. excluding
  the taskbar)
- ✅ Notification queue/positioning (reflow when a notification closes)
- ✅ Settings window (corner, duration, colors, sound/TTS toggles, layout,
  autostart)
- ✅ "Generate Code" page that builds a `--notify <json>` command, the
  replacement for the old code-generator GUI
- ✅ CLI-based IPC via Tauri's single-instance plugin (replaces the old
  named-pipe protocol used by `fpquisend`/`fpquitip`)
- ✅ Legacy `<text>...</text><bkColor>...</bkColor>` tag DSL compatibility
  layer via `--notify-legacy` (new app uses JSON by default, see below)
- ⬜ First-start wizard
- ⬜ Bundled sound presets / icon presets
- ⬜ Packaging & auto-update

## Architecture

```
tauri-app/
  src/                     # React + TypeScript frontend
    types.ts               # NotificationSpec / AppConfig (mirrors Rust types)
    lib/api.ts              # typed wrappers around `invoke()`
    App.tsx                  # picks a page based on the current window's label
    pages/
      Notification.tsx       # rendered in every "notif-<id>" window
      Settings.tsx            # rendered in the "main" window
      CodeGenerator.tsx        # rendered in the "main" window
  src-tauri/               # Rust backend
    src/
      lib.rs                # app setup, tray menu, commands, single-instance
      notification.rs        # NotificationSpec, window creation & stacking/positioning
      config.rs               # AppConfig, persisted via tauri-plugin-store
      cli.rs                   # parses `--notify <json>` / `--notify-legacy <tags>` from argv
      legacy.rs                # legacy `<text>...</text>` tag DSL -> NotificationSpec
```

### Windows

- `main` — hidden on startup, used for both the Settings and Generate Code
  pages (tabs). Closing it hides it instead of quitting (the app keeps
  running in the tray).
- `notif-<uuid>` — one per visible notification. Frameless, transparent,
  always-on-top, positioned by `notification.rs` according to the configured
  screen, corner and stacking order. Positioning uses each monitor's work
  area (`Monitor::work_area()`), so notifications don't overlap the taskbar,
  and accounts for the monitor's scale factor since window
  position/size are in logical pixels while monitor geometry is physical.

### Notification spec (JSON)

Replaces the old tag-based "code" string
(`<text>Hello</text><bkColor>purple</bkColor>...`). Example:

```json
{
  "title": "Build finished",
  "text": "All tests passed.",
  "bkColor": "#2b7a3a",
  "delayMs": 5000,
  "buttons": [
    { "label": "Open log", "cmd": "code build.log" }
  ]
}
```

Fields: `title`, `text` (required), `textColor`, `bkColor`, `icon` (path or
URL), `sound` (path or URL), `talk` (text to speak via TTS), `delayMs`
(0/omitted = use the configured default, omit + `untilClick: true` = stays
open until dismissed), `untilClick`, `buttons[]` (`label` + `cmd` and/or
`url`), `corner` (per-notification override of the configured screen corner).

### Command-line / IPC

The old `fpquisend`/`fpquitip` companion tools sent requests to the running
instance over a named pipe. The Tauri app uses
[`tauri-plugin-single-instance`](https://v2.tauri.app/plugin/single-instance/)
instead:

```sh
fp-qui --notify '{"title":"Hello","text":"World","delayMs":5000}'
```

If FP-QUI is already running, this argument is forwarded to the running
instance (via the single-instance plugin) and a new notification window is
created. If it's not running, the argument is read from `std::env::args()`
on first launch. No separate sender binary is needed — any process can just
invoke the FP-QUI executable with `--notify`.

#### Legacy tag-based syntax

Existing integrations that still send the old FP-QUI tag notation (e.g.
`<text>Hello</text><bkColor>purple</bkColor><delay>5000</delay>`) can use
`--notify-legacy` instead of `--notify`:

```sh
fp-qui --notify-legacy '<text>Hello</text><bkColor>purple</bkColor><delay>5000</delay>'
```

This is parsed by `legacy.rs` (a Rust port of `_commandLineInterpreter.au3`'s
nesting-aware tag parser) and mapped onto the same `NotificationSpec` used by
`--notify`. Only the tags that map onto `NotificationSpec` are understood
(`text`, `textColor`, `bkColor`, `ico`, `delay`, `untilClick`, `talk`,
`audio`, `button`); layout/internal-only legacy tags (`width`, `height`, `x`,
`y`, `font`, `dispatcherArea`, `GUID`, ...) and AutoIt macros/`%variable%`
substitutions are accepted but ignored.

## Development

Requires Node.js and Rust, plus the platform-specific
[Tauri prerequisites](https://v2.tauri.app/start/prerequisites/):

- **Windows**: the MSVC C++ build tools (the Rust `x86_64-pc-windows-msvc`
  target needs `link.exe`). Install
  [Build Tools for Visual Studio](https://visualstudio.microsoft.com/visual-cpp-build-tools/)
  and, in the installer, select the **"Desktop development with C++"**
  workload (this provides the MSVC linker + Windows SDK; plain VS Code is
  *not* sufficient). Also install
  [WebView2](https://developer.microsoft.com/microsoft-edge/webview2/)
  (preinstalled on Windows 11 / recent Windows 10).
  - If you get `error: linker 'link.exe' not found` when running
    `npm run tauri build`/`dev`, the C++ workload above is missing (or a
    fresh shell/IDE restart is needed so `PATH` picks up the new tools).
- **macOS**: Xcode Command Line Tools (`xcode-select --install`).
- **Linux**: `libwebkit2gtk-4.1-dev`, `libgtk-3-dev`,
  `libayatana-appindicator3-dev`, `librsvg2-dev` (and a C compiler/linker,
  e.g. `build-essential`).

```sh
npm install
npm run tauri dev    # run in development
npm run tauri build  # produce a release bundle
```

`npm run build` type-checks and builds the frontend only (no native
dependencies required). `cargo check` / `cargo build` in `src-tauri/` build
the Rust backend.

## Migration mapping (old AutoIt modules -> new equivalent)

| Old module | New equivalent |
| --- | --- |
| `trayMainMenu.au3`, `trayMenu.kxf` | Tray menu in `lib.rs` (`setup()`) |
| `splashNotification.au3` | `notification::show()` + `pages/Notification.tsx` |
| `positioning.au3` | `notification::compute_position()` / `reposition_all()` |
| `initializeNotificationsArrays.au3` | `NotificationState` in `notification.rs` |
| `doAudio.au3`, `doBeep.au3` | `<audio>`/`Audio()` playback in `Notification.tsx` |
| `doTalk.au3` | `window.speechSynthesis` in `Notification.tsx` |
| `doRun.au3`, `executeCommand.au3`, `forwardRequest.au3` | `run_command` Tauri command (`tauri-plugin-shell`) |
| `NamedPipes.au3`, `_pipe.au3`, `wmCopyData.au3`, `fpquisend`, `fpquitip` | `tauri-plugin-single-instance` + `--notify <json>` (`cli.rs`) |
| `setConfiguration.au3`, `initializeDefaults.au3`, `initializeColors.au3`, `setBehaviour.au3` | `AppConfig` in `config.rs` + `pages/Settings.tsx` |
| `_setAutoStart.au3` | `tauri-plugin-autostart` (`set_autostart`/`get_autostart` commands) |
| `codeGeneratorGUI.au3`/`.kxf` | `pages/CodeGenerator.tsx` |
| `configurationAssistantGUI.au3`, `firstStartGUI.au3` | `pages/Settings.tsx` (first-start wizard not yet ported) |
| `argumentsPrompt.au3`, `_commandLineInterpreter.au3` | `legacy.rs` (`--notify-legacy <tags>`, see "Legacy tag-based syntax") |
| `_log.au3`, `initializeErrorHandling.au3` | TODO — use `tracing` / `log` crate |
