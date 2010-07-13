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
	this forwards a request (via cmdLine) to an existing instance of FP-QUI, that runs the "FP-QUI"-pipe (since only one instance of such a pipe is allowed, there can only be one process) (this instance is also referred to as "main" (--> forward to main))
	
	-) checks if request is an update for an existing notification (indicated by winHandle<>"" in arguments)
		-) if true 
			sends update request to main
		-) if false 
			sends create request to main
			waits for response (winHandle)
			sends response to requeste

#ce

#include-once

#include <_commandLineInterpreter.au3>
#include <_pipe.au3>
#include <_error.au3>

;in: request
;out: success: 1, else: 0
;@error: no error: 0, generic error: 1
Func _forwardRequest($input)

	If $input=="" Then 
		SetError(1)
		Return 0
	EndIf
	
	Local $pipeRetries=20
	Local $pipeTimeout=1500
	Local $pipeReceiveTimeout=60000

	Local $replyInstructions=_commandLineInterpreter($input,"reply")
	$replyInstructions=_commandLineInterpreter($replyInstructions[0][1],"pipe;stdout")

	;no reply requested
	If $input<>"" And $replyInstructions[0][1]=="" And $replyInstructions[1][1]=="" Then
		
		Local $return=_pipeSend("FP-QUI",$input,$pipeRetries,$pipeTimeout)
		
		If $return<>1 Then
			_error("_start (other instance running/update (noreply)): _pipeSend encountered an error, could not send invoke to main; return="&$return,$errorInteractive,$errorBroadcast,$errorLog,$errorLogDir,$errorLogFile,$errorLogMaxNumberOfLines,1)
			SetError(1)
			Return 0
		EndIf
		
	;stdout or pipe reply requested			
	Else

		Local $reply="error"
		Local $internalReturnPipe="FP-QUI"&@AutoItPID
		
		;send request to main, append internalReturnPipe
		Local $return=_pipeSend("FP-QUI",$input&"<reply><pipe>"&$internalReturnPipe&"</pipe></reply>",$pipeRetries,$pipeTimeout)
		
		If $return<>1 Then 
			_error("_start (other instance running/new): _pipeSend encountered an error, could not send invoke to main; return="&$return,$errorInteractive,$errorBroadcast,$errorLog,$errorLogDir,$errorLogFile,$errorLogMaxNumberOfLines,1)
			SetError(1)
			Return 0
		Else 
			
			;receive answer from main, hopefully containing the new handle
			Local $timer=TimerInit()
			
			While 1
				$return=_pipeReceive($internalReturnPipe,0)
				If $return<>"" Or TimerDiff($timer)>$pipeReceiveTimeout Then ExitLoop
				Sleep(1000)
			WEnd
				
			If $return=="" Then 
				_error("_start (other instance running/new): _pipeReceive timeout, could not receive answer from main via internal pipe in time; return="&$return,$errorInteractive,$errorBroadcast,$errorLog,$errorLogDir,$errorLogFile,$errorLogMaxNumberOfLines,1)
				SetError(1)
				Return 0
			Else
				$reply=$return
			EndIf
			
		EndIf
			
		;give requester a reply
		
			;via stdout
		If $replyInstructions[1][1]<>"" Then ConsoleWrite($reply)
		
			;via pipe
		If $replyInstructions[0][1]<>"" Then 
			
			$return=_pipeSend($replyInstructions[0][1],$reply)
			
			If $return<>1 Then 
				_error("_start (other instance running/new): _pipeSend encountered an error, could not send an answer to caller; return="&$return&"; pipe name:"&$returnPipe,$errorInteractive,$errorBroadcast,$errorLog,$errorLogDir,$errorLogFile,$errorLogMaxNumberOfLines,1)
				SetError(1)
				Return 0
			EndIf
			
		EndIf

	EndIf
	
	Return 1
	
EndFunc