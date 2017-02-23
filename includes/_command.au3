#include-once

#include <_error.au3>

Func _commandStripParams($command)
	
	;clean string
	$command=StringStripCR($command)
	$command=StringStripWS($command,1+2)
	
	;if command starts with " then detect non-param part by "
	If StringLeft($command,1)=='"' Then
		
		$commandParts=StringSplit($command,'"',3)
		
		For $i=0 To UBound($commandParts)-1
			If $commandParts[$i]<>"" Then 
				$command=$commandParts[$i]
				ExitLoop
			EndIf
		Next
	
	;else detect by whitespace
	Else
		
		$commandParts=StringSplit($command,' ',3)
		
		For $i=0 To UBound($commandParts)-1
			If $commandParts[$i]<>"" Then 
				$command=$commandParts[$i]
				ExitLoop
			EndIf
		Next
		
	EndIf
		
	Return $command
	
EndFunc