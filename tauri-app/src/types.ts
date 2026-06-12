export type Corner = "top-left" | "top-right" | "bottom-left" | "bottom-right";

export interface NotificationButton {
  label: string;
  cmd?: string;
  url?: string;
}

/** Mirrors NotificationSpec in src-tauri/src/notification.rs */
export interface NotificationSpec {
  id: string;
  title?: string;
  text: string;
  textColor?: string;
  bkColor?: string;
  icon?: string;
  sound?: string;
  talk?: string;
  delayMs?: number;
  untilClick: boolean;
  buttons: NotificationButton[];
  corner?: Corner;
}

/** Mirrors MonitorInfo in src-tauri/src/notification.rs */
export interface MonitorInfo {
  name: string;
  width: number;
  height: number;
  primary: boolean;
}

/** Mirrors AppConfig in src-tauri/src/config.rs */
export interface AppConfig {
  corner: Corner;
  /** Index into the array returned by `listMonitors`. `null`/`undefined` = primary monitor. */
  screen?: number | null;
  defaultDurationMs: number;
  defaultBgColor: string;
  defaultTextColor: string;
  soundEnabled: boolean;
  ttsEnabled: boolean;
  marginX: number;
  marginY: number;
  notificationWidth: number;
  notificationHeight: number;
  gap: number;
}

export const CORNER_LABELS: Record<Corner, string> = {
  "top-left": "Top left",
  "top-right": "Top right",
  "bottom-left": "Bottom left",
  "bottom-right": "Bottom right",
};
