#cs

	FP-QUI allows you to show popups in the tray area.
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

#include-once

#include <_run.au3>

Func _splashNotification($inhibitInternal=Default)

	If Not IsDeclared("inhibitInternal") Or $inhibitInternal == Default Then $inhibitInternal = 0

	Local $code = "<text>FP-QUI is running in the background</text>"
	$code &= "<bkColor>purple</bkColor>"
	$code &= "<ico>@ScriptDir\icon.ico</ico>"
	$code &= "<noDouble>1</noDouble>"
	$code &= "<delay>10000</delay>"
	$code &= "<button>"
    $code &= "<ID1><label>Help</label><cmd><shellOpen>"&$FPQUI_HELPPATH&"</shellOpen></cmd></ID1>"
	$code &= "<ID2><label>Exit</label><cmd>taskkill /PID @AutoItPID /F</cmd></ID2>"
	$code &= "</button>"
	$code &= "<untilClick><any>1</any><includeButton>1</includeButton></untilClick>"

	If $inhibitInternal==0 Then
		_processRequest($code)
	Else
		_run(@ScriptDir&"\FP-QUI.exe "&$code)
	EndIf

EndFunc