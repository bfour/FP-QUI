import { useEffect, useState } from "react";
import { getCurrentWindow } from "@tauri-apps/api/window";
import { openUrl } from "@tauri-apps/plugin-opener";
import { dismissNotification, getConfig, getNotificationSpec, runCommand } from "../lib/api";
import { useSystemTheme } from "../lib/systemTheme";
import { resolveIcon, resolveSound } from "../lib/presets";
import type { AppConfig, NotificationButton, NotificationSpec } from "../types";
import "./Notification.css";

function notificationId(): string | null {
  const label = getCurrentWindow().label;
  const prefix = "notif-";
  return label.startsWith(prefix) ? label.slice(prefix.length) : null;
}

export default function Notification() {
  const [spec, setSpec] = useState<NotificationSpec | null>(null);
  const [config, setConfig] = useState<AppConfig | null>(null);
  const systemTheme = useSystemTheme();
  const id = notificationId();

  useEffect(() => {
    if (!id) return;
    getNotificationSpec(id).then(setSpec);
    getConfig().then(setConfig);
  }, [id]);

  useEffect(() => {
    if (!spec || !config) return;

    // A notification's own sound wins; otherwise the configured default
    // (a bundled preset out of the box) is played.
    const sound = config.soundEnabled ? resolveSound(spec.sound ?? config.defaultSound) : undefined;
    if (sound) {
      new Audio(sound).play().catch(() => {
        /* ignore playback errors, e.g. missing/blocked audio device */
      });
    }

    const speechText = spec.talk ?? (config.ttsEnabled ? spec.text : undefined);
    if (speechText && "speechSynthesis" in window) {
      window.speechSynthesis.speak(new SpeechSynthesisUtterance(speechText));
    }
  }, [spec, config]);

  if (!spec || !config) return null;

  const close = () => {
    if (id) void dismissNotification(id);
  };

  const runButton = async (button: NotificationButton) => {
    if (button.cmd) await runCommand(button.cmd);
    if (button.url) await openUrl(button.url);
    close();
  };

  // Colours set on the notification itself always win. Otherwise we either
  // follow the system light/dark theme (handled in CSS) or fall back to the
  // configured default colours.
  const fallbackBg = config.useSystemTheme ? undefined : config.defaultBgColor;
  const fallbackFg = config.useSystemTheme ? undefined : config.defaultTextColor;
  const bg = spec.bkColor ?? fallbackBg;
  const fg = spec.textColor ?? fallbackFg;
  const icon = resolveIcon(spec.icon);

  return (
    <div
      className="notification"
      data-theme={systemTheme.dark ? "dark" : "light"}
      data-corners={systemTheme.rounded ? "rounded" : "square"}
      style={{
        borderRadius: `${systemTheme.cornerRadius}px`,
        ...(bg ? { backgroundColor: bg } : {}),
        ...(fg ? { color: fg } : {}),
      }}
      onClick={() => {
        if (spec.untilClick || spec.buttons.length === 0) close();
      }}
    >
      <button className="notification__close" onClick={(e) => { e.stopPropagation(); close(); }}>
        ×
      </button>

      <div className="notification__body">
        {icon && <img className="notification__icon" src={icon} alt="" />}
        <div className="notification__content">
          {spec.title && <div className="notification__title">{spec.title}</div>}
          <div className="notification__text">{spec.text}</div>
        </div>
      </div>

      {spec.buttons.length > 0 && (
        <div className="notification__buttons">
          {spec.buttons.map((button, index) => (
            <button
              key={index}
              className="notification__button"
              onClick={(e) => {
                e.stopPropagation();
                void runButton(button);
              }}
            >
              {button.label}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
