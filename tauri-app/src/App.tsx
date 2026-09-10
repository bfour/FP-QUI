import { useEffect, useState } from "react";
import { getCurrentWindow } from "@tauri-apps/api/window";
import { listen } from "@tauri-apps/api/event";
import Notification from "./pages/Notification";
import Settings from "./pages/Settings";
import CodeGenerator from "./pages/CodeGenerator";
import FirstStart from "./pages/FirstStart";
import { isFirstRun } from "./lib/api";
import "./App.css";

type Tab = "settings" | "codegen";

function MainWindow() {
  const [tab, setTab] = useState<Tab>("settings");
  // null while the backend is still being asked whether this is a first start.
  const [firstRun, setFirstRun] = useState<boolean | null>(null);
  // Bumped by "Check for Updates" in the tray menu. A counter rather than an
  // event, so the request survives Settings not being mounted yet.
  const [updateRequest, setUpdateRequest] = useState(0);

  useEffect(() => {
    isFirstRun().then(setFirstRun, () => setFirstRun(false));
  }, []);

  useEffect(() => {
    const unlisten = listen<string>("navigate", (event) => {
      if (event.payload === "settings" || event.payload === "codegen") {
        setTab(event.payload);
      } else if (event.payload === "updates") {
        setTab("settings");
        setUpdateRequest((request) => request + 1);
      }
    });
    return () => {
      unlisten.then((f) => f());
    };
  }, []);

  if (firstRun === null) return null;

  // The assistant owns the whole window until it is finished or skipped, so
  // the tabs can't be used to wander off mid-setup.
  if (firstRun) {
    return (
      <div className="app">
        <FirstStart onDone={() => setFirstRun(false)} />
      </div>
    );
  }

  return (
    <div className="app">
      <nav className="app__nav">
        <button className={tab === "settings" ? "active" : ""} onClick={() => setTab("settings")}>
          Settings
        </button>
        <button className={tab === "codegen" ? "active" : ""} onClick={() => setTab("codegen")}>
          Generate Code
        </button>
      </nav>
      <div className="app__content">
        {tab === "settings" ? (
          <Settings
            updateRequest={updateRequest}
            onRestartAssistant={() => setFirstRun(true)}
          />
        ) : (
          <CodeGenerator />
        )}
      </div>
    </div>
  );
}

export default function App() {
  const label = getCurrentWindow().label;

  if (label.startsWith("notif-")) {
    return <Notification />;
  }

  return <MainWindow />;
}
