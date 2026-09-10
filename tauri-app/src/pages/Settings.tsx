import { useCallback, useEffect, useState } from "react";
import { getVersion } from "@tauri-apps/api/app";
import { check, type Update } from "@tauri-apps/plugin-updater";
import { relaunch } from "@tauri-apps/plugin-process";
import {
  getAutostart,
  getConfig,
  listMonitors,
  openLogDir,
  setAutostart,
  setConfig,
  setFirstRunCompleted,
  showNotification,
} from "../lib/api";
import { SOUND_PRESETS, presetRef, resolveSound } from "../lib/presets";
import type { AppConfig, Corner, MonitorInfo } from "../types";
import { CORNER_LABELS } from "../types";
import "./Settings.css";

const CORNERS: Corner[] = ["top-left", "top-right", "bottom-left", "bottom-right"];

type UpdateStatus =
  | { kind: "idle" }
  | { kind: "checking" }
  | { kind: "upToDate" }
  | { kind: "available"; update: Update }
  | { kind: "installing"; version: string }
  | { kind: "installed"; version: string }
  | { kind: "error"; message: string };

interface Props {
  /** Incremented when "Check for Updates" was picked from the tray menu. */
  updateRequest: number;
  /** Re-opens the first-start assistant in the main window. */
  onRestartAssistant: () => void;
}

