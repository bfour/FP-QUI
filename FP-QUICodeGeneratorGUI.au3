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

#NoTrayIcon

#Include <Misc.au3>
#Include <GuiComboBox.au3>
#Include <GuiListView.au3>

#include <_XMLDomWrapper.au3>
#include <_fpqui.au3>
#include <_ini.au3>

Global $notifHandle = _fpqui("<text>FP-QUICodeGenerator is loading</text><ico>"&@ScriptDir&"\icon.ico</ico><untilProcessClose>"&@AutoItPID&"</untilProcessClose><bkColor>purple</bkColor>")

#include "modules\initializeDefaults.au3"
#include "modules\initializeColors.au3"
#include "modules\codeGeneratorGUI.au3"

Global $globalConfigPath=@ScriptDir&"\data\config_global.ini"
_initializeDefaults()
_initializeColors()

_XMLLoadXML("<xml></xml>", "", -1, False) ;initialize xml-code, note that we use "<xml> wrappers that do not appear in the code string"
Global $code = "" ;stores the xml-code-string
Global $buttonFontBuffer = ""
Global $statusTimer
_setStatus()
Global $debugTimer = TimerInit()
Global $debug = 1

_fpquiUpdate("<delay>1000</delay>", $notifHandle)

_mainLoop()


Func _debug($string)
	If $debug==1 Then ConsoleWrite(TimerDiff($debugTimer)&" - "&$string&@LF)
EndFunc

Func _mainLoop()
	
	While 1
		
		$nMsg = GUIGetMsg()
		
		Switch $nMsg

; =====================
; === MAIN CONTROLS ===
; =====================

		Case $GUI_EVENT_CLOSE
			Exit
			
		Case $copyButton
			GUICtrlSetBkColor($codeEdit, 0x000000)
			GUICtrlSetColor($codeEdit, 0xFFFFFF)
			Sleep(30)
			ClipPut($code)
			GUICtrlSetBkColor($codeEdit, 0xFFFFFF)
			GUICtrlSetColor($codeEdit, 0x000000)
			_setStatus("Code copied to clipboard.", "", "green")
			
		Case $deletePreviewButton
			_fpquiDelete($notifHandle)
			
		Case $previewButton
			If $code<>"" Then 
				$notifHandle = _fpqui($code, $notifHandle)
			Else
				_setStatus("There is no code yet. I cannot create a QUI.", "", "yellow")
			EndIf
			

; ===============
; === VISUALS ===
; ===============

;     TEXT

		Case $textInput
			_setOption("/xml/text", GUICtrlRead($textInput))
			_update()
		
		Case $textFontButton
			Local $font = _ChooseFont()
			If $font <> -1 And IsArray($font) Then
				
				_setOption("/xml/font", $font[2])
				_setOption("/xml/fontSize", $font[3])
				_setOption("/xml/textColor", $font[7])
				_update()
				
			EndIf
			
		Case $textFontDefaultButton
			_deleteOption("/xml/font")
			_deleteOption("/xml/fontSize")
			_deleteOption("/xml/textColor")
			_update()

;     ICON

		Case $iconInput
			_setOption("/xml/ico", GUICtrlRead($iconInput))
			_update()
			
		Case $iconBrowseButton
			Local $iconPath = FileOpenDialog(@ScriptName, @MyDocumentsDir, "icon (*.ico)", 3)
			
			If Not @error Then
				GUICtrlSetData($iconInput, $iconPath)
				_setOption("/xml/ico", $iconPath)
				_update()
			EndIf
			
		Case $iconDefaultButton
			GUICtrlSetData($iconInput, "")
			_deleteOption("/xml/ico")
			_update()

;     AVI

		Case $AVIInput
			_setOption("/xml/avi", GUICtrlRead($AVIInput))
			_update()
			
		Case $AVIBrowseButton
			Local $AVIPath = FileOpenDialog(@ScriptName, @MyDocumentsDir, "AVI (*.avi)", 3)
			
			If Not @error Then
				GUICtrlSetData($AVIInput, $AVIPath)
				_setOption("/xml/avi", $AVIPath)
				_update()
			EndIf
			
		Case $AVIDefaultButton
			GUICtrlSetData($AVIInput, "")
			_deleteOption("/xml/avi")
			_update()

