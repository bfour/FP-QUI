Func _doCheckLifetime($i)
	
	If ( _ 
		($notificationsOptions[$i][1]<>"" And TimerDiff($notificationsOptionsData[$i][1])>=$notificationsOptions[$i][1]) Or _ ;delay
		($notificationsOptions[$i][8]<>"" And ProcessExists($notificationsOptions[$i][8])<>0) Or _ ;untilProcessExists
		($notificationsOptions[$i][9]<>"" And ProcessExists($notificationsOptions[$i][9])==0) _ ;untilProcessClose
	   ) _ 
	Then 
		_hideNotification($i)
	EndIf
	
EndFunc