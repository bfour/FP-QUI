#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Array.au3>

#include <_run.au3>
#include <_fpqui.au3>
#include <_path.au3>

#include "deploy_shared.au3"


#Region ### START Koda GUI section ### Form=E:\sabox\grid\FP-QUI\gui\deployGUI.kxf
$Form1_1 = GUICreate("deploy", 571, 394, 338, 367)
$Edit1 = GUICtrlCreateEdit("", 8, 40, 553, 289)
GUICtrlSetData(-1, "Edit1")
$Input1 = GUICtrlCreateInput("Input1", 8, 8, 553, 24)
$cancel = GUICtrlCreateButton("Cancel", 152, 336, 195, 49, 0)
$OK = GUICtrlCreateButton("OK", 352, 336, 211, 49, 0)
$Checkbox1 = GUICtrlCreateCheckbox("no changelog entry", 8, 344, 137, 33)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

GUICtrlSetData($Input1,@YEAR&@MON&@MDAY&"T"&@HOUR&@MIN)
GUICtrlSetData($Edit1,"")


While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE, $cancel
			Exit
			
		Case $OK
			GUISetState(@SW_HIDE)
			_deploy()

	EndSwitch
WEnd


Func _deploy()
	
	Local $version = GUICtrlRead($Input1)
	
	If GUICtrlRead($Checkbox1)<>1 Then 
		Local $text = GUICtrlRead($Edit1)
		$text=StringSplit($text,@CRLF,3)
		_ArrayReverse($text)
		
		_addChangeLogEntry($text,$version)
	EndIf
	
	_fpqui("<text>wrapping-up</text><ico>"&@ScriptDir&"\icon.ico</ico><avi>%grid%\FP-QUI\GUI\busy_indicator.avi</avi><untilProcessClose>"&@AutoItPID&"</untilProcessClose><bkColor>purple</bkColor>")
	_runWait(@ScriptDir&"\deployBinary.exe "&$version)
;~ 	_runWait(@ScriptDir&"\deploySource.exe "&$version)
		
	
	Beep(500,400)
	_fpqui("<text>"&$version&" is ready for deployment</text><bkColor>green</bkColor><delay>6000</delay><ico>"&@ScriptDir&"\icon.ico</ico>")
	
	Exit
	
EndFunc