;     BKCOLOR

		Case $bkColorCombo
			_setOption("/xml/bkColor", GUICtrlRead($bkColorCombo))
			_update()
			
		Case $bkColorSelectButton
			Local $color = _ChooseColor(2, 0x98C9FA, 2, $codeGeneratorGUI)
			If $color <> -1 Then
				_GUICtrlComboBox_SetEditText($bkColorCombo, $color)
				_setOption("/xml/bkColor", $color)
				_update()
			EndIf
			
		Case $bkColorDefaultButton
			_GUICtrlComboBox_SetEditText($bkColorCombo, "")
			_deleteOption("/xml/bkColor")
			_update()

;     TRANS

		Case $transInput
			_setOption("/xml/trans", GUICtrlRead($transInput))
			_update()
		
		Case $transPlusButton, $transMinusButton
			Local $currentTrans = _XMLGetValue("/xml/trans")
			Local $newTrans
			
			If IsArray($currentTrans) Then
				If $nMsg == $transPlusButton Then
					$newTrans = $currentTrans[1] + 10
				Else
					$newTrans = $currentTrans[1] - 10
				EndIf
			Else
				If $nMsg == $transPlusButton Then
					$newTrans = $defaultTrans + 10
				Else
					$newTrans = $defaultTrans - 10
				EndIf
			EndIf
			
			If $newTrans > 255 Then 
				$newTrans = 255
			ElseIf $newTrans < 0 Then
				$newTrans = 0
			EndIf
			
			_setOption("/xml/trans", $newTrans)
			GUICtrlSetData($transInput, $newTrans)
			_update()
			
		Case $transDefaultButton
			GUICtrlSetData($transInput, "")
			_deleteOption("/xml/trans")
			_update()

;     WIDTH

		Case $widthInput
			_setOption("/xml/width", GUICtrlRead($widthInput))
			_update()

		Case $widthDefaultButton
			GUICtrlSetData($widthInput, "")
			_deleteOption("/xml/width")
			_update()
		
;     HEIGHT

		Case $heightInput
			_setOption("/xml/height", GUICtrlRead($heightInput))
			_update()

		Case $heightDefaultButton
			GUICtrlSetData($heightInput, "")
			_deleteOption("/xml/height")
			_update()

;     X

		Case $xInput
			_setOption("/xml/x", GUICtrlRead($xInput))
			_update()

		Case $xDefaultButton
			GUICtrlSetData($xInput, "")
			_deleteOption("/xml/x")
			_update()

;     Y

		Case $yInput
			_setOption("/xml/y", GUICtrlRead($yInput))
			_update()

		Case $yDefaultButton
			GUICtrlSetData($yInput, "")
			_deleteOption("/xml/y")
			_update()
			
