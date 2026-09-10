import { invoke } from "@tauri-apps/api/core";
import type { AppConfig, MonitorInfo, NotificationSpec, SystemTheme } from "../types";

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

export function getSystemTheme() {
  return invoke<SystemTheme>("get_system_theme");
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

export function listMonitors() {
  return invoke<MonitorInfo[]>("list_monitors");
}

export function isFirstRun() {
  return invoke<boolean>("is_first_run");
}

export function setFirstRunCompleted(completed: boolean) {
  return invoke<void>("set_first_run_completed", { completed });
}

export function openLogDir() {
  return invoke<void>("open_log_dir");
}
