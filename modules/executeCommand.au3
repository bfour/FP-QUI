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

#include-once

#include <_commandLineInterpreter.au3>
;~ #include <_run.au3>

Func _executeCommand($cmd)
	
;~ _debug("execute commd "&$cmd)	

	;shell open if wrapped in <shellOpen></shellOpen>
	If StringRegExp($cmd,"<shellOpen>.*</shellOpen>") Then
;~ _debug("shellopen")		
		
		$cmd=_commandLineInterpreter($cmd,"shellOpen")
		$cmd=$cmd[0][1]
		Local $return = ShellExecute($cmd,"","","open")
		Local $error = @error
		
		If $error Then _error('Failed to execute via shell: '&$cmd,$errorInteractive,$errorBroadcast,$errorLog,$errorLogDir,$errorLogfile,$errorLogMaxNumberOfLines)
		
		SetError($error)
		Return $return
	
	ElseIf StringRegExp($cmd,"<internal>.*</internal>") Then
	
;~ _debug("start commndline interp")		
		$cmd=_commandLineInterpreter($cmd,"internal")
;~ _debug("end commdline interp")		
		
		$cmd=$cmd[0][1]
		Local $return = _processRequest($cmd)
		Local $error = @error
		
;~ 		If $error Then _error('Failed to process request: '&$cmd,$errorInteractive,$errorBroadcast,$errorLog,$errorLogDir,$errorLogfile,$errorLogMaxNumberOfLines)
		
		SetError($error)
		Return $return
	
	Else
	
;~ _debug("run")	
		Local $return = _runEx($cmd)
;~ _debug("returned from _run")	
		Local $error = @error
				
		SetError($error)
		Return $return
	
	EndIf
		
_debug("end execute commd")	
	
	
EndFunc