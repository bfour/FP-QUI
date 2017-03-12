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
   Global $startPos               = _iniRead($globalConfigPath,"dispatcherWindow","startPos","bottom,right")
   Global $direction              = _iniRead($globalConfigPath,"dispatcherWindow","direction","up,left")
   Global $lastDisplayHash        = _displayGetPosHash()
   Global $lastTaskbarHash        = _taskbarGetPosHash()

EndFunc

Func _getDispatcherArea()

   Opt("WinTitleMatchMode",4)
   Local $dispatcherArea = WinGetPos(_WinAPI_GetDesktopWindow())
   Local $displayPos[1][4]
   $displayPos[0][0] = $dispatcherArea[0]
   $displayPos[0][1] = $dispatcherArea[1]
   $displayPos[0][2] = $dispatcherArea[2]
   $displayPos[0][3] = $dispatcherArea[3]
   $screenSelection = 0

   ;reduce by taskbar-area
      ;where's the taskbar?

         ;get pos
   Opt("WinTitleMatchMode",4)
   Local $taskbarPos[4]
   Local $curTaskbarPos = WinGetPos("[CLASS:Shell_TrayWnd]")
   If Not IsArray($curTaskbarPos) Then
      $taskbarPos[0] = 0
      $taskbarPos[1] = 0
      $taskbarPos[2] = 0
      $taskbarPos[3] = 0
    Else
      $taskbarPos = $curTaskbarPos
    EndIf
    _debug("taskbar pos: "&$taskbarPos[0]&","&$taskbarPos[1]&","&$taskbarPos[2]&","&$taskbarPos[3])

         ;which screen?
   Local $taskbarScreen=""
   For $i=0 To UBound($displayPos)-1
      ;is taskbar x and y within disp?
      If (($displayPos[$i][0] < $taskbarPos[0]+3) And ($taskbarPos[0]+3 < ($displayPos[$i][0]+$displayPos[$i][2]))) And _
         (($displayPos[$i][1] < $taskbarPos[1]+3) And ($taskbarPos[1]+3 < ($displayPos[$i][1]+$displayPos[$i][3]))) Then $taskbarScreen=$i
   Next

   If $taskbarScreen=="" Then
      _error("unable to determine on which display the taskbar is, setting 0",$errorInteractive,$errorBroadcast,$errorLog,$errorLogDir,$errorLogFile,$errorLogMaxNumberOfLines)
      $taskbarScreen=0
   EndIf


         ;which location? (top, bottom, left, right)
   Local $taskbarLocation=""
   ;if w>h then top OR bottom else left OR right
   ;top/bottom: if y+-3 = y(disp) then bottom
   ;left/right: if x+-3 = x(disp) then left
   If $taskbarPos[2]>$taskbarPos[3] Then
      ;top or bottom
      If (($taskbarPos[1]+3 > $displayPos[$taskbarScreen][1]) And ($taskbarPos[1]-3 < $displayPos[$taskbarScreen][1])) Then
         $taskbarLocation="top"
      Else
         $taskbarLocation="bottom"
      EndIf
   Else
      ;left or right
      If (($taskbarPos[0]+3 > $displayPos[$taskbarScreen][0]) And ($taskbarPos[0]-3 < $displayPos[$taskbarScreen][0])) Then
         $taskbarLocation="left"
      Else
         $taskbarLocation="right"
      EndIf
   EndIf

   ;if dispatcher is on same display, do trim
   If $screenSelection==$taskbarScreen Then

      Switch $taskbarLocation

      Case "top"
         $dispatcherArea[1]=$dispatcherArea[1]+($taskbarPos[1]+$taskbarPos[3]) ;y
         $dispatcherArea[3]=$dispatcherArea[3]-($taskbarPos[1]+$taskbarPos[3]) ;height

      Case "bottom"
         $dispatcherArea[3]=$taskbarPos[1] ;height

      Case "left"
         $dispatcherArea[0]=$dispatcherArea[0]+($taskbarPos[0]+$taskbarPos[2]) ;x
         $dispatcherArea[2]=$dispatcherArea[2]-($taskbarPos[0]+$taskbarPos[2]) ;width

      Case "right"
         $dispatcherArea[2]=$taskbarPos[0] ;width

      EndSwitch

   EndIf

    _debug("returning dispatcher area:" &$dispatcherArea[0]&","&$dispatcherArea[1]&","&$dispatcherArea[2]&","&$dispatcherArea[3])
   Return $dispatcherArea

EndFunc

Func _taskbarGetPosHash()

   Opt("WinTitleMatchMode",4)
   Local $pos=WinGetPos("[CLASS:Shell_TrayWnd]")
   Local $posString = ""
   For $i=0 To UBound($pos)-1
     $posString &= $pos[$i]
   Next

   Return _WinAPI_HashString($posString, True)

EndFunc