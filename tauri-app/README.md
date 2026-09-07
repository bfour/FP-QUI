# FP-QUI (Tauri rewrite)

A cross-platform, TypeScript/Rust rewrite of [FP-QUI](../readme.md), the
Windows-only AutoIt notification tool. The goal is to keep the same core
idea — a background tray app that shows highly customizable popup
notifications, controllable from the command line so it can be wired up to
other programs (Thunderbird, scripts, cron jobs, etc.) — while making it run
on Windows, macOS and Linux and be maintainable in TypeScript/Rust instead of
AutoIt + Delphi.

## Status

The core notification pipeline, the settings/code-generator UI and the
packaging story are in place:

- ✅ System tray icon with a menu (Settings, Generate Code, Send Test
  Notification, Check for Updates, Quit)
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
- ✅ First-start assistant, shown once per configuration and re-runnable from
  Settings
- ✅ Bundled sound and icon presets, referenced as `preset:<id>`
- ✅ Logging to a rotating file in the OS log directory (`tauri-plugin-log`)
- ✅ Packaging & auto-update: signed installers built by the release workflow,
  updates checked and installed from within the app (Windows and Linux;
  macOS bundles are still switched off, see "Packaging and updates")

## Architecture

```
tauri-app/
  src/                     # React + TypeScript frontend
    types.ts               # NotificationSpec / AppConfig (mirrors Rust types)
    lib/api.ts              # typed wrappers around `invoke()`
    lib/presets.ts           # bundled sound/icon presets, `preset:<id>` resolution
    App.tsx                   # picks a page based on the current window's label
    pages/
      Notification.tsx        # rendered in every "notif-<id>" window
      Settings.tsx             # rendered in the "main" window
      CodeGenerator.tsx         # rendered in the "main" window
      FirstStart.tsx             # first-start assistant, rendered in the "main" window
  public/presets/          # the bundled sounds and icons themselves
  tools/                   # generator for the bundled sounds
  src-tauri/               # Rust backend
    src/
      lib.rs                # app setup, tray menu, commands, single-instance, logging
      notification.rs        # NotificationSpec, window creation & stacking/positioning
      config.rs               # AppConfig + first-run flag, persisted via tauri-plugin-store
      cli.rs                   # parses `--notify <json>` / `--notify-legacy <tags>` from argv
      legacy.rs                # legacy `<text>...</text>` tag DSL -> NotificationSpec
```

### Windows

- `main` — hidden on startup, used for the Settings, Generate Code and
  first-start pages. Closing it hides it instead of quitting (the app keeps
  running in the tray). On a configuration that has never been set up it is
  shown on launch with the first-start assistant.
