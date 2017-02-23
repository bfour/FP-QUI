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