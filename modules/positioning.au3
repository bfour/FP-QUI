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

Func _repositionAll()
	
	For $i=1 To UBound($notificationsHandles)-1
			
		;set optimal size and position
;~ 		_setOptimalSize($i)
		_setOptimalPos($i)
		
	Next
	
EndFunc


Func _setSize($ID, $width, $height)

	Local $winHandle=$notificationsHandles[$ID][0]
	Local $currentSize=WinGetPos($winHandle)	

	If $width<>$currentSize[2] Or $height<>$currentSize[3] Then
		WinMove($winHandle,"",$currentSize[0],$currentSize[1],$width,$height)
	EndIf

EndFunc


;out: [0:width 1:height 2:fontSize]
Func _setOptimalSize($ID, $widthOverwrite=Default, $heightOverwrite=Default)
	
	Local $winHandle=$notificationsHandles[$ID][0]
	Local $currentSize=WinGetPos($winHandle)
	Local $currentFontSize=$notificationsOptionsData[$ID][17]
	

	Local $optimalSize=_getOptimalSize($ID, $widthOverwrite, $heightOverwrite) ;width, height, fontSize

	If $optimalSize[0]<>$currentSize[2] Or $optimalSize[1]<>$currentSize[3] Or $optimalSize[2]<>$currentFontSize Then
		
		GUISetFont($optimalSize[2],Default,Default,$notificationsOptions[$ID][16],$winHandle)
		$notificationsOptionsData[$ID][17]=$optimalSize[2]
		
		WinMove($winHandle,"",$currentSize[0],$currentSize[1],$optimalSize[0],$optimalSize[1])
		
	EndIf
	
	Return $optimalSize
	
EndFunc

;in: options-string, including width-overwrite, height-overwrite, text, icon, avi, progress, buttons
;out: [0: width, 1: height, 2: font-size]
Func _getOptimalSize($ID, $widthOverwrite=Default, $heightOverwrite=Default)
	
	If $widthOverwrite == Default Then $widthOverwrite=$notificationsOptions[$ID][3]
	If $heightOverwrite == Default Then $heightOverwrite=$notificationsOptions[$ID][4]
	
	Local $text=$notificationsOptions[$ID][0]
	Local $icon=$notificationsOptions[$ID][6]
	Local $avi=$notificationsOptions[$ID][22]
	Local $progress=$notificationsOptions[$ID][24]
	Local $buttons=$notificationsOptions[$ID][25]
	Local $fontSizeOverwrite=$notificationsOptions[$ID][17]

	Local $optimalWidth=""
	Local $optimalHeight=""
	Local $optimalFontSize=""
	
	
	;get font size
	If $fontSizeOverwrite<>"" Then
		$optimalFontSize=$fontSizeOverwrite
	Else
		$optimalFontSize=$defaultFontSize
	EndIf
	
	;get width
	If $widthOverwrite<>"" Then 
		$optimalWidth=$widthOverwrite
	Else
		
		$optimalWidth=_getWidthNeeded($text,$optimalFontSize,$icon,$avi,$buttons,$notificationsOptions[$ID][16])

		;autoFontSize if width is greater dispatcher width and no fontSizeOverwrite
		If $optimalWidth>$dispatcherArea[2] And $fontSizeOverwrite=="" Then 
			
			For $i=$optimalFontSize To 12 Step -1
				$optimalWidth=_getWidthNeeded($text,$i,$icon,$avi,$buttons,$notificationsOptions[$ID][16])
				If $optimalWidth<=$dispatcherArea[2] Then
					$optimalFontSize=$i
					ExitLoop
				EndIf
			Next
			
			;if optimal width is still greater than dispatcher width, set to smallest fontSize and break lines
			If $optimalWidth>$dispatcherArea[2] Then
				$optimalFontSize=12
				$text=_StringInsert($text,@CRLF,Int(StringLen($text)/3))
				$text=_StringInsert($text,@CRLF,Int((StringLen($text)/3)+(StringLen($text)/3)))
			EndIf
			
		EndIf

	EndIf
		
	If $heightOverwrite<>"" Then 
		$optimalHeight=$heightOverwrite
	Else
		$optimalHeight=$defaultHeight
	EndIf

	Local $returnArray[3]=[$optimalWidth,$optimalHeight,$optimalFontSize]
	Return $returnArray
	
EndFunc

	Func _getWidthNeeded($text,$fontSize,$icon,$avi,$buttons,$font)
		
		Local $widthNeeded = $defaultWidth
		
		If $text<>"" Then
			Local $idealButtonSize=_getOptimalButtonSize($text, $font, $fontSize)			
			$widthNeeded=$idealButtonSize[0]
			$widthNeeded+=50 ;looks prettier ;-)
		EndIf
		
		If $icon<>"" Then $widthNeeded+=53		
		If $avi<>"" Then $widthNeeded+=53
		If $icon<>"" Or $avi<>"" Then $widthNeeded+=5
		If $buttons<>"" Then
			
			;border
			$widthNeeded+=5
			
			;get buttons
			$buttons = _commandLineInterpreter($buttons)
			
			;add button width for each button
			For $i=0 To UBound($buttons)-1
				Local $buttonOptions = _commandLineInterpreter($buttons[$i][1],"label;font;fontSize")
				Local $idealButtonSize=_getOptimalButtonSize($buttonOptions[0][1], $buttonOptions[1][1], $buttonOptions[2][1])
				$widthNeeded += $idealButtonSize[0]
			Next
		
		EndIf

		Return $widthNeeded
		
	EndFunc