export default function Settings({ updateRequest, onRestartAssistant }: Props) {
  const [config, setLocalConfig] = useState<AppConfig | null>(null);
  const [autostart, setLocalAutostart] = useState(false);
  const [monitors, setMonitors] = useState<MonitorInfo[]>([]);
  const [status, setStatus] = useState<string | null>(null);
  const [version, setVersion] = useState<string>("");
  const [updateState, setUpdateState] = useState<UpdateStatus>({ kind: "idle" });

  useEffect(() => {
    getConfig().then(setLocalConfig);
    getAutostart().then(setLocalAutostart).catch(() => setLocalAutostart(false));
    listMonitors().then(setMonitors).catch(() => setMonitors([]));
    getVersion().then(setVersion).catch(() => setVersion(""));
  }, []);

  const checkForUpdates = useCallback(async () => {
    setUpdateState({ kind: "checking" });
    try {
      const found = await check();
      setUpdateState(found ? { kind: "available", update: found } : { kind: "upToDate" });
    } catch (error) {
      setUpdateState({ kind: "error", message: String(error) });
    }
  }, []);

  // "Check for Updates" in the tray menu opens this page and asks for a check.
  useEffect(() => {
    if (updateRequest > 0) void checkForUpdates();
  }, [updateRequest, checkForUpdates]);

  if (!config) return <p className="settings__loading">Loading…</p>;

  const update = <K extends keyof AppConfig>(key: K, value: AppConfig[K]) =>
    setLocalConfig({ ...config, [key]: value });

  const save = async () => {
    await setConfig(config);
    await setAutostart(autostart);
    setStatus("Saved.");
    setTimeout(() => setStatus(null), 2000);
  };

  const sendTest = () =>
    showNotification({
      title: "FP-QUI",
      text: "This is a test notification.",
    });

  const playDefaultSound = () => {
    const url = resolveSound(config.defaultSound);
    if (url) void new Audio(url).play().catch(() => setStatus("Could not play that sound."));
  };

  const runAssistantAgain = async () => {
    await setFirstRunCompleted(false);
    onRestartAssistant();
  };

  const installUpdate = async (found: Update) => {
    setUpdateState({ kind: "installing", version: found.version });
    try {
      await found.downloadAndInstall();
      setUpdateState({ kind: "installed", version: found.version });
    } catch (error) {
      setUpdateState({ kind: "error", message: String(error) });
    }
  };

  return (
    <div className="settings">
      <h2>Behaviour</h2>

      <label className="settings__row">
        <span>Screen</span>
        <select
          value={config.screen ?? ""}
          onChange={(e) => update("screen", e.target.value === "" ? null : Number(e.target.value))}
        >
          <option value="">Primary</option>
          {monitors.map((monitor, index) => (
            <option key={index} value={index}>
              {monitor.name} ({monitor.width}×{monitor.height}
              {monitor.primary ? ", primary" : ""})
            </option>
          ))}
        </select>
      </label>

      <label className="settings__row">
        <span>Screen corner</span>
        <select
          value={config.corner}
          onChange={(e) => update("corner", e.target.value as Corner)}
        >
          {CORNERS.map((corner) => (
            <option key={corner} value={corner}>
              {CORNER_LABELS[corner]}
            </option>
          ))}
        </select>
      </label>

      <label className="settings__row">
        <span>Default duration (ms, 0 = until clicked)</span>
        <input
          type="number"
          min={0}
          step={500}
          value={config.defaultDurationMs}
          onChange={(e) => update("defaultDurationMs", Number(e.target.value))}
        />
      </label>

      <label className="settings__row">
        <span>Match the Windows light/dark theme</span>
        <input
          type="checkbox"
          checked={config.useSystemTheme}
          onChange={(e) => update("useSystemTheme", e.target.checked)}
        />
      </label>

      <label className="settings__row">
        <span>Background color</span>
        <input
          type="color"
          disabled={config.useSystemTheme}
          value={config.defaultBgColor}
          onChange={(e) => update("defaultBgColor", e.target.value)}
        />
      </label>

      <label className="settings__row">
        <span>Text color</span>
        <input
          type="color"
          disabled={config.useSystemTheme}
          value={config.defaultTextColor}
          onChange={(e) => update("defaultTextColor", e.target.value)}
        />
      </label>

      <label className="settings__row">
        <span>Play notification sounds</span>
        <input
          type="checkbox"
          checked={config.soundEnabled}
          onChange={(e) => update("soundEnabled", e.target.checked)}
        />
      </label>

      <div className="settings__row">
        <span>Default sound</span>
        <select
          disabled={!config.soundEnabled}
          value={config.defaultSound}
          onChange={(e) => update("defaultSound", e.target.value)}
        >
          <option value="">(silent)</option>
          {SOUND_PRESETS.map((sound) => (
            <option key={sound.id} value={presetRef(sound.id)}>
              {sound.label}
            </option>
          ))}
          {config.defaultSound && !config.defaultSound.startsWith("preset:") && (
            <option value={config.defaultSound}>{config.defaultSound}</option>
          )}
        </select>
        <button
          className="settings__inline-button"
          disabled={!config.soundEnabled || !config.defaultSound}
          onClick={playDefaultSound}
        >
          Play
        </button>
      </div>

      <label className="settings__row">
        <span>Read notifications aloud (text-to-speech)</span>
        <input
          type="checkbox"
          checked={config.ttsEnabled}
          onChange={(e) => update("ttsEnabled", e.target.checked)}
        />
      </label>

      <label className="settings__row">
        <span>Start FP-QUI when you log in</span>
        <input
          type="checkbox"
          checked={autostart}
          onChange={(e) => setLocalAutostart(e.target.checked)}
        />
      </label>

      <h2>Layout</h2>

      <div className="settings__grid">
        <label className="settings__row">
          <span>Width (px)</span>
          <input
            type="number"
            min={100}
            value={config.notificationWidth}
            onChange={(e) => update("notificationWidth", Number(e.target.value))}
          />
        </label>
        <label className="settings__row">
          <span>Height (px)</span>
          <input
            type="number"
            min={50}
            value={config.notificationHeight}
            onChange={(e) => update("notificationHeight", Number(e.target.value))}
          />
        </label>
        <label className="settings__row">
          <span>Margin X (px)</span>
          <input
            type="number"
            min={0}
            value={config.marginX}
            onChange={(e) => update("marginX", Number(e.target.value))}
          />
        </label>
        <label className="settings__row">
          <span>Margin Y (px)</span>
          <input
            type="number"
            min={0}
            value={config.marginY}
            onChange={(e) => update("marginY", Number(e.target.value))}
          />
        </label>
        <label className="settings__row">
          <span>Gap between notifications (px)</span>
          <input
            type="number"
            min={0}
            value={config.gap}
            onChange={(e) => update("gap", Number(e.target.value))}
          />
        </label>
      </div>

      <div className="settings__actions">
        <button onClick={sendTest}>Send test notification</button>
        <button onClick={save}>Save</button>
        {status && <span className="settings__status">{status}</span>}
      </div>

      <h2>Updates</h2>

      <div className="settings__row">
        <span>Installed version{version ? `: ${version}` : ""}</span>
        <button onClick={() => void checkForUpdates()} disabled={updateState.kind === "checking"}>
          {updateState.kind === "checking" ? "Checking…" : "Check for updates"}
        </button>
      </div>

      {updateState.kind === "upToDate" && (
        <p className="settings__note">FP-QUI is up to date.</p>
      )}
      {updateState.kind === "available" && (
        <div className="settings__update">
          <p className="settings__note">
            Version {updateState.update.version} is available.
            {updateState.update.body ? ` ${updateState.update.body}` : ""}
          </p>
          <button onClick={() => void installUpdate(updateState.update)}>Download and install</button>
        </div>
      )}
      {updateState.kind === "installing" && (
        <p className="settings__note">Downloading and installing {updateState.version}…</p>
      )}
      {updateState.kind === "installed" && (
        <div className="settings__update">
          <p className="settings__note">Version {updateState.version} installed.</p>
          <button onClick={() => void relaunch()}>Restart FP-QUI</button>
        </div>
      )}
      {updateState.kind === "error" && (
        <p className="settings__error">Update failed: {updateState.message}</p>
      )}

      <h2>Troubleshooting</h2>

      <div className="settings__actions">
        <button onClick={() => void openLogDir()}>Open log folder</button>
        <button onClick={() => void runAssistantAgain()}>Run the first-start assistant</button>
      </div>
    </div>
  );
}
