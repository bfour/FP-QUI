#cs

   Copyright 2009-2017 Florian Pollak (bfourdev@gmail.com)

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