;     BUTTON

		Case $buttonAddButton
			_resetButtonSettings()
			_showButtonControls()
		
		Case $buttonFontButton
			If Not IsArray($buttonFontBuffer) Then
				$buttonFontBuffer = _ChooseFont($defaultFont, $defaultFontSize, 0, 0, False, False, False, $codeGeneratorGUI)
			Else
				$buttonFontBuffer = _ChooseFont($buttonFontBuffer[2], $buttonFontBuffer[3], $buttonFontBuffer[5], 0, False, False, False, $codeGeneratorGUI)
			EndIf
	
		Case $buttonFontDefaultButton
			$buttonFontBuffer = ""
			_setStatus("Button font reset to default.", "", "green")
			
		Case $buttonBrowseButton
			Local $commandPath = FileOpenDialog(@ScriptName, @MyDocumentsDir, "all (*.*)", 3)
			
			If Not @error Then GUICtrlSetData($buttonCommandInput, $commandPath)

		Case $buttonDeleteButton
			Local $selection = _GUICtrlListView_GetSelectedIndices($buttonListView, True)
			
			If $selection[0] == 0 Then
				_setStatus("Please select a button from the list first.", "", "yellow")
			Else
				
				Local $ID = _GUICtrlListView_GetItemText($buttonListView, $selection[1], 0)
				_deleteOption("/xml/button/ID"&$ID)
				
				Local $remainingButtons = _XMLGetChildNodes("/xml/button")
				If $remainingButtons[0] == 0 Then _deleteOption("/xml/button")
				_GUICtrlListView_DeleteItem($buttonListView, $selection[1])
				_update()
				
			EndIf
			
		Case $buttonEditButton
			
			Local $selection = _GUICtrlListView_GetSelectedIndices($buttonListView, True)				
			
			If $selection[0] == 0 Then
				_setStatus("Please select a button from the list first.", "", "yellow")
			Else
				
				Local $ID = _GUICtrlListView_GetItemText($buttonListView, $selection[1], 0)
				Local $cache
				GUICtrlSetData($buttonIDLabel, $ID)
				_showButtonControls()
				
				While 1==1
					
					;label
					$cache = _XMLGetValue("/xml/button/ID"&$ID&"/label") 
					If @error Then
						_setStatus("Error: Invalid button selected.", "", "red")
						ExitLoop
					EndIf
					GUICtrlSetData($buttonTextInput, $cache[1])
					

					;cmd
					$cache = _XMLGetValue("/xml/button/ID"&$ID&"/cmd") 
					If Not @error Then
						GUICtrlSetData($buttonCommandInput, $cache[1])
					Else
						GUICtrlSetData($buttonCommandInput, "")
					EndIf
					
					
					Local $fontDefined = False
					
					;font
					$cache = _XMLGetValue("/xml/button/ID"&$ID&"/font") 
					If Not @error Then
						$fontDefined = True
						If UBound($buttonFontBuffer)<8 Then Dim $buttonFontBuffer[8]
						$buttonFontBuffer[2] = $cache[1]
					EndIf
					
					;fontSize
					$cache = _XMLGetValue("/xml/button/ID"&$ID&"/fontSize") 
					If Not @error Then
						$fontDefined = True
						If UBound($buttonFontBuffer)<8 Then Dim $buttonFontBuffer[8]
						$buttonFontBuffer[3] = $cache[1]
					EndIf
					
					;fontColor
					$cache = _XMLGetValue("/xml/button/ID"&$ID&"/textColor")
					If Not @error Then
						$fontDefined = True
						If UBound($buttonFontBuffer)<8 Then Dim $buttonFontBuffer[8]
						$buttonFontBuffer[7] = $cache[1]
					EndIf
					
					If Not $fontDefined Then $fontBuffer = ""
						
					ExitLoop
				WEnd
								
			EndIf			

		Case $buttonCancelButton
			_hideButtonControls()
			_resetButtonSettings()

		Case $buttonSaveButton
			
			Local $ID = GUICtrlRead($buttonIDLabel)
			Local $text = GUICtrlRead($buttonTextInput)
			Local $cmd = GUICtrlRead($buttonCommandInput)
			Local $editMode = False

			While 1==1
			
				If $ID = "new" Then
					
					$ID = 1
					Local $currentButtons = _XMLGetChildNodes("/xml/button")

					If Not @error Then
						;go through current IDs and find the next one that is not yet in use
						Local $cache = 0
						For $i=1 To UBound($currentButtons)-1
							$cache = StringReplace($currentButtons[$i], "ID", "")
							If $cache > $ID Then $ID = $cache
						Next
						$ID += 1
					EndIf
				
				ElseIf Number($ID)>0 Then
				
					$editMode = True
					
				Else
				
					_setStatus("Error: Invalid button-ID. This button cannot be saved.", "", "red")
					_resetButtonSettings()
					_hideButtonControls()
					ExitLoop

				EndIf

				If $text<>"" Then
					
