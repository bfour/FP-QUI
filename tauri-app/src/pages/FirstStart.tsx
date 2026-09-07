import { useEffect, useMemo, useState } from "react";
import {
  getAutostart,
  getConfig,
  listMonitors,
  setAutostart,
  setConfig,
  setFirstRunCompleted,
  showNotification,
} from "../lib/api";
import { SOUND_PRESETS, presetRef, resolveSound } from "../lib/presets";
import type { AppConfig, Corner, MonitorInfo } from "../types";
import { CORNER_LABELS } from "../types";
import "./FirstStart.css";

const CORNERS: Corner[] = ["top-left", "top-right", "bottom-left", "bottom-right"];

const EXAMPLE_COMMAND = `fp-qui --notify '{"title":"Build finished","text":"All tests passed."}'`;

interface Props {
  /** Called once the assistant has been completed or skipped. */
  onDone: () => void;
}

/**
 * The first-start assistant, shown once per configuration before the settings
 * window proper. Replaces firstStartGUI.au3 / firstStartHandling.au3: same
 * job (get the essentials set before the app disappears into the tray), but
 * covering the settings that actually matter in this version.
 */
export default function FirstStart({ onDone }: Props) {
  const [config, setLocalConfig] = useState<AppConfig | null>(null);
  const [autostart, setLocalAutostart] = useState(false);
  const [monitors, setMonitors] = useState<MonitorInfo[]>([]);
  const [step, setStep] = useState(0);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    getConfig().then(setLocalConfig);
    getAutostart().then(setLocalAutostart).catch(() => setLocalAutostart(false));
    listMonitors().then(setMonitors).catch(() => setMonitors([]));
  }, []);

  const steps = useMemo(
    () => ["Welcome", "Startup", "Position", "Sound", "Done"],
    [],
  );

  if (!config) return <p className="wizard__loading">Loading…</p>;

  const update = <K extends keyof AppConfig>(key: K, value: AppConfig[K]) =>
    setLocalConfig({ ...config, [key]: value });

  const finish = async (completed: boolean) => {
    setSaving(true);
    setError(null);
    try {
      if (completed) {
        await setConfig(config);
        await setAutostart(autostart);
      }
      await setFirstRunCompleted(true);
      onDone();
    } catch (cause) {
      setError(String(cause));
    } finally {
      setSaving(false);
    }
  };

  // Applying the position settings before previewing is what makes the
  // preview show the corner and screen picked on this step.
  const preview = async () => {
    setError(null);
    try {
      await setConfig(config);
      await showNotification({
        title: "FP-QUI",
        text: "This is what your notifications will look like.",
        icon: presetRef("info"),
      });
    } catch (cause) {
      setError(String(cause));
    }
  };

  const playSound = () => {
    const url = resolveSound(config.defaultSound);
    if (url) void new Audio(url).play().catch(() => setError("Could not play that sound."));
  };

  const copyExample = async () => {
    await navigator.clipboard.writeText(EXAMPLE_COMMAND);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="wizard">
      <ol className="wizard__steps">
        {steps.map((label, index) => (
          <li key={label} className={index === step ? "active" : index < step ? "done" : ""}>
            {label}
          </li>
        ))}
      </ol>

      <div className="wizard__body">
        {step === 0 && (
          <section>
            <h2>Welcome to FP-QUI</h2>
            <p>
              FP-QUI sits in the system tray and shows popup notifications on request —
              from your own scripts, a mail client, a build job, anything that can run a
              command. This assistant walks through the handful of settings worth deciding
              up front; everything here can be changed later under Settings.
            </p>
          </section>
        )}

        {step === 1 && (
          <section>
            <h2>Start with your session</h2>
            <p>
              FP-QUI has to be running to show a notification instantly. It can be started
              on demand by whatever wants to notify you, but starting it when you log in
              avoids that delay. It costs a little memory while it waits in the tray.
            </p>
            <label className="wizard__row">
              <input
                type="checkbox"
                checked={autostart}
                onChange={(event) => setLocalAutostart(event.target.checked)}
              />
              <span>Start FP-QUI when I log in</span>
            </label>
          </section>
        )}

        {step === 2 && (
          <section>
            <h2>Where notifications appear</h2>
            <p>
              Notifications stack in one corner of one screen, inside the work area, so
              they stay clear of the taskbar.
            </p>
            <label className="wizard__row">
              <span>Screen</span>
              <select
                value={config.screen ?? ""}
                onChange={(event) =>
                  update("screen", event.target.value === "" ? null : Number(event.target.value))
                }
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
            <label className="wizard__row">
              <span>Corner</span>
              <select
                value={config.corner}
                onChange={(event) => update("corner", event.target.value as Corner)}
              >
                {CORNERS.map((corner) => (
                  <option key={corner} value={corner}>
                    {CORNER_LABELS[corner]}
                  </option>
                ))}
              </select>
            </label>
            <label className="wizard__row">
              <span>Stay on screen for (ms, 0 = until clicked)</span>
              <input
                type="number"
                min={0}
                step={500}
                value={config.defaultDurationMs}
                onChange={(event) => update("defaultDurationMs", Number(event.target.value))}
              />
            </label>
            <p className="wizard__hint">
              Showing a preview applies these settings right away, so it appears exactly
              where notifications will.
            </p>
            <button onClick={() => void preview()}>Show a preview</button>
          </section>
        )}

        {step === 3 && (
          <section>
            <h2>Sound and speech</h2>
            <label className="wizard__row">
              <input
                type="checkbox"
                checked={config.soundEnabled}
                onChange={(event) => update("soundEnabled", event.target.checked)}
              />
              <span>Play a sound with notifications</span>
            </label>
            <label className="wizard__row">
              <span>Default sound</span>
              <select
                disabled={!config.soundEnabled}
                value={config.defaultSound}
                onChange={(event) => update("defaultSound", event.target.value)}
              >
                <option value="">(silent)</option>
                {SOUND_PRESETS.map((sound) => (
                  <option key={sound.id} value={presetRef(sound.id)}>
                    {sound.label}
                  </option>
                ))}
              </select>
            </label>
            <button disabled={!config.soundEnabled || !config.defaultSound} onClick={playSound}>
              Play
            </button>
            <label className="wizard__row">
              <input
                type="checkbox"
                checked={config.ttsEnabled}
                onChange={(event) => update("ttsEnabled", event.target.checked)}
              />
              <span>Read notification text aloud</span>
            </label>
            <p className="wizard__hint">
              Individual notifications can override both, with their own sound file or
              their own spoken text.
            </p>
          </section>
        )}

        {step === 4 && (
          <section>
            <h2>Sending a notification</h2>
            <p>
              Anything that can run a command can now show a notification. FP-QUI forwards
              the request to the instance already running, so the tray app stays a single
              process:
            </p>
            <pre className="wizard__code">{EXAMPLE_COMMAND}</pre>
            <button onClick={copyExample}>{copied ? "Copied!" : "Copy example"}</button>
            <p className="wizard__hint">
              The <strong>Generate Code</strong> tab builds these commands for you,
              including colors, icons, sounds and buttons. Existing integrations that send
              the old tag syntax can use <code>--notify-legacy</code> instead.
            </p>
          </section>
        )}
      </div>

      {error && <p className="wizard__error">{error}</p>}

      <div className="wizard__actions">
        <button className="wizard__skip" disabled={saving} onClick={() => void finish(false)}>
          Skip
        </button>
        <span className="wizard__spacer" />
        <button disabled={step === 0 || saving} onClick={() => setStep(step - 1)}>
          Back
        </button>
        {step < steps.length - 1 ? (
          <button className="wizard__primary" disabled={saving} onClick={() => setStep(step + 1)}>
            Next
          </button>
        ) : (
          <button className="wizard__primary" disabled={saving} onClick={() => void finish(true)}>
            Save and finish
          </button>
        )}
      </div>
    </div>
  );
}
