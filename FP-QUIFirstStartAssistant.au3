#cs

	exit codes:
		- 0 ... no error
		- 1 ... unspecified error
		- 2 ... user pressed cancel
		- 4 ... internal error
		- 8 ... user denied autostart overwrite
		

#ce

#include <_error.au3>
#include <_setAutoStart.au3>
#include <_config.au3>
#include <_fpqui.au3>

#include "modules\vars.au3"
#include "modules\initializeErrorHandling.au3"
#include "modules\setConfiguration.au3"
#include "modules\register.au3"

#include "modules\firstStartGUI.au3"



_initialize()
_mainLoop()

Func _initialize()
	
	_initializeErrorHandling()
	
	Global $dir = @ScriptDir
	Global $exe = "FP-QUI.exe"
	Global $coreExe = "FP-QUICore.exe"
	Global $exePath = $dir &"\"& $exe
	Global $coreExePath = $dir &"\"& $coreExe
	
;~ 	Global $globalConfigPath = @ScriptDir&"\data\config_global.ini"
	
	Global $reportString = ""
	Global $exitCode = 0
	
	If Not FileExists($exePath) Then
		_error($exePath&' ($exePath) does not exist.', $errorInteractive, $errorBroadCast, $errorLog, $errorLogDir, $errorLogFile, $errorLogMaxNumberOfLines, 1)
		Exit(4) ;internal error
	EndIf

	If Not FileExists($coreExePath) Then
		_error($coreExePath&' ($coreExePath) does not exist.', $errorInteractive, $errorBroadCast, $errorLog, $errorLogDir, $errorLogFile, $errorLogMaxNumberOfLines, 1)
		Exit(4) ;internal error
	EndIf
	
	; auto optimize font selection
	If @OSVersion == "WIN_2003" OR @OSVersion == "WIN_XP" OR @OSVersion == "WIN_2000" Then 
		
		_setConfiguration("defaults", "font", "Arial")
		Local $return = _fpqui("<system><reinitDefaults>1</reinitDefaults></system>", Default, 0, _ 
				"<coreNotRunning>return</coreNotRunning><requestFailed>return</requestFailed>"& _ 
				"<sendMaxRetries>8</sendMaxRetries><sendRetryPause>100</sendRetryPause>"& _ 
				"<receiveMaxRetries>0</receiveMaxRetries><receiveRetryPause>0</receiveRetryPause>", _ 
				Default, Default)
		
		; we're awaiting no response --> errCode 4
		If @error<>4 Then _error('Segoe UI does not seem to be installed. Falling back to Arial. Please restart FP-QUICore.', 1, $errorBroadCast, $errorLog, $errorLogDir, $errorLogFile, $errorLogMaxNumberOfLines, 1)
			
	EndIf

	_generateFirstStartGUI()
	_showFirstStartGUI()
	
EndFunc

Func _mainLoop()
	
	While 1
		
		$nMsg = GUIGetMsg()
		
		Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit

		Case $cancelButton
			Exit(2)
			
		Case $saveButton
			
			;AUTOSTART
			If GUICtrlRead($autoStartCheckbox)==1 Then
				
				;add autostart entry
				$return = _addAutoStart("FP-QUICore", $coreExePath, True, True)
				
				Switch @error
				Case 0
					$reportString &= "Added AutoStart entry." &@LF
					
				Case 1 ;user abort
					_error("User aborted overwrite of autostart entry.", $errorInteractive, $errorBroadCast, $errorLog, $errorLogDir, $errorLogFile, $errorLogMaxNumberOfLines)
					$reportString &= "You aborted adding an entry to your AutoStart folder."&@LF
					$exitCode = 8
					
				Case 2 ;failed to write or overwrite
					_error("Failed to add AutoStart entry.", 1, $errorBroadCast, $errorLog, $errorLogDir, $errorLogFile, $errorLogMaxNumberOfLines, 1)
					$reportString &= "Failed to add AutoStart entry ("&$return&")."&@LF
					$exitCode = 4
					
				EndSwitch
				
			Else
				
				;remove autostart entry
				_removeAutoStart("FP-QUICore")
				
				Switch @error
				Case 0
					$reportString &= "Removed AutoStart entry."&@LF
					
				Case 1 ;deletion failed
					_error("Failed to remove AutoStart entry.", 1, $errorBroadCast, $errorLog, $errorLogDir, $errorLogFile, $errorLogMaxNumberOfLines, 1)
					$reportString &= "Failed to remove AutoStart entry."&@LF
					$exitCode = 4
					
;~ 				Case 2 ;entry does not exist
;~ 				Case 3 ;1+2
				EndSwitch
				
			EndIf
			
			
			;REGISTER
			If GUICtrlRead($registerCheckbox)==1 Then
				
				;register
				_register(0)
				If @error Then 
					_error("Failed to add registry entry.", 1, $errorBroadCast, $errorLog, $errorLogDir, $errorLogFile, $errorLogMaxNumberOfLines, 1)
					$reportString &= "Failed to add registry entry."&@LF
					$exitCode = 4
				Else
					$reportString &= "Added registry entry."&@LF
				EndIf
				
			Else
				
				;deregister
				Local $return = _deregister(0)
				If @error<>0 Then 
					_error("Failed to remove registry entries. $return="&$return, 1, $errorBroadCast, $errorLog, $errorLogDir, $errorLogFile, $errorLogMaxNumberOfLines, 1) ;$return==2 ... Returns 2 if error deleting key/value.
					$reportString &= "Failed to remove registry entries."&@LF
					$exitCode = 4
				Else
					$reportString &= "Removed registry entries."&@LF
				EndIf

			EndIf

			_hideFirstStartGUI()
			;show report
			MsgBox(0+64, @ScriptName, $reportString)
			;set first start to 0
			_setConfiguration("behaviour", "firstStart", 0)
			Exit
			
		Case $helpButton
			ShellExecute($FPQUI_HELPPATH, "", "", "open")
			If @error Then _error("Could not open help file at "&$FPQUI_HELPPATH, 1, $errorBroadCast, $errorLog, $errorLogDir, $errorLogFile, $errorLogMaxNumberOfLines, 1)
	
		EndSwitch
		
		Sleep(20)
		
	WEnd
	
EndFunc