;~ 					If Not IsArray($currentButtons) Then _XMLCreateRootChild("button")
;~ 					If Not $editMode Then _XMLCreateChildNode("/xml/button", "ID"&$ID)
					
					Local $listViewItemString = $ID&"|"&$text&"|"&$cmd&"|||"
					
					_setOption("/xml/button/ID"&$ID&"/label", $text)
					_setOption("/xml/button/ID"&$ID&"/cmd", $cmd)
					
					If IsArray($buttonFontBuffer) Then
						_setOption("/xml/button/ID"&$ID&"/font", $buttonFontBuffer[2])
						_setOption("/xml/button/ID"&$ID&"/fontSize", $buttonFontBuffer[3])
						_setOption("/xml/button/ID"&$ID&"/textColor", $buttonFontBuffer[7])
						$listViewItemString = StringReplace($listViewItemString, "|||", "")
						$listViewItemString &= "|" & $buttonFontBuffer[2] & "|"
						$listViewItemString &= $buttonFontBuffer[3] & "|"
						$listViewItemString &= $buttonFontBuffer[7]
					Else
						_setOption("/xml/button/ID"&$ID&"/font", "")
						_setOption("/xml/button/ID"&$ID&"/fontSize", "")
						_setOption("/xml/button/ID"&$ID&"/textColor", "")						
					EndIf
					
					If $editMode Then
						
						;determine listview index
						Local $index = -1
						For $i=0 To _GUICtrlListView_GetItemCount($buttonListView)-1
							If _GUICtrlListView_GetItemText($buttonListView, $i, 0) == $ID Then $index = $i
						Next
						
						Local $listViewItemData = StringSplit($listViewItemString, "|", 3)
						
						For $i=0 To UBound($listViewItemData)-1
							_GUICtrlListView_SetItemText($buttonListView, $index, $listViewItemData[$i], $i)
						Next
						
					Else
						GUICtrlCreateListViewItem($listViewItemString, $buttonListView)
					EndIf
					
					_update()
					
				Else
					_setStatus("The button's label must not be empty.", "", "yellow")
				EndIf
			
			ExitLoop
			WEnd

; =============
; === AUDIO ===
; =============		

;     TEXT TO SPEECH

		Case $talkStringInput
			_setOption("/xml/talk/string", GUICtrlRead($talkStringInput))
			_update()
			
		Case $talkTextButton
			_setOption("/xml/talk/string", "%text%")
			GUICtrlSetData($talkStringInput, "%text%")
			_update()
			
		Case $talkRepeatInput
			_setOption("/xml/talk/repeat", GUICtrlRead($talkRepeatInput))
			_update()			
			
		Case $talkRepeatDefaultButton
			_setOption("/xml/talk/repeat", "")
			GUICtrlSetData($talkRepeatInput, "")
			_update()			
			
		Case $talkPauseInput
			_setOption("/xml/talk/pause", GUICtrlRead($talkPauseInput))
			_update()			
			
		Case $talkPauseDefaultButton
			_setOption("/xml/talk/pause", "")
			GUICtrlSetData($talkPauseInput, "")
			_update()
			
		Case $talkShakeCheckbox
			If GUICtrlRead($talkShakeCheckbox)==1 Then
				_setOption("/xml/talk/shake", 1)
				_update()
			Else
				_setOption("/xml/talk/shake", "")
				_update()
			EndIf

;     SOUND

		Case $audioInput
			_setOption("/xml/audio/path", GUICtrlRead($audioInput))
			_update()
			
		Case $audioBrowseButton
			Local $audioPath = FileOpenDialog(@ScriptName, @MyDocumentsDir, "WAV (*.wav)|MP3 (*.mp3)", 3)
			
			If Not @error Then
				GUICtrlSetData($audioInput, $audioPath)
				_setOption("/xml/audio/path", $audioPath)
				_update()
			EndIf
			
		Case $audioRepeatInput
			_setOption("/xml/audio/repeat", GUICtrlRead($audioRepeatInput))
			_update()			
			
		Case $audioRepeatDefaultButton
			_setOption("/xml/audio/repeat", "")
			GUICtrlSetData($audioRepeatInput, "")
			_update()			
			
		Case $audioPauseInput
			_setOption("/xml/audio/pause", GUICtrlRead($audioPauseInput))
			_update()			
			
		Case $audioPauseDefaultButton
			_setOption("/xml/audio/pause", "")
			GUICtrlSetData($audioPauseInput, "")
			_update()
			
		Case $audioShakeCheckbox
			If GUICtrlRead($audioShakeCheckbox)==1 Then
				_setOption("/xml/audio/shake", 1)
				_update()
			Else
				_setOption("/xml/audio/shake", "")
				_update()
			EndIf
			
		Case $audioMaxVolCheckBox
			If GUICtrlRead($audioMaxVolCheckBox)==1 Then
				_setOption("/xml/audio/maxVol", 1)
				_update()
			Else
				_setOption("/xml/audio/maxVol", "")
				_update()
			EndIf

		Case $audioOverwriteMuteCheckbox
			If GUICtrlRead($audioOverwriteMuteCheckbox)==1 Then
				_setOption("/xml/audio/overwriteMute", 1)
				_update()
			Else
				_setOption("/xml/audio/overwriteMute", "")
				_update()
			EndIf			

