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

Func _initializeDispatcherArea()

	Global $dispatcherWindowTitle=_iniRead($globalConfigPath,"dispatcherWindow","title","FP-QUI/dispatcherWindow")
	Global $dispatcherArea=_getDispatcherArea()
	Global $startPos=_iniRead($globalConfigPath,"dispatcherWindow","startPos","bottom,right")
	Global $direction=_iniRead($globalConfigPath,"dispatcherWindow","direction","up,left")
	
EndFunc

Func _getDispatcherArea()
	
	Local $displayPos=_displayGetPos() ;0:x, 1:y, 2:width, 3:height, 4:is primary
	
	Local $dispatcherArea=_iniRead($globalConfigPath,"dispatcherWindow","area","screen1")
	Local $screenSelection=0
	
	If StringInStr($dispatcherArea,"screen")==1 Then
		
		Local $screenSelection=Int(StringReplace($dispatcherArea,"screen",""))
		
		If UBound($displayPos)<$screenSelection Then
			
			_error('screenSelection "'&$screenSelection&'" is invalid, '&UBound($displayPos)&' display(s) detected, setting default display instead',$errorInteractive,$errorBroadcast,$errorLog,$errorLogDir,$errorLogFile,$errorLogMaxNumberOfLines)
			Local $dispatcherArea[$i][4]=[0,0,@DesktopWidth,@DesktopHeight]
			
		Else
			
			Local $dispatcherArea[4]=[$displayPos[$screenSelection][0],$displayPos[$screenSelection][1],$displayPos[$screenSelection][2],$displayPos[$screenSelection][3]]
			
		EndIf
	
	Else
	
		_error('dispatcherArea "'&$dispatcherArea&'" is invalid, '&UBound($displayPos)&' display(s) detected, setting default display instead',$errorInteractive,$errorBroadcast,$errorLog,$errorLogDir,$errorLogFile,$errorLogMaxNumberOfLines)
		Local $dispatcherArea[$i][4]=[0,0,@DesktopWidth,@DesktopHeight]
		
	EndIf
	
	
	;reduce by taskbar-area
		;where's the taskbar?
		
			;get pos
	Opt("WinTitleMatchMode",4)
	Local $taskbarPos=WinGetPos("[CLASS:Shell_TrayWnd]")
	If Not IsArray($taskbarPos) Then $taskbarPos[4]=[0,0,0,0]
	


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

	Return $dispatcherArea
	
EndFunc