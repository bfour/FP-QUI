#include-once

#include <_error.au3>

;returns path to grid-directory
Func _gridDir()
		
	Local $scriptDirSplit=StringSplit(@ScriptDir,"\")
	Local $gridDir=""

	For $i=UBound($scriptDirSplit)-1 To 1 Step -1
		
		If $scriptDirSplit[$i]="grid" Then
			
			For $j=1 To $i Step 1
				$gridDir&=$scriptDirSplit[$j]&"\"
			Next
			
			$gridDir=StringTrimRight($gridDir,1)
			
		EndIf
		
	Next
	
	If DirGetSize($gridDir,2)==-1 Then 
	   SetError(1)
	   Return ""
	EndIf
	
	Return $gridDir
	
EndFunc