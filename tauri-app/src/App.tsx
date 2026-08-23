import { useEffect, useState } from "react";
import { getCurrentWindow } from "@tauri-apps/api/window";
import { listen } from "@tauri-apps/api/event";
import Notification from "./pages/Notification";
import Settings from "./pages/Settings";
import CodeGenerator from "./pages/CodeGenerator";
import "./App.css";

type Tab = "settings" | "codegen";

function MainWindow() {
  const [tab, setTab] = useState<Tab>("settings");

  useEffect(() => {
    const unlisten = listen<string>("navigate", (event) => {
      if (event.payload === "settings" || event.payload === "codegen") {
        setTab(event.payload);
      }
    });
    return () => {
      unlisten.then((f) => f());
    };
  }, []);

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
        {tab === "settings" ? <Settings /> : <CodeGenerator />}
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