;     ONBOARD BEEP

		Case $beepInput
			_setOption("/xml/beep/string", GUICtrlRead($beepInput))
			_update()
			
		Case $beepHelpButton
;TODO: implement
_setStatus("Sorry, this is not yet implemented.", "", "blue")
			
		Case $beepRepeatInput
			_setOption("/xml/beep/repeat", GUICtrlRead($beepRepeatInput))
			_update()			
			
		Case $beepRepeatDefaultButton
			_setOption("/xml/beep/repeat", "")
			GUICtrlSetData($beepRepeatInput, "")
			_update()			
			
		Case $beepPauseInput
			_setOption("/xml/beep/pause", GUICtrlRead($beepPauseInput))
			_update()			
			
		Case $beepPauseDefaultButton
			_setOption("/xml/beep/pause", "")
			GUICtrlSetData($beepPauseInput, "")
			_update()
			
		Case $beepShakeCheckbox
			If GUICtrlRead($beepShakeCheckbox)==1 Then
				_setOption("/xml/beep/shake", 1)
				_update()
			Else
				_setOption("/xml/beep/shake", "")
				_update()
			EndIf

; =================
; === BEHAVIOUR ===
; =================

;     UNTIL

		Case $delayInput
			_setOption("/xml/delay", GUICtrlRead($delayInput))
			_update()
			
		Case $delayDefaultButton
			_setOption("/xml/delay", "")
			GUICtrlSetData($delayInput, "")
			_update()			

		Case $untilProcessExistsInput
			_setOption("/xml/untilProcessExists", GUICtrlRead($untilProcessExistsInput))
			_update()
			
		Case $untilProcessExistsDefaultButton
			_setOption("/xml/untilProcessExists", "")
			GUICtrlSetData($untilProcessExistsInput, "")
			_update()			
			
		Case $untilProcessCloseInput
			_setOption("/xml/untilProcessClose", GUICtrlRead($untilProcessCloseInput))
			_update()
			
		Case $untilProcessCloseDefaultButton
			_setOption("/xml/untilProcessClose", "")
			GUICtrlSetData($untilProcessCloseInput, "")
			_update()			
			
		Case $untilClickPrimRadio
			_setOption("/xml/untilClick/prim", 1)
			_setOption("/xml/untilClick/sec", "")
			_setOption("/xml/untilClick/any", "")
			_update()
			
		Case $untilClickSecRadio
			_setOption("/xml/untilClick/prim", "")
			_setOption("/xml/untilClick/sec", 1)
			_setOption("/xml/untilClick/any", "")
			_update()
			
		Case $untilClickAnyRadio
			_setOption("/xml/untilClick/prim", "")
			_setOption("/xml/untilClick/sec", "")
			_setOption("/xml/untilClick/any", 1)
			_update()
			
		Case $untilClickIncludeButtonCheckbox
			If GUICtrlRead($untilClickIncludeButtonCheckbox)==1 Then
				_setOption("/xml/untilClick/includeButton", 1)
				_update()
			Else
				_setOption("/xml/talk/includeButton", "")
				_update()
			EndIf
			
		Case $untilClickDefaultButton
			_setOption("/xml/untilClick/prim", "")
			_setOption("/xml/untilClick/sec", "")
			_setOption("/xml/untilClick/any", "")
			GUICtrlSetState($untilClickPrimRadio, $GUI_UNCHECKED)
			GUICtrlSetState($untilClickSecRadio, $GUI_UNCHECKED)
			GUICtrlSetState($untilClickAnyRadio, $GUI_UNCHECKED)
			_update()

