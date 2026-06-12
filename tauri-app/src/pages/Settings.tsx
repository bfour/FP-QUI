import { useEffect, useState } from "react";
import { getAutostart, getConfig, setAutostart, setConfig, showNotification } from "../lib/api";
import type { AppConfig, Corner } from "../types";
import { CORNER_LABELS } from "../types";
import "./Settings.css";

const CORNERS: Corner[] = ["top-left", "top-right", "bottom-left", "bottom-right"];

export default function Settings() {
  const [config, setLocalConfig] = useState<AppConfig | null>(null);
  const [autostart, setLocalAutostart] = useState(false);
  const [status, setStatus] = useState<string | null>(null);

  useEffect(() => {
    getConfig().then(setLocalConfig);
    getAutostart().then(setLocalAutostart).catch(() => setLocalAutostart(false));
  }, []);

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

  return (
    <div className="settings">
      <h2>Behaviour</h2>

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
        <span>Background color</span>
        <input
          type="color"
          value={config.defaultBgColor}
          onChange={(e) => update("defaultBgColor", e.target.value)}
        />
      </label>

      <label className="settings__row">
        <span>Text color</span>
        <input
          type="color"
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
    </div>
  );
}
