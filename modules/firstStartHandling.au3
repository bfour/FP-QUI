#include <_run.au3>

Func _handleFirstStart($behaviourFirstStart, $behaviourshowFirstStartGUI)
	
	If $behaviourFirstStart==1 And $behaviourshowFirstStartGUI==1 Then 
		
		Local $return
;~ 		$return = _runWait(@ScriptDir&"\FP-QUIFirstStartAssistant.exe")
		$return = _run(@ScriptDir&"\FP-QUIFirstStartAssistant.exe")

		#cs
			exit codes:
				- 0 ... no error
				- 1 ... unspecified error
				- 2 ... user pressed cancel
				- 4 ... internal error
				- 8 ... user denied autostart overwrite
		#ce
;~ 		Switch $return
;~ 			
;~ 		Case 0
;~ 			
;~ 		Case 1
;~ 			
;~ 			
;~ 		EndSwitch
	EndIf
	
EndFunc