;     ONCLICK

		Case $onClickPrimInput
			_setOption("/xml/onClick/prim", GUICtrlRead($onClickPrimInput))
			_update()
			
		Case $onClickPrimDefaultButton
			_setOption("/xml/onClick/prim", "")
			GUICtrlSetData($onClickPrimInput, "")
			_update()
			
		Case $onClickSecInput
			_setOption("/xml/onClick/sec", GUICtrlRead($onClickSecInput))
			_update()
			
		Case $onClickSecDefaultButton
			_setOption("/xml/onClick/sec", "")
			GUICtrlSetData($onClickSecInput, "")
			_update()
			
		Case $onClickAnyInput
			_setOption("/xml/onClick/any", GUICtrlRead($onClickAnyInput))
			_update()
			
		Case $onClickAnyDefaultButton
			_setOption("/xml/onClick/any", "")
			GUICtrlSetData($onClickAnyInput, "")
			_update()
			
		Case $onClickIncludeButtonCheckBox
			If GUICtrlRead($onClickIncludeButtonCheckBox)==1 Then
				_setOption("/xml/onClick/includeButton", 1)
				_update()
			Else
				_setOption("/xml/onClick/includeButton", "")
				_update()
			EndIf
			
			
;     RUN

		Case $runInput
			
			Local $cmd = GUICtrlRead($runInput)
			
			If GUICtrlRead($runCommandCheckbox)==1 Then
				_setOption("/xml/run", $cmd)
				_setOption("/xml/run/shellOpen", "")
				_setOption("/xml/run/internal", "")
			ElseIf GUICtrlRead($runShellOpenCheckbox)==1 Then
				_setOption("/xml/run", "")
				_setOption("/xml/run/shellOpen", $cmd)
				_setOption("/xml/run/internal", "")
			ElseIf GUICtrlRead($runInternalCheckbox)==1 Then
				_setOption("/xml/run", "")
				_setOption("/xml/run/shellOpen", "")
				_setOption("/xml/run/internal", $cmd)
			Else
				_setStatus("Error: Invalid run-mode, please select one.", "", "red")
			EndIf
			
			_update()
			
		Case $runBrowseButton
			
			Local $path = FileOpenDialog(@ScriptName, @MyDocumentsDir, "any (*.*)", 3)
			
			If Not @error Then
				GUICtrlSetData($runInput, $path)
				
				If GUICtrlRead($runCommandCheckbox)==1 Then
					_setOption("/xml/run", $path)
					_setOption("/xml/run/shellOpen", "")
					_setOption("/xml/run/internal", "")
				ElseIf GUICtrlRead($runShellOpenCheckbox)==1 Then
					_setOption("/xml/run", "")
					_setOption("/xml/run/shellOpen", $path)
					_setOption("/xml/run/internal", "")
				ElseIf GUICtrlRead($runInternalCheckbox)==1 Then
					_setOption("/xml/run", "")
					_setOption("/xml/run/shellOpen", "")
					_setOption("/xml/run/internal", $path)
				Else
					_setStatus("Error: Invalid run-mode, please select one.", "", "red")
				EndIf				
				
				_update()
			EndIf
			
		Case $runRepeatInput
			_setOption("/xml/run/repeat", GUICtrlRead($runRepeatInput))
			_update()
			
		Case $runRepeatDefaultButton
			_setOption("/xml/run/repeat", "")
			GUICtrlSetData($runRepeatInput, "")
			_update()
			
		Case $runPauseInput
			_setOption("/xml/run/pause", GUICtrlRead($runPauseInput))
			_update()
			
		Case $runPauseDefaultButton
			_setOption("/xml/run/pause", "")
			GUICtrlSetData($runPauseInput, "")
			_update()
			
		Case $runCommandCheckbox
			Local $cmd = GUICtrlRead($runInput)

			_setOption("/xml/run", $cmd)
			_setOption("/xml/run/shellOpen", "")
			_setOption("/xml/run/internal", "")
			
			_update()
		
		Case $runShellOpenCheckbox
			Local $cmd = GUICtrlRead($runInput)

			_setOption("/xml/run", "")
			_setOption("/xml/run/shellOpen", $cmd)
			_setOption("/xml/run/internal", "")
			
			_update()
			
		Case $runInternalCheckbox
			Local $cmd = GUICtrlRead($runInput)

			_setOption("/xml/run", "")
			_setOption("/xml/run/shellOpen", "")
			_setOption("/xml/run/internal", $cmd)
			
			_update()
			