- `notif-<uuid>` — one per visible notification. Frameless, transparent,
  always-on-top, positioned by `notification.rs` according to the configured
  screen, corner and stacking order. Positioning uses each monitor's work
  area (`Monitor::work_area()`), so notifications don't overlap the taskbar,
  and accounts for the monitor's scale factor since window
  position/size are in logical pixels while monitor geometry is physical.
  These windows are created on a dedicated background thread per
  notification, never on the main/event-loop thread directly — on Windows,
  building a `WebviewWindow` synchronously from a Tauri command or the
  single-instance message handler deadlocks the whole app, since WebView2
  initialization needs that thread's message loop to be free
  (see [wry#583](https://github.com/tauri-apps/wry/issues/583)).

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

Fields: `title`, `text` (required), `textColor`, `bkColor`, `icon`
(`preset:<id>`, path or URL), `sound` (`preset:<id>`, path or URL), `talk`
(text to speak via TTS), `delayMs`
(0/omitted = use the configured default, omit + `untilClick: true` = stays
open until dismissed), `untilClick`, `buttons[]` (`label` + `cmd` and/or
`url`), `corner` (per-notification override of the configured screen corner).

### First start

The first time FP-QUI runs against a fresh configuration it opens the main
window on a short assistant (`pages/FirstStart.tsx`) instead of going straight
to the tray: autostart, screen/corner/duration, sound and speech, and an
example command to copy. Finishing or skipping it sets a `firstRunCompleted`
flag in the same store the configuration lives in, so it is shown once;
Settings → Troubleshooting can bring it back. This replaces
`firstStartGUI.au3`/`firstStartHandling.au3`, which shipped as a separate
`FP-QUIFirstStartAssistant.exe`.

Launching with `--notify` never opens the assistant — a notification request
is not the moment to ask someone about autostart.

### Presets

`icon` and `sound` accept a `preset:<id>` reference to one of the assets
bundled with the app, next to the paths and URLs they already took:

| Sounds | Icons |
| --- | --- |
| `preset:chime`, `preset:ping`, `preset:alert`, `preset:success`, `preset:error` | `preset:info`, `preset:success`, `preset:warning`, `preset:error`, `preset:message`, `preset:bell` |

```sh
fp-qui --notify '{"text":"Build finished","icon":"preset:success","sound":"preset:chime"}'
```

References stay unresolved until a notification is rendered
(`src/lib/presets.ts`), so a command generated on one machine works on another.
The same code resolves the other two forms: URLs are passed through, and a
plain file path is converted to Tauri's asset protocol — a bare path is not
loadable from a webview otherwise, which is why `app.security.assetProtocol`
is enabled in `tauri.conf.json`. Its scope is deliberately unrestricted: a
notification may name any icon or sound on the machine, and the only pages
loaded into these webviews are FP-QUI's own.

The sounds live in `public/presets/sounds` and are generated by
`tools/generate-sound-presets.py` (short synthesized tones, so nothing has to
be shipped under someone else's license); the icons are hand-written SVGs in
`public/presets/icons`. To add a preset, drop the file in and add an entry to
`SOUND_PRESETS`/`ICON_PRESETS` in `src/lib/presets.ts`.

Settings has a "default sound", played for notifications that don't bring
their own (`preset:chime` out of the box, or "(silent)" for the old behaviour
of staying quiet unless asked).

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
the Rust backend. `python3 tools/generate-sound-presets.py` regenerates the
bundled sounds.

## Packaging and updates

`.github/workflows/tauri-build.yml` builds the app on every push to
`publish/production-tauri` and uploads the bundles as workflow artifacts —
that is the "does it still build" job.

Releases go through `.github/workflows/tauri-release.yml`, which runs on a
`tauri-v*` tag (or on demand), builds the installers, signs the updater
artifacts and attaches everything — including the `latest.json` the in-app
updater reads — to a **draft** GitHub release. Nothing reaches users until
that release is published.

Signing keys are generated once with `pnpm tauri signer generate` and stored
as repository secrets:

| Secret | Contents |
| --- | --- |
| `TAURI_SIGNING_PRIVATE_KEY` | the generated private key |
| `TAURI_SIGNING_PRIVATE_KEY_PASSWORD` | its password (`""` if none) |
| `TAURI_SIGNING_PUBLIC_KEY` | the matching public key |

The public key is written into a build-time config overlay
(`src-tauri/tauri.release.conf.json`, generated by the workflow and
gitignored) together with `bundle.createUpdaterArtifacts`, so the app only
accepts updates signed with the private key while development builds need no
keys at all — `plugins.updater.pubkey` in the committed `tauri.conf.json` is
deliberately empty. A locally built app can therefore find an update but not
install it; that is expected.

Releasing a version:

1. bump `version` in `src-tauri/tauri.conf.json` (and `package.json`),
2. push a `tauri-v<version>` tag,
3. review the draft release the workflow created and publish it.

The app checks for updates on request — "Check for Updates" in the tray menu,
or the Updates section in Settings — against
`https://github.com/bfour/FP-QUI/releases/latest/download/latest.json`, and
offers to download, install and restart. There is no automatic background
check.

macOS is not part of either workflow yet: notification windows are
transparent, which on macOS needs tauri's `macos-private-api` feature (plus
`app.macOSPrivateApi`), and turning that on rules out Mac App Store
distribution. Enabling it — or dropping `transparent()` on macOS behind a
`#[cfg]` — is what re-enables the macOS jobs.

## Logging

`tauri-plugin-log` writes to stdout (useful with `npm run tauri dev`) and to a
rotating `fp-qui.log` in the OS log directory:

| Platform | Location |
| --- | --- |
| Windows | `%LOCALAPPDATA%\dev.bfour.fpqui\logs` |
| macOS | `~/Library/Logs/dev.bfour.fpqui` |
| Linux | `~/.local/share/dev.bfour.fpqui/logs` |

Settings → Troubleshooting → "Open log folder" opens it. Failures that used to
disappear into `let _ = ...` (window creation, command execution, storing the
configuration) are logged there.

## Migration mapping (old AutoIt modules -> new equivalent)

| Old module | New equivalent |
| --- | --- |
| `trayMainMenu.au3`, `trayMenu.kxf` | Tray menu in `lib.rs` (`setup()`) |
| `splashNotification.au3` | `notification::show()` + `pages/Notification.tsx` |
| `positioning.au3` | `notification::compute_position()` / `reposition_all()` |
| `initializeNotificationsArrays.au3` | `NotificationState` in `notification.rs` |
| `doAudio.au3`, `doBeep.au3` | `<audio>`/`Audio()` playback in `Notification.tsx`, bundled presets in `lib/presets.ts` |
| `doTalk.au3` | `window.speechSynthesis` in `Notification.tsx` |
| `doRun.au3`, `executeCommand.au3`, `forwardRequest.au3` | `run_command` Tauri command (`tauri-plugin-shell`) |
| `NamedPipes.au3`, `_pipe.au3`, `wmCopyData.au3`, `fpquisend`, `fpquitip` | `tauri-plugin-single-instance` + `--notify <json>` (`cli.rs`) |
| `setConfiguration.au3`, `initializeDefaults.au3`, `initializeColors.au3`, `setBehaviour.au3` | `AppConfig` in `config.rs` + `pages/Settings.tsx` |
| `_setAutoStart.au3` | `tauri-plugin-autostart` (`set_autostart`/`get_autostart` commands) |
| `codeGeneratorGUI.au3`/`.kxf` | `pages/CodeGenerator.tsx` |
| `configurationAssistantGUI.au3` | `pages/Settings.tsx` |
| `firstStartGUI.au3`, `firstStartHandling.au3`, `FP-QUIFirstStartAssistant` | `pages/FirstStart.tsx` (see "First start") |
| `argumentsPrompt.au3`, `_commandLineInterpreter.au3` | `legacy.rs` (`--notify-legacy <tags>`, see "Legacy tag-based syntax") |
| `_log.au3`, `initializeErrorHandling.au3` | `log` macros + `tauri-plugin-log` (see "Logging") |
| `FP-QUIRegistrar.au3` (registry entry so other apps can find and start FP-QUI) | not needed — the installer puts the executable in a fixed location and callers run it directly |
| `deploy.au3`, `deployBinary.au3`, `deploySource.au3`, `install-daqgroup-notifier.nsi` | Tauri bundler + `.github/workflows/tauri-release.yml` (see "Packaging and updates") |
| (no equivalent — updates were manual) | `tauri-plugin-updater` + `tauri-plugin-process`, driven from the tray menu and Settings |
