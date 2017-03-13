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

#include <WinAPIMisc.au3>
#include <WinAPI.au3>

Func _initializeDispatcherArea()

   Global $dispatcherWindowTitle  = _iniRead($globalConfigPath,"dispatcherWindow","title","FP-QUI/dispatcherWindow")
   Global $dispatcherArea         = _getDispatcherArea()
   Global $lastDispatcherArea     = $dispatcherArea
   Global $startPos               = _iniRead($globalConfigPath,"dispatcherWindow","startPos","bottom,right")
   Global $direction              = _iniRead($globalConfigPath,"dispatcherWindow","direction","up,left")

EndFunc

Func _getDispatcherArea()

   Local $screen = _iniRead($globalConfigPath, "dispatcherWindow", "screen", "primary")
   Local $displays = _displayGetEnum()
   Local $screenArea[4]
   Local $workingArea[4]

   If $screen == "primary" Or Number($screen) >= UBound($displays) Then
	  Local $primaryDisplay = _displayGetPrimary()
	  $screenArea = StringSplit($primaryDisplay[0], ";", 2)
	  $workingArea = StringSplit($primaryDisplay[1], ";", 2)
   Else
	  $screenArea = StringSplit($displays[$screen][0], ";", 2)
	  $workingArea = StringSplit($displays[$screen][1], ";", 2)
   EndIf

;~    _debug("$screenArea:" &$screenArea[0]&","&$screenArea[1]&","&$screenArea[2]&","&$screenArea[3])
;~    _debug("$workingArea:" &$workingArea[0]&","&$workingArea[1]&","&$workingArea[2]&","&$workingArea[3])

   Local $dispatcherArea = [$workingArea[0], $workingArea[1], $workingArea[2]-$workingArea[0], $workingArea[3]-$workingArea[1]]

;~    _debug("returning dispatcher area:" &$dispatcherArea[0]&","&$dispatcherArea[1]&","&$dispatcherArea[2]&","&$dispatcherArea[3])
   Return $dispatcherArea

EndFunc

Func _dispatcherAreaHasChanged()

;~    _debug("dispatcher area has changed?")

   Local $calculatedDispatcherArea = _getDispatcherArea()

   For $i = 0 To UBound($calculatedDispatcherArea)-1
	  If $calculatedDispatcherArea[$i] <> $lastDispatcherArea[$i] Then
		 ; has changed
		 $lastDispatcherArea = $calculatedDispatcherArea
		 Return $calculatedDispatcherArea
	  EndIf
   Next

   ; has not changed
;~    _debug("dispatcher area has NOT changed")
   Return False

EndFunc