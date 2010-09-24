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

	CI:
	
	exe 
		<recip>
		<msg>
		<maxRetries>
		<retryPause>
		<errorMode>
			<QUI> 1
			msgbox
			stdout
			pipe
		<errorModePipe>
			specify pipe if pipe has been chosen as errorMode
		<errorMsg>
			what to return on error (default if empty: "pipe send failed" etc. (see below)) 

#ce

#NoTrayIcon

#include <_pipe.au3>
#include <_commandLineInterpreter.au3>

#include "modules\initializeErrorHandling.au3"

_initializeErrorHandling()

Local $interface = "recip;msg;maxRetries;retryPause;errorMode;errorModePipe;errorMsg"
Local $request = _commandLineInterpreter($CmdLineRaw, $interface)

Local $recip = $request[0][1]
Local $msg = $request[1][1]
Local $maxRetries = $request[2][1]
Local $retryPause = $request[3][1]
Local $errorMode = $request[4][1]
Local $errorPipe = $request[5][1]
Local $errorMsg = $request[6][1]

If $recip == "" Then Exit
If $maxRetries == "" Then $maxRetries = Default
If $retryPause == "" Then $retryPause = Default
If $errorMode == "" Then $errorMode = "msgbox"
If $errorMsg == "" Then $errorMsg = 'sending instructions via pipe to "'&$recip&'" failed'


Local $return=_pipeSend($recip, $msg, $maxRetries, $retryPause)

If $return<>1 Then 

	Switch $errorMode
		
		Case "QUI"
			_error($errorMsg,$errorInteractive,$errorBroadcast,$errorLog,$errorLogDir,$errorLogFile,$errorLogMaxNumberOfLines,0)
			
		Case "msgbox"
			_error($errorMsg,$errorInteractive,$errorBroadcast,$errorLog,$errorLogDir,$errorLogFile,$errorLogMaxNumberOfLines,1)
			
		Case "stdout"
			ConsoleWrite($errorMsg)
			
		Case "pipe"
			_pipeSend($errorPipe, $errorMsg)
			
		Case "log"
			_error($errorMsg,0,0,$errorLog,$errorLogDir,$errorLogFile,$errorLogMaxNumberOfLines)
			
	EndSwitch
			
EndIf
