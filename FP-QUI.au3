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

	
	Provides an interface for FP-QUICore. Alternatively, you may use FP-QUICore itself. The syntax is exactly the same. Since FP-QUI only includes the code necessary to process an invoke and communicate with FP-QUICore it should need less resources to be executed.
	
	1.) checks if a main-instance is running, starts one if necessary
	2.) forwards invoke to main
	3.) delivers response

#ce

#CS 

	interface:
	return values: 1 ... generic error occured, -1 ... FP-QUICore could not be started, 0 ... no error occured 
	
#CE

Global $debug = 1
;~ Global $debugTimer = TimerInit()
Func _debug($string)
;~ 	If $debug==1 Then ConsoleWrite(TimerDiff($debugTimer)&" - "&$string&@LF)
EndFunc

#NoTrayIcon

; disable config-init for performance reasons
Global $_configInit = False

#Include <Misc.au3>
#Include <NamedPipes.au3>

#include <_run.au3>

#include "modules\initializeErrorHandling.au3"
#include "modules\initializeBehaviour.au3"
#include "modules\forwardRequest.au3"

#include "modules\setBehaviour.au3"
;~ #include "modules\argumentsPrompt.au3"

_initializeErrorHandling()
_initializeBehaviour()

Global $errorForceMsgBox=1

;check if maxInstances is reached
Local $procList = ProcessList(@ScriptName)
If $procList[0][0] > $behaviourMaxInstances Then
	_error("maximum number of instances reached: "&$procList[0][0], 0, 0, $errorLog,$errorLogDir,$errorLogFile,$errorLogMaxNumberOfLines)
	Exit
EndIf

Local $request = $CmdLineRaw
;~ If $request=="" Then
;~ 	
;~ 	If $behaviourPromptIfNoArguments==1 Then 
;~ 		$request=_argumentsPrompt()
;~ 		If $request=="" Then Exit
;~ 	Else
;~ 		Exit
;~ 	EndIf
;~ 	
;~ EndIf
If $request == "" Then $request = "<system><menu>1</menu></system>"

;ensure notifier is running
If Not _NamedPipes_WaitNamedPipe("\\.\pipe\FP-QUI") Then ; pipe does not exist --> not running
	
	_run(@ScriptDir&"\FP-QUICore.exe")
	If ProcessWait("FP-QUICore.exe",10)==0 Then
		_error("FP-QUICore.exe is not running. Please start it manually. FP-QUICore must be running in the background to be able to receive requests.",1,0,0,"","","",1)
		Exit(-1)
	EndIf
	
EndIf

_forwardRequest($request)

Exit(@error)
