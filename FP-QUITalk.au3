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

	author: Florian Pollak

	syntax:
		exe [string]  !!deprecated
		exe <string>[string]</string><priority>[override ... speak immediately, queue ... queue if necessary, drop ... may be dropped [default]]</priority>

#ce

#NoTrayIcon

#include <_talk.au3>
#include <_pipe.au3>
#include <_commandLineInterpreter.au3>

_initialize()
If $CmdLineRaw <> "" Then _addRequest($CmdLineRaw)
_main()

Func _initialize()

	Global $timeout 	= 10000 ; ms to wait before exit (this way we can use this instance multiple times)
	Global $timer 		= TimerInit()
	Global $pipeName 	= @ScriptName
	Global $clock 		= 500
	Global $queue 		= _initializeQueue()

	;if another instance is already up and running, exit
;~ 	Local $instances=ProcessList(@ScriptName)
;~ 	If $instances[0][0]>1 Then Exit
	;if another instance is already up and running (and has created a pipe, so we can't instantiate another one), forward the CmdLine via pipe
	_pipeReceive($pipeName,0)
	If @error == 2 Then ; pipe create failed (another instance is likely to be existent)
		_pipeSend($pipeName, $CmdLineRaw) ;TODO implement error handling
		Exit
	EndIf

EndFunc

Func _main()

	Local $buffer = ""

	While TimerDiff($timer) < $timeout

		$buffer = _pipeReceive($pipeName, 0)

		If $buffer<>"" Then
			$timer = TimerInit()
			_addRequest($buffer)
			If Not @error Then ContinueLoop ; if queue not yet full, continue
		EndIf

		_processQueue()

		Sleep($clock)

	WEnd

EndFunc

Func _addRequest($request)

	Local $instructions = _commandLineInterpreter($request, "string;priority")
	Local $string 		= $instructions[0][1]
	Local $priority		= $instructions[1][1]

	; backwards compatibility
	If $string=="" And $priority=="" Then
		$string = $request
		$priority = "drop"
	ElseIf $priority=="" Then
		$priority = "drop"
	ElseIf $string=="" Then
		; string empty
		SetError(1)
		Return ""
	EndIf

	_addQueue($queue, $string, $priority)
	_cleanQueue($queue)

EndFunc

;~ #include <array.au3>
Func _processQueue()

;~ 	_ArrayDisplay($queue)
	Local $localTimer = TimerInit()

	While TimerDiff($localTimer) < 3000

		Local $index = _getQueue($queue)
		If $index=="" Then Return 1

		$timer = TimerInit()
		_talk($queue[$index][2])
		_removeQueue($queue, $index)
		Sleep(10)

	WEnd

EndFunc


Func _initializeQueue()

	Local $queue[10][3] ; [n][0:occupied-bit, 1:priority, 2:string]
	For $i=0 To UBound($queue)-1
		$queue[$i][0] = 0
	Next

	Return $queue

EndFunc

Func _addQueue(ByRef $queue, ByRef $string, ByRef $priority)

	;get empty space and add
	For $i=0 To UBound($queue)-1
		If $queue[$i][0] == 0 Then
			$queue[$i][0] = 1
			$queue[$i][1] = $priority
			$queue[$i][2] = $string
			Return 1
		EndIf
	Next

	SetError(1)
	Return ""

EndFunc

Func _cleanQueue(ByRef $queue)

	;remove drop-entries if others exist
	Local $othersExist = 0
	Local $dropCounter = 0
	For $i=0 To UBound($queue)-1
		If $othersExist==0 And ($queue[$i][1] == "override" Or $queue[$i][1] == "queue") Then
			$othersExist = 1
		ElseIf $queue[$i][1] == "drop" Then
			$dropCounter += 1
		EndIf
	Next

;~ ToolTip($dropCounter)

	For $i=UBound($queue)-1 To 0 Step -1
		If $othersExist == 0 And $dropCounter <= 1 Then Return 1
		If $queue[$i][1] == "drop" Then
			$queue[$i][0] = 0
			$dropCounter -= 1
		EndIf
	Next

EndFunc

Func _getQueue(ByRef $queue)

	Local $queuePriorIndex = ""

	For $i=0 To UBound($queue)-1

		If $queue[$i][0] == 0 Then ContinueLoop

		Switch $queue[$i][1]

			Case "override"
				Return $i

			Case "queue"
				$queuePriorIndex = $i

			Case "drop"
				Return $i ; since the queue should have been cleaned, this must be the only drop-priority-item

		EndSwitch

	Next

	Return $queuePriorIndex

EndFunc

Func _removeQueue(ByRef $queue, $index)
	$queue[$index][0] = 0
EndFunc
