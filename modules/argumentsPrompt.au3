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

#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

#Include <GuiEdit.au3>

Func _argumentsPrompt()
	
	Opt("GUIOnEventMode",0)
	
#Region ### START Koda GUI section ### Form=e:\sabox\grid\FP-QUI\gui\argumentsprompt.kxf
$argumentsPrompt = GUICreate(@ScriptName, 549, 225, 436, 378)
$OKButton = GUICtrlCreateButton("OK", 352, 184, 91, 33, 0)
$cancelButton = GUICtrlCreateButton("Cancel", 448, 184, 91, 33, 0)
$doNotShowAgainCheckbox = GUICtrlCreateCheckbox("Do not show again.", 352, 160, 145, 17)
GUICtrlSetState(-1, $GUI_DISABLE)
GUICtrlSetState(-1, $GUI_HIDE)
$argumentsEdit = GUICtrlCreateEdit("", 8, 8, 529, 145, BitOR($ES_AUTOVSCROLL,$WS_VSCROLL))
GUICtrlSetData(-1, "<text>Hello.</text>")
$bracketButton = GUICtrlCreateButton("<>", 8, 160, 75, 25, 0)
$closeBracketButton = GUICtrlCreateButton("</>", 88, 160, 75, 25, 0)
$combo = GUICtrlCreateCombo("", 8, 192, 233, 25)
GUICtrlSetData(-1, "text|textColor|bkColor|talk|ico", "text")
$clearButton = GUICtrlCreateButton("clear", 168, 160, 75, 25, 0)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

	While 1
		
		$nMsg = GUIGetMsg()
		
		Switch $nMsg
			
		Case $GUI_EVENT_CLOSE
			GUISetState(@SW_HIDE,$argumentsPrompt)
			_argumentsPromptProcessCheckbox($doNotShowAgainCheckbox)
			Return ""
			
		Case $bracketButton, $closeBracketButton
			
			Local $index=_GUICtrlEdit_GetSel($argumentsEdit)
			Local $prefix=""
			
			If $nMsg==$bracketButton Then
				$prefix="<"				
			Else
				$prefix="</"
			EndIf
			
			_GUICtrlEdit_InsertText($argumentsEdit, $prefix, $index[0])
			_GUICtrlEdit_InsertText($argumentsEdit, ">", $index[1]+StringLen($prefix))
			
			GUICtrlSetState($argumentsEdit,$GUI_FOCUS)
			_GUICtrlEdit_SetSel($argumentsEdit, $index[1]+StringLen($prefix)+1, $index[1]+StringLen($prefix)+1)			
			
		Case $clearButton
			_GUICtrlEdit_SetText($argumentsEdit,"")		
			
		Case $combo
			Local $index=_GUICtrlEdit_GetSel($argumentsEdit)
			Local $string=GUICtrlRead($combo)
			
			_GUICtrlEdit_InsertText($argumentsEdit, $string, $index[0])
			TrayTip($index[0],$index[0]+StringLen($string),30)
			GUICtrlSetState($argumentsEdit,$GUI_FOCUS)
			_GUICtrlEdit_SetSel($argumentsEdit, $index[0], $index[0]+StringLen($string))
		
		Case $OKButton
			GUISetState(@SW_HIDE,$argumentsPrompt)
			_argumentsPromptProcessCheckbox($doNotShowAgainCheckbox)
			Return GUICtrlRead($argumentsEdit)
		
		Case $cancelButton
			GUISetState(@SW_HIDE,$argumentsPrompt)
			_argumentsPromptProcessCheckbox($doNotShowAgainCheckbox)
			Return ""
			
		EndSwitch
		
		Sleep(50)
		
	WEnd

EndFunc

Func _argumentsPromptProcessCheckbox($checkbox)

	If GUICtrlRead($checkbox)==1 Then 
		_setBehaviour("promptIfNoArguments",0)
	Else
		_setBehaviour("promptIfNoArguments",1)
	EndIf

EndFunc
