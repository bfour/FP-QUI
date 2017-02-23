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

#include <_run.au3>

Func _handleFirstStart($behaviourFirstStart, $behaviourshowFirstStartGUI)

	If $behaviourFirstStart==1 And $behaviourshowFirstStartGUI==1 Then

		Local $return
;~ 		$return = _runWait(@ScriptDir&"\FP-QUIFirstStartAssistant.exe")
		$return = _run(@ScriptDir&"\FP-QUIFirstStartAssistant.exe")

		#cs
			exit codes:
				- 0 ... no error
				- 1 ... unspecified error
				- 2 ... user pressed cancel
				- 4 ... internal error
				- 8 ... user denied autostart overwrite
		#ce
;~ 		Switch $return
;~
;~ 		Case 0
;~
;~ 		Case 1
;~
;~
;~ 		EndSwitch
	EndIf

EndFunc