;     MISC

		Case $noDoubleCheckbox
			If GUICtrlRead($noDoubleCheckbox)==1 Then
				_setOption("/xml/noDouble", 1)
				_update()
			Else
				_setOption("/xml/noDouble", "")
				_update()
			EndIf

		Case $focusCheckbox
			If GUICtrlRead($focusCheckbox)==1 Then
				_setOption("/xml/focus", 1)
				_update()
			Else
				_setOption("/xml/focus", "")
				_update()
			EndIf
			
		Case $replaceVarCheckbox
			If GUICtrlRead($replaceVarCheckbox)==1 Then
				_setOption("/xml/replaceVar", 1)
				_update()
			Else
				_setOption("/xml/replaceVar", "")
				_update()
			EndIf

		EndSwitch

		;reset status after 10 seconds
		If TimerDiff($statusTimer) > 10000 Then _setStatus()

		Sleep(10)
		
	WEnd
	
EndFunc

;~ Func _setOption($location, $data)
;~ 	
;~ 	If $data == "" Then
;~ 		
;~ 		;delete
;~ 		_deleteOption($location)
;~ 		
;~ 	Else
;~ 	
;~ 		;update
;~ 		_XMLUpdateField($location, $data)
;~ 		
;~ 		;create new if not yet exists
;~ 		If @error Then
;~ 			
;~ 			Local $name = StringSplit($location, "/", 3)
;~ 			$name = $name[UBound($name)-1]
;~ 			
;~ 			$location = StringTrimRight($location, StringLen($name)+1)
;~ 			
;~ 			_XMLCreateChildNode($location, $name, $data)
;~ 			
;~ 		EndIf
;~ 		
;~ 	EndIf
;~ 	
;~ EndFunc


Func _setOption($location, $data)
	
	If $data == "" Then
_debug("_setOption/delete "&$location)		
		;delete
		_deleteOption($location)
		
	Else

_debug("_setOption/set, $location="&$location)		

		Local $name = StringSplit($location, "/", 3)
		Local $currentRoot = "/"&$name[1]
		Local $currentTag = $name[2]
		
		;start at root+1 level and check for each child if exists, create if needed
		For $i = 2 To UBound($name)-1
_debug("_setOption/set loop")		

			$currentTag = $name[$i]
_debug("_setOption/set loop, $currentTag="&$currentTag)	
			
			Local $children = _XMLGetChildren($currentRoot)
_debug("_setOption/set loop, $children="&$children&" ($currentRoot="&$currentRoot&")")	
			
			;check if the current tag exists
			If _ArraySearch($children, $currentTag) > 0 Then
				;it exists, adjust root and continue
				$currentRoot = $currentRoot&"/"&$currentTag
_debug("_setOption/set loop, found $currentTag in children-array, set $currentRoot to "&$currentRoot)	
				ContinueLoop
			Else
				;the current tag does not exist --> we need to create it and all following
				_XMLCreateChildNode($currentRoot, $currentTag)
_debug("_setOption/set loop, did not find $currentTag in children-array, created "&$currentRoot&"/"&$currentTag)
				$currentRoot = $currentRoot&"/"&$currentTag
				ContinueLoop
			EndIf
			
		Next
		
;~ MsgBox(1,"",$currentRoot)		
		;the structure should now be initialized, set data
		_XMLUpdateField($currentRoot, $data)
_debug("_setOption/updated "&$currentRoot&" to "&$data)	


	EndIf
	
EndFunc

Func _getOptions($location)
	
	Local $return = _XMLGetValue($location)
	Return SetError(@error, @extended, $return[1])
	
EndFunc

Func _deleteOption($xPath)
	
	Local $return = _XMLDeleteNode($xPath)
	Return SetError(@error, @extended, $return)
	
