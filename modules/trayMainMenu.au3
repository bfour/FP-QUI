#include-once

#include "mainMenu.au3"
#include <_run.au3>

Func _trayMainMenu()

   Opt("TrayAutoPause", 0)
   Opt("TrayMenuMode", 1+2)
   Opt("TrayOnEventMode", 1)

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
   ShellExecute(@ScriptDir&"\docs\documentation\documentation.html", "", "", "open")
EndFunc

Func _trayMainMenuConfigure()
   _debug("_trayMainMenuConfigure")
   _run(@ScriptDir&"\FP-QUIConfigurationAssistant.exe")
EndFunc

Func _trayMainMenuGenerateCode()
   _debug("_trayMainMenuGenerateCode")
   _run(@ScriptDir&"\FP-QUICodeGeneratorGUI.exe")
EndFunc