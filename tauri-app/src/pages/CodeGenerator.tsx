import { useMemo, useState } from "react";
import { showNotification } from "../lib/api";
import type { NotificationButton, NotificationSpec } from "../types";
import "./CodeGenerator.css";

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
        <label className="codegen__row">
          <span>Icon (path or URL)</span>
          <input value={spec.icon} onChange={(e) => update("icon", e.target.value)} />
        </label>
        <label className="codegen__row">
          <span>Sound (path or URL)</span>
          <input value={spec.sound} onChange={(e) => update("sound", e.target.value)} />
        </label>
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