EndFunc

Func _update()
	
	$code = _getCodeString()
	GUICtrlSetData($codeEdit, $code)
	$notifHandle = _fpqui($code, $notifHandle)
	
EndFunc

Func _getCodeString()
	
	_XMLSaveDoc(@scriptdir&"\test.xml")
	Local $data = FileRead(@scriptdir&"\test.xml")
	$data = StringReplace($data,"<xml>","")
	$data = StringReplace($data,"</xml>","")
	$data = StringReplace($data,@CRLF,"")
	
	Return $data
	
EndFunc


Func _setStatus($string=Default, $color=Default, $bkColor=Default)
	
	If $string<>Default Or $color<>Default Or $bkColor<>Default Then
		;reset timer if option was set
		$statusTimer = TimerInit()
	Else
		;else, advance timer by one hour from now (so there will be no reset for one hour unless an option is set)
		$statusTimer = TimerInit() + 3600000
	EndIf
		
	If $string == Default Then $string = ""
	
	;padding
	$string = " "&$string
	
	Switch $color

		Case "blue"
			$color=$colorsBlue
		Case "green"
			$color=$colorsGreen
		Case "red"
			$color=$colorsRed
		Case "orange"
			$color=$colorsOrange
		Case "white"
			$color=$colorsWhite
		Case "black"
			$color=$colorsBlack
		Case "gray"
			$color=$colorsGray
		Case "purple"
			$color=$colorsPurple
		Case "yellow"
			$color=$colorsYellow

	EndSwitch
	
	Switch $bkColor

		Case "blue"
			$bkColor=$colorsBlue
		Case "green"
			$bkColor=$colorsGreen
		Case "red"
			$bkColor=$colorsRed
		Case "orange"
			$bkColor=$colorsOrange
		Case "white"
			$bkColor=$colorsWhite
		Case "black"
			$bkColor=$colorsBlack
		Case "gray"
			$bkColor=$colorsGray
		Case "purple"
			$bkColor=$colorsPurple
		Case "yellow"
			$bkColor=$colorsYellow

	EndSwitch	
		
	GUICtrlSetData($statusLabel, $string)
	GUICtrlSetColor($statusLabel, $color)
	GUICtrlSetBkColor($statusLabel, $bkColor)
	
EndFunc


Func _showButtonControls()
	
	GUICtrlSetState($buttonTextInput, $GUI_SHOW)
	GUICtrlSetState($buttonFontButton, $GUI_SHOW)
	GUICtrlSetState($buttonFontDefaultButton, $GUI_SHOW)
	GUICtrlSetState($buttonCommandInput, $GUI_SHOW)
	GUICtrlSetState($buttonBrowseButton, $GUI_SHOW)
	GUICtrlSetState($buttonEditLabel, $GUI_SHOW)
	GUICtrlSetState($buttonIDLabel, $GUI_SHOW)
	GUICtrlSetState($buttonCancelButton, $GUI_SHOW)
	GUICtrlSetState($buttonSaveButton, $GUI_SHOW)
	
EndFunc

Func _hideButtonControls()

	GUICtrlSetState($buttonTextInput, $GUI_HIDE)
	GUICtrlSetState($buttonFontButton, $GUI_HIDE)
	GUICtrlSetState($buttonFontDefaultButton, $GUI_HIDE)
	GUICtrlSetState($buttonCommandInput, $GUI_HIDE)
	GUICtrlSetState($buttonBrowseButton, $GUI_HIDE)
	GUICtrlSetState($buttonEditLabel, $GUI_HIDE)
	GUICtrlSetState($buttonIDLabel, $GUI_HIDE)
	GUICtrlSetState($buttonCancelButton, $GUI_HIDE)
	GUICtrlSetState($buttonSaveButton, $GUI_HIDE)

EndFunc

Func _resetButtonSettings()
	
	GUICtrlSetData($buttonTextInput, "")
	GUICtrlSetData($buttonCommandInput, "")
	GUICtrlSetData($buttonIDLabel, "new")
	$buttonFontBuffer = ""
	
EndFunc


Func OnAutoItExit()
	_fpquiDelete($notifHandle)
EndFunc