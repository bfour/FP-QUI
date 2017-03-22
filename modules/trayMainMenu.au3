#include-once

#include "splashNotification.au3"
#include "vars.au3"
#include <_run.au3>
#include <wmCopyData.au3>

Func _trayMainMenu()

   Opt("TrayAutoPause", 0)
   Opt("TrayMenuMode", 1+2)
   Opt("TrayOnEventMode", 1)

   TraySetClick(8) ; Tooltip on left mouse and main menu on right mouse
   TraySetOnEvent($TRAY_EVENT_PRIMARYDOWN, "_trayPrimary")

   Local $helpEntry = TrayCreateItem("Help")
   Local $configureEntry = TrayCreateItem("Configure")
   Local $generateCodeEntry = TrayCreateItem("Generate Code")
   TrayCreateItem("") ; separator line
   Local $terminateEntry = TrayCreateItem("Terminate")
   Local $restartEntry = TrayCreateItem("Restart")

   TrayItemSetOnEvent($terminateEntry, "_trayMainMenuTerminate")
   TrayItemSetOnEvent($restartEntry, "_trayMainMenuRestart")
   TrayItemSetOnEvent($helpEntry, "_trayMainMenuHelp")
   TrayItemSetOnEvent($configureEntry, "_trayMainMenuConfigure")
   TrayItemSetOnEvent($generateCodeEntry, "_trayMainMenuGenerateCode")

EndFunc

Func _trayPrimary()
   _splashNotification(0)
EndFunc

Func _trayMainMenuTerminate()
   _debug("_trayMainMenuTerminate")
   Exit
EndFunc

Func _trayMainMenuRestart()
   _debug("_trayMainMenuRestart")
   _run(@ScriptDir&'\tools\FP-BatchProcessor.exe "<runWait><cmd>taskkill /PID @AutoItPID /F</cmd></runWait><run><cmd>'&@ScriptDir&'\FP-QUICore.exe</cmd></run>"')
EndFunc

Func _trayMainMenuHelp()
   _debug("_trayMainMenuHelp")
   ShellExecute($FPQUI_HELPPATH, "", "", "open")
EndFunc

Func _trayMainMenuConfigure()
   _debug("_trayMainMenuConfigure")
   _run(@ScriptDir&"\FP-QUIConfigurationAssistant.exe")
EndFunc

Func _trayMainMenuGenerateCode()
   _debug("_trayMainMenuGenerateCode")
   _run(@ScriptDir&"\FP-QUICodeGeneratorGUI.exe")
EndFunc