import { useMemo, useState } from "react";
import type { ReactNode } from "react";
import { showNotification } from "../lib/api";
import { ICON_PRESETS, PRESET_PREFIX, SOUND_PRESETS, presetRef, resolveSound } from "../lib/presets";
import type { Preset } from "../lib/presets";
import type { NotificationButton, NotificationSpec } from "../types";
import "./CodeGenerator.css";

interface PresetFieldProps {
  label: string;
  presets: Preset[];
  value: string;
  placeholder: string;
  onChange: (value: string) => void;
  /** Rendered next to the field, e.g. a button to play the chosen sound. */
  extra?: ReactNode;
}

/**
 * Picks one of the bundled presets, or takes a path/URL of the user's own.
 * Presets are stored as `preset:<id>` so the generated command stays portable
 * — the receiving instance resolves them against its own bundled assets.
 */
function PresetField({ label, presets, value, placeholder, onChange, extra }: PresetFieldProps) {
  const isPresetValue = value.startsWith(PRESET_PREFIX);
  const [custom, setCustom] = useState(value !== "" && !isPresetValue);

  const selection = custom ? "custom" : isPresetValue ? value : "";

  return (
    <label className="codegen__row">
      <span>{label}</span>
      <select
        value={selection}
        onChange={(event) => {
          const next = event.target.value;
          setCustom(next === "custom");
          onChange(next === "custom" || next === "" ? "" : next);
        }}
      >
        <option value="">(none)</option>
        {presets.map((preset) => (
          <option key={preset.id} value={presetRef(preset.id)}>
            {preset.label}
          </option>
        ))}
        <option value="custom">Custom path or URL…</option>
      </select>
      {custom && (
        <input
          placeholder={placeholder}
          value={isPresetValue ? "" : value}
          onChange={(event) => onChange(event.target.value)}
        />
      )}
      {extra}
    </label>
  );
}

const EMPTY_SPEC: Omit<NotificationSpec, "id"> = {
  title: "",
  text: "Hello.",
  textColor: "",
  bkColor: "",
  icon: "",
  sound: "",
  talk: "",
  delayMs: undefined,
  untilClick: false,
  buttons: [],
};

/** Removes empty/undefined fields so the generated JSON stays minimal. */
function cleanSpec(spec: Omit<NotificationSpec, "id">): Record<string, unknown> {
  const result: Record<string, unknown> = { text: spec.text };
  if (spec.title) result.title = spec.title;
  if (spec.textColor) result.textColor = spec.textColor;
  if (spec.bkColor) result.bkColor = spec.bkColor;
  if (spec.icon) result.icon = spec.icon;
  if (spec.sound) result.sound = spec.sound;
  if (spec.talk) result.talk = spec.talk;
  if (spec.delayMs !== undefined) result.delayMs = spec.delayMs;
  if (spec.untilClick) result.untilClick = true;
  if (spec.buttons.length > 0) result.buttons = spec.buttons;
  return result;
}

export default function CodeGenerator() {
  const [spec, setSpec] = useState<Omit<NotificationSpec, "id">>(EMPTY_SPEC);
  const [copied, setCopied] = useState(false);

  const update = <K extends keyof typeof spec>(key: K, value: (typeof spec)[K]) =>
    setSpec({ ...spec, [key]: value });

  const updateButton = (index: number, button: NotificationButton) => {
    const buttons = [...spec.buttons];
    buttons[index] = button;
    update("buttons", buttons);
  };

  const addButton = () => update("buttons", [...spec.buttons, { label: "", cmd: "" }]);
  const removeButton = (index: number) =>
    update("buttons", spec.buttons.filter((_, i) => i !== index));

  const json = useMemo(() => JSON.stringify(cleanSpec(spec)), [spec]);
  const command = `fp-qui --notify '${json}'`;

  const copy = async () => {
    await navigator.clipboard.writeText(command);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const preview = () => showNotification({ ...spec, id: "" });

  return (
    <div className="codegen">
      <h2>Generate Code</h2>
      <p className="codegen__hint">
        Build a notification, then copy the generated command to invoke FP-QUI from
        another program (e.g. Thunderbird, a script, a cron job).
      </p>

      <label className="codegen__row">
        <span>Title</span>
        <input value={spec.title} onChange={(e) => update("title", e.target.value)} />
      </label>

      <label className="codegen__row">
        <span>Text</span>
        <textarea
          value={spec.text}
          onChange={(e) => update("text", e.target.value)}
          rows={3}
        />
      </label>

      <div className="codegen__grid">
        <label className="codegen__row">
          <span>Background color</span>
          <input
            placeholder="(default)"
            value={spec.bkColor}
            onChange={(e) => update("bkColor", e.target.value)}
          />
        </label>
        <label className="codegen__row">
          <span>Text color</span>
          <input
            placeholder="(default)"
            value={spec.textColor}
            onChange={(e) => update("textColor", e.target.value)}
          />
        </label>
        <PresetField
          label="Icon"
          presets={ICON_PRESETS}
          value={spec.icon ?? ""}
          placeholder="C:\\icons\\build.png or https://…"
          onChange={(value) => update("icon", value)}
        />
        <PresetField
          label="Sound"
          presets={SOUND_PRESETS}
          value={spec.sound ?? ""}
          placeholder="C:\\sounds\\alert.wav or https://…"
          onChange={(value) => update("sound", value)}
          extra={
            <button
              type="button"
              disabled={!spec.sound}
              onClick={() => {
                const url = resolveSound(spec.sound);
                if (url) void new Audio(url).play().catch(() => undefined);
              }}
            >
              Play
            </button>
          }
        />
        <label className="codegen__row">
          <span>Speak text (TTS)</span>
          <input value={spec.talk} onChange={(e) => update("talk", e.target.value)} />
        </label>
        <label className="codegen__row">
          <span>Duration (ms)</span>
          <input
            type="number"
            min={0}
            placeholder="(default)"
            value={spec.delayMs ?? ""}
            onChange={(e) =>
              update("delayMs", e.target.value === "" ? undefined : Number(e.target.value))
            }
          />
        </label>
        <label className="codegen__row">
          <span>Stay open until clicked</span>
          <input
            type="checkbox"
            checked={spec.untilClick}
            onChange={(e) => update("untilClick", e.target.checked)}
          />
        </label>
      </div>

      <h3>Buttons</h3>
      {spec.buttons.map((button, index) => (
        <div className="codegen__button-row" key={index}>
          <input
            placeholder="Label"
            value={button.label}
            onChange={(e) => updateButton(index, { ...button, label: e.target.value })}
          />
          <input
            placeholder="Command to run"
            value={button.cmd ?? ""}
            onChange={(e) => updateButton(index, { ...button, cmd: e.target.value })}
          />
          <input
            placeholder="…or URL to open"
            value={button.url ?? ""}
            onChange={(e) => updateButton(index, { ...button, url: e.target.value })}
          />
          <button onClick={() => removeButton(index)}>Remove</button>
        </div>
      ))}
      <button onClick={addButton}>Add button</button>

      <h3>Generated command</h3>
      <pre className="codegen__output">{command}</pre>

      <div className="codegen__actions">
        <button onClick={preview}>Preview</button>
        <button onClick={copy}>{copied ? "Copied!" : "Copy command"}</button>
      </div>
    </div>
  );
}
