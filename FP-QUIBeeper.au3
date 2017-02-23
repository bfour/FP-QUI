#cs

	FP-QUI allows you to show notifications (popups) in the tray area.
	It can be controlled via command line or named pipes.
    Copyright (C) 2010 Florian Pollak

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.
	If not, see http://www.gnu.org/licenses/gpl.html.

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