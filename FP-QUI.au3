#cs

   FP-QUI allows you to show popups in the tray area.
   It can be controlled via command line or named pipes.

   Copyright 2010-2017 Florian Pollak (bfourdev@gmail.com

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

   Provides an interface for FP-QUICore. Alternatively, you may use FP-QUICore itself. The syntax is exactly the same. Since FP-QUI only includes the code necessary to process an invoke and communicate with FP-QUICore it should need less resources to be executed.

   1.) checks if a main-instance is running, starts one if necessary
   2.) forwards invoke to main
   3.) delivers response

#ce

#CS

   interface:
   return values: 1 ... generic error occured, -1 ... FP-QUICore could not be started, 0 ... no error occured

#CE

#NoTrayIcon

; disable config-init for performance reasons
Global $_configInit = False

#Include <Misc.au3>

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
If $request == "" Then $request = "<system><menu>1</menu></system>"

; check whether core is running
If _Singleton("FP-QUICore", 1) == 0 Then
   ; core not running -> launch it
   _run(@ScriptDir&"\FP-QUICore.exe")
   If ProcessWait("FP-QUICore.exe",10)==0 Then
      _error("FP-QUICore.exe is not running. Please start it manually. FP-QUICore must be running in the background to be able to receive requests.",1,0,0,"","","",1)
      Exit(-1)
   EndIf
EndIf

_forwardRequest($request)

Exit(@error)
