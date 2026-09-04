import { useEffect, useState } from "react";
import { getCurrentWindow } from "@tauri-apps/api/window";
import { getSystemTheme } from "./api";
import type { SystemTheme } from "../types";

/**
 * Used while the backend answer is in flight, and if it fails altogether.
 * Assumes the rounded, Windows 11-style look and takes the dark/light state
 * from the webview, which follows the OS setting.
 */
function fallbackTheme(): SystemTheme {
  return {
    rounded: true,
    cornerRadius: 8,
    dark: window.matchMedia("(prefers-color-scheme: dark)").matches,
  };
}

/**
 * The host system's notification look, kept in sync while the window is open:
 * the user can flip Windows between light and dark with a notification on
 * screen, and it should follow.
 */
export function useSystemTheme(): SystemTheme {
  const [theme, setTheme] = useState<SystemTheme>(fallbackTheme);

  useEffect(() => {
    let active = true;
    let unlisten: (() => void) | undefined;

    getSystemTheme().then((current) => {
      if (active) setTheme(current);
    }, () => {
      /* keep the fallback */
    });

    getCurrentWindow()
      .onThemeChanged(({ payload }) => {
        if (active) setTheme((current) => ({ ...current, dark: payload === "dark" }));
      })
      .then((stop) => {
        if (active) unlisten = stop;
        else stop();
      }, () => {
        /* theme change events are a nicety; the initial value still applies */
      });

    return () => {
      active = false;
      unlisten?.();
    };
  }, []);

  return theme;
}
