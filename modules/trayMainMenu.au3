#include-once

#include "mainMenu.au3"

Func _trayMainMenu()
	
	Opt("TrayMenuMode",1)
	Opt("TrayOnEventMode",1)
	
	TraySetOnEvent($TRAY_EVENT_PRIMARYDOWN, "_mainMenu")
;~ 	TraySetOnEvent($TRAY_EVENT_PRIMARYUP, "_mainMenu" )
	TraySetOnEvent($TRAY_EVENT_SECONDARYDOWN, "_mainMenu")
;~ 	TraySetOnEvent($TRAY_EVENT_SECONDARYUP, "_mainMenu" )
;~ 	TraySetOnEvent($TRAY_EVENT_PRIMARYDOWN, "_mainMenu" )
	
EndFunc