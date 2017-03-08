#cs

   Copyright 2010-2017 Florian Pollak (bfourdev@gmail.com)

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

#ce

#include-once

#include <_run.au3>

;searches for handle in $notificationsHandles, returns first array-index
;returns "" if handle not found
Func _handleToID($handle)

	For $i=1 To UBound($notificationsHandles)-1
		If $notificationsHandles[$i][0] == $handle Then Return $i
	Next

	SetError(1)
	Return ""

EndFunc

;returns 0 or 1
Func _notificationVisible($handle)

	If _handleToID($handle)=="" Then
		Return 0
	Else

		;we have to check whether the notification is in the delete queue, if so, it's not visible anymore
		For $i=1 To UBound($notificationsDeleteRequests)-1
			If $notificationsDeleteRequests[$i] == $handle Then Return 0
		Next

		Return 1

	EndIf

EndFunc


;looks for an notification with the same signature
;in: 	options (signature)
;out: 	is unique: -1
;		double found: ID of that notif
Func _notifGetDouble(ByRef $options)

	Local $optionsString=""
	Local $cmdLineDescriptorRequestArray=StringSplit($cmdLineDescriptorRequest,";",3)
	Local $allEqual=1

	;check if unique
	For $i=1 To UBound($notificationsOptions)-1

		$optionsString=""
		$allEqual=1

		For $j=0 To UBound($notificationsOptions,2)-1

			;skip 26, 27, 33 since they are used for internal stuff and will almost always be different
			If $j<>26 And $j<>27 And $j<>33 And $notificationsOptions[$i][$j]<>$options[$j][1] Then
				$allEqual=0
				ExitLoop
			EndIf

		Next

		;if notif with same signature found
		If $allEqual==1 Then
			Return $i ; $i = ID
		EndIf

	Next

	;nothing found, is unique
	Return -1

EndFunc

;returns optionsString
Func _optionsArrayToString($optionsArray)
;~ ConsoleWrite("_optionsArrayToString"&@LF)
	Local $optionsString=""
	Local $options = StringSplit($cmdLineDescriptorRequest,";",3)

	For $i=0 To UBound($optionsArray)-1
		$optionsString &= "<"&$options[$i]&">"&$optionsArray[$i]&"</"&$options[$i]&">"
	Next

;~ ConsoleWrite("_optionsArrayToString end"&@LF)
	Return $optionsString

EndFunc

Func _runEx($cmd)

	Run($cmd, "", @SW_HIDE)
	If @error<>0 Then _error('executing "'&$cmd&'" failed',$errorInteractive,$errorBroadcast,$errorLog,$errorLogDir,$errorLogFile,$errorLogMaxNumberOfLines)

EndFunc

Func _replaceVar(ByRef $options)

	If $options[21][1]<>"0" Then
		For $i=0 To UBound($options)-1
			$options[$i][1]=_stringReplaceVariables($options[$i][1])
			$options[$i][1]=StringReplace($options[$i][1],"%text%",$options[0][1])
		Next
	EndIf

EndFunc

Func _replaceMyHandle(ByRef $options, $myHandle)

	If $options[21][1]=="0" Then Return

	For $i=0 To UBound($options)-1
		$options[$i][1] = StringReplace($options[$i][1],"%myHandle%",$myHandle)
	Next

EndFunc
