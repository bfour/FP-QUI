#include-once

#include "mainMenu.au3"
#include <_run.au3>
#include <wmCopyData.au3>

Func _trayMainMenu()

   Opt("TrayAutoPause", 0)
   Opt("TrayMenuMode", 1+2)
   Opt("TrayOnEventMode", 1)

   TraySetClick(8) ; Tooltip on left mouse and main menu on right mouse
   TraySetOnEvent($TRAY_EVENT_PRIMARYDOWN, "theTrayEventHandler")

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

Func theLeftMouseTooltip()
    local $btn1 = "Help"
    local $btn2 = "Exit"
    local $cmd1 = "<shellOpen>@ScriptDir\docs\documentation\documentation.html</shellOpen>"
    local $cmd2 = "taskkill /PID @AutoItPID /F"
    local $btn = ""
    $btn &= "<ID1><fontSize>12</fontSize><label>"&$btn1&"</label><cmd>"&$cmd1&"</cmd></ID1>"
    $btn &= "<ID2><fontSize>12</fontSize><label>"&$btn2&"</label><cmd>"&$cmd2&"</cmd></ID2>"
    local $msg = "<text>FP-QUI: perfect tooltip notification system.</text>"
    $msg &= "<bkColor>0xBC8BDA</bkColor><ico>@ScriptDir\icon.ico</ico><noDouble>1</noDouble><delay>5000</delay>"
    $msg &= "<trans>255</trans><font>Tahoma Bold</font><fontSize>16</fontSize><untilClick><any>1</any><includeButton>1</includeButton></untilClick>"
    $msg &= "<button>"&$btn&"</button>"
    wmCopyDataFifoPut( $msg )
EndFunc

Func theTrayEventHandler()
    Switch @TRAY_ID
        Case $TRAY_EVENT_PRIMARYDOWN
            theLeftMouseTooltip()
    EndSwitch
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