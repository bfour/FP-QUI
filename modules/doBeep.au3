Func _doBeep($i)

	If $notificationsOptions[$i][12]<>"" Then
		
		Local $beep=_commandLineInterpreter($notificationsOptions[$i][12],"string;repeat;pause;shake")
		Local $string=$beep[0][1]
		Local $repeat=$beep[1][1]
		Local $pause=$beep[2][1]
		Local $shake=$beep[3][1]
		
		;avoid unexpected behaviour
		If $repeat=="" And $pause=="" Then $repeat=1
		If $pause<1000 Then $pause=1000
		
		Local $beepData=_commandLineInterpreter($notificationsOptionsData[$i][12],"timer;repetitions")
		Local $timer=$beepData[0][1]
		Local $repetitions=$beepData[1][1]
		
		If (($timer=="" Or $pause=="" Or TimerDiff($timer)>$pause) And ($repetitions=="" Or $repeat=="" Or $repetitions<$repeat)) Then 
			
			_runEx(@ScriptDir&"\FP-QUIBeeper.exe <beep>"&$string&"</beep>")
			
			If $shake<>"" Then _shakeNotification($i)

			If $pause<>"" Then $timer=TimerInit() ;only store timer if relevant
			If $repeat<>"" Then $repetitions+=1 ;only store repetitions if relevant
			$notificationsOptionsData[$i][12]="<timer>"&$timer&"</timer><repetitions>"&$repetitions&"</repetitions>"
			
		EndIf
		
	EndIf
	
EndFunc