Func _getOptimalButtonSize($text, $font, $fontSize)
	
	GUICtrlSetData($dummyButton,$text)
	GUICtrlSetFont($dummyButton,$fontSize,"","",$font)
	
	Return _GUICtrlButton_GetIdealSize($dummyButton)
	
EndFunc


Func _setOptimalPos($ID)
	
;~ MsgBox(1,"","set optimal pos for "&$ID)	

	Local $xOverwrite=$notificationsOptions[$ID][13]
	Local $yOverwrite=$notificationsOptions[$ID][14]
	
	If Not(($xOverwrite<>"") And ($yOverwrite<>"")) Then
		
		Local $winHandle=$notificationsHandles[$ID][0]
		Local $currentPos=WinGetPos($winHandle)
		Local $optimalPos=_getOptimalPos($currentPos[0],$currentPos[1],$currentPos[2],$currentPos[3],$ID)

;~ 		Local $distance=Sqrt(($currentPos[0]-$optimalPos[0])^2 + ($currentPos[1]-$optimalPos[1])^2)
		Local $speed=1
;~ 		If $distance<200 Then $speed=2

		If $optimalPos[0]<>$currentPos[0] Or $optimalPos[1]<>$currentPos[1] Then
			WinMove($winHandle,"",$optimalPos[0],$optimalPos[1],$currentPos[2],$currentPos[3],$speed)
		EndIf
		
	EndIf
	
EndFunc

;returns optimal parameters in array [0:x 1:y]
Func _getOptimalPos($currentX,$currentY,$currentWidth,$currentHeight,$ID)

	;X
	Local $optimalX=$currentX
	
	If $notificationsOptions[$ID][13]<>"" Then ;overwrite
		$optimalX=$notificationsOptions[$ID][13]
	Else
		
		If StringInStr($startPos,"left")<>0 Then
			$optimalX=0
		ElseIf StringInStr($startPos,"right")<>0 Then
			$optimalX=$dispatcherArea[2]-$currentWidth
		Else
			$currentX=($dispatcherArea[2]-$currentWidth)/2 ;middle
		EndIf
		
	EndIf
	
	
	;Y
	Local $optimalY=$currentY
	
	If $notificationsOptions[$ID][14]<>"" Then ;overwrite
		$optimalY=$notificationsOptions[$ID][14]
	Else
		
		;$visibleNotificationsPos: 0:x 1:y 2:width 3:height 4:handle
		Local $visibleNotificationsPos=_getVisibleNotificationsPos()

		;delete this handle
		For $i=UBound($visibleNotificationsPos)-1 To 0 Step -1
			If $visibleNotificationsPos[$i][4]=$notificationsHandles[$ID][0] Then _ArrayDelete($visibleNotificationsPos,$i)
		Next

		Local $distances[1]
		
		;if direction is up, increase y by the length of the gap between the bottom edge of this notification and the top edge of the next notification or bottom egde of dispatcher area
		If StringInStr($direction,"up")<>0 Then
			
			Local $currentBottomEdgeY=$currentY+$currentHeight
			$optimalY=$dispatcherArea[3]-$currentHeight

			;if no other windows exist, move to bottom of screen
			If UBound($visibleNotificationsPos)==0 Then
				$optimalY=$dispatcherArea[3]-$currentHeight
			Else
				
				;get distances
				For $i=0 To UBound($visibleNotificationsPos)-1
					ReDim $distances[UBound($distances)+1]
					$distances[UBound($distances)-1]=$visibleNotificationsPos[$i][1]-$currentBottomEdgeY
				Next
				_ArrayDelete($distances,0)
				
				;get smallest positive distance
				_ArraySort($distances)
;~ 	_ArrayDisplay($distances,"$distances")

				For $i=0 To UBound($distances)-1
					If $distances[$i]>=0 Then 
						$optimalY=($currentY+$distances[$i])-1
						ExitLoop
					EndIf
				Next
			
			EndIf		
			
		ElseIf StringInStr($direction,"down")<>0 Then
			
		EndIf
	
	EndIf
	
	Local $returnArray[4]=[$optimalX,$optimalY]
	
;~ _ArrayDisplay($returnArray,"$optimalX,$optimalY")

	Return $returnArray
		
EndFunc




;return: array: 0:x 1:y 2:width 3:height 4:handle
Func _getVisibleNotificationsPos()

	Local $returnArray[UBound($notificationsHandles)][5]

	For $i=1 To UBound($notificationsHandles)-1
		
		Local $pos=WinGetPos($notificationsHandles[$i][0])
		Local $visible=BitAND(WinGetState($notificationsHandles[$i][0]),2)

		If $visible And IsArray($pos) Then 
			$returnArray[$i][0]=$pos[0]
			$returnArray[$i][1]=$pos[1]
			$returnArray[$i][2]=$pos[2]
			$returnArray[$i][3]=$pos[3]
			$returnArray[$i][4]=$notificationsHandles[$i][0]
		EndIf
		
	Next
	
	;delete empties
	For $i=UBound($returnArray)-1 To 0 Step -1
		If $returnArray[$i][0]=="" Then _ArrayDelete($returnArray,$i)
	Next
	
	Return $returnArray

EndFunc



