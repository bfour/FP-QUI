import { invoke } from "@tauri-apps/api/core";
import type { AppConfig, NotificationSpec } from "../types";

export function showNotification(spec: Partial<NotificationSpec> & { text: string }) {
  const fullSpec: NotificationSpec = {
    id: "",
    untilClick: false,
    buttons: [],
    ...spec,
  };
  return invoke<string>("show_notification", { spec: fullSpec });
}

export function dismissNotification(id: string) {
  return invoke<void>("dismiss_notification", { id });
}

export function getNotificationSpec(id: string) {
  return invoke<NotificationSpec | null>("get_notification_spec", { id });
}

export function getConfig() {
  return invoke<AppConfig>("get_config");
}

export function setConfig(config: AppConfig) {
  return invoke<void>("set_config", { config });
}

export function getAutostart() {
  return invoke<boolean>("get_autostart");
}

export function setAutostart(enabled: boolean) {
  return invoke<void>("set_autostart", { enabled });
}

export function runCommand(cmd: string) {
  return invoke<void>("run_command", { cmd });
}
