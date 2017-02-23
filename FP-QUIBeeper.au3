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

#cs

	interface: exe <beep>freq;duration|freq;duration|...</beep>

	exit codes:
		0 ... proper execution
		1 ... error occured, most likely due to improper arguments

#ce

#NoTrayIcon

#include <array.au3>
#include <_commandLineInterpreter.au3>

If $CmdLineRaw == "" Then Exit

Global $exitCode=0

Global $request=_commandLineInterpreter($CmdLineRaw,"beep")
$request=$request[0][1]

Global $beeps=StringSplit($request,"|",3)

For $i=0 To UBound($beeps)-1

	Local $beep=StringSplit($beeps[$i],";",3)
	If UBound($beep)==2 Then
		Beep($beep[0],$beep[1])
	Else
		$exitCode=1
	EndIf

Next

Exit($exitCode)