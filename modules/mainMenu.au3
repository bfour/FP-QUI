#include-once

#include <_run.au3>

Func _mainMenu($inhibitInternal=Default)
	
	If Not IsDeclared("inhibitInternal") Or $inhibitInternal == Default Then $inhibitInternal = 0
	
	$button1Label = "Terminate"
	$button2Label = "Restart"
	$button3Label = "Help"
	$button4Label = "Configure"
	$button5Label = "Generate Code"
	
	$button1Command = "taskkill /PID @AutoItPID /F"
	$button2Command = "@ScriptDir\tools\FP-BatchProcessor.exe <runWait><cmd>taskkill /PID @AutoItPID /F</cmd></runWait><run><cmd>@ScriptDir\FP-QUICore.exe</cmd></run>"
	$button3Command = "<shellOpen>@ScriptDir\docs\documentation\documentation.html</shellOpen>"
	$button4Command = "@ScriptDir\FP-QUIConfigurationAssistant.exe"
	$button5Command = "@ScriptDir\FP-QUICodeGeneratorGUI.exe"
	
;~ 	If @ScriptName == "FP-QUICore.exe" Then
;~ 		$button1Command = "taskkill /PID "&@AutoItPID&" /F"
;~ 		$button2Command = "@ScriptDir\tools\FP-BatchProcessor.exe <runWait>taskkill /PID "&@AutoItPID&" /F</runWait><run>@ScriptDir\FP-QUICore.exe</run>")		
;~ 	EndIf

	Local $code = "<bkColor>0xBC8BDA</bkColor><ico>@ScriptDir\icon.ico</ico><noDouble>1</noDouble><delay>10000</delay><button><ID1><label>"&$button1Label&"</label><font>Segoe UI</font><fontSize>16</fontSize><textColor>0x000000</textColor><cmd>"&$button1Command&"</cmd></ID1><ID2><label>"&$button2Label&"</label><font>Segoe UI</font><fontSize>16</fontSize><textColor>0x000000</textColor><cmd>"&$button2Command&"</cmd></ID2><ID3><label>"&$button3Label&"</label><font>Segoe UI</font><fontSize>16</fontSize><textColor>0x000000</textColor><cmd>"&$button3Command&"</cmd></ID3><ID4><label>"&$button4Label&"</label><font>Segoe UI</font><fontSize>16</fontSize><textColor>0x000000</textColor><cmd>"&$button4Command&"</cmd></ID4><ID5><label>"&$button5Label&"</label><font>Segoe UI</font><fontSize>16</fontSize><textColor>0x000000</textColor><cmd>"&$button5Command&"</cmd></ID5></button>"

	
	If $inhibitInternal==0 Then
		_processRequest($code)
	Else
		_run(@ScriptDir&"\FP-QUI.exe "&$code)
	EndIf

EndFunc