#cs

	FP-QUI allows you to show popups that provide a quick user interface.
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

#Include <GuiComboBox.au3>
#Include <GuiListBox.au3>
#Include <Misc.au3>

#include <_config.au3>
#include <_path.au3>
#include <_error.au3>

#include "modules\vars.au3"
#include "modules\initializeErrorHandling.au3"
#include "modules\initializeBehaviour.au3"
#include "modules\initializeDefaults.au3"
#include "modules\initializeColors.au3"
#include "modules\setConfiguration.au3"

#include "modules\configurationAssistantGUI.au3"

_initializeErrorHandling()
_assureEnvironment()
_initializeGUI()
_showConfigurationAssistantGUI()
_mainLoop()

Func _assureEnvironment()
	
	;if config-dir does not exists, create it
	Local $configDir = _pathGetDir($globalConfigPath)
	If DirGetSize($configDir,2)==-1 Then DirCreate($configDir)
		
	;if global config is missing, create it
	If Not FileExists($configDir) Then 
		If FileInstall(".\data\config_global.ini", ".\data\config_global.ini", 0)==0 Then _error("global config is missing, tried copying, failed", $errorInteractive, $errorBroadCast, $errorLog, $errorLogDir, $errorLogFile, $errorLogMaxNumberOfLines)
	EndIf
	
EndFunc

Func _initializeGUI()
	
	GUISetState($configurationAssistantGUI, $GUI_DISABLE)
	GUICtrlSetState($cancelButton, $GUI_FOCUS)

	_initializeBehaviour()
	_initializeDefaults()
	_initializeColors()

	;configuration
	GUICtrlSetData($configPathCombo, _iniRead($globalConfigPath, "_ini", "specificPath", "@ScriptDir\data\config_@UserName_@ComputerName.ini"))
	
	
	;behaviour
;~ 	If $behaviourPromptIfNoArguments Then
;~ 		GUICtrlSetState($promptIfNoArgumentsCheckbox, $GUI_CHECKED)
;~ 	Else
;~ 		GUICtrlSetState($promptIfNoArgumentsCheckbox, $GUI_UNCHECKED)
;~ 	EndIf
	
	If $behaviourAutoRegister Then
		GUICtrlSetState($autoRegisterCheckbox, $GUI_CHECKED)
	Else
		GUICtrlSetState($autoRegisterCheckbox, $GUI_UNCHECKED)
	EndIf
	
	If $behaviourAutoDeregister Then
		GUICtrlSetState($autoDeregisterCheckbox, $GUI_CHECKED)
	Else
		GUICtrlSetState($autoDeregisterCheckbox, $GUI_UNCHECKED)
	EndIf
	
	
	;defaults
	GUICtrlSetData($fontInput, $defaultFont)
	GUICtrlSetData($fontSizeInput, $defaultFontSize)
	GUICtrlSetData($textColorInput, $defaultTextColor)
	GUICtrlSetData($minimumFontSizeInput, $defaultMinimumFontSize)
	_GUICtrlComboBox_SetEditText($bkColorCombo, $defaultBkColor)
	GUICtrlSetData($heightInput, $defaultHeight)
	GUICtrlSetData($transInput, $defaultTrans)
	
	If $behaviourFadeOut==1 Then
		GUICtrlSetState($fadeOutCheckbox, $GUI_CHECKED)
	Else
		GUICtrlSetState($fadeOutCheckbox, $GUI_UNCHECKED)
	EndIf	
	
	;colors
;~ 	_GUICtrlListBox_ResetContent($colorsListBox)
;~ 	
;~ 	Local $counter = 0
;~ 	For $color In $colorsAvailable
;~ 		
;~ 		_GUICtrlListBox_AddString($colorsListBox, $color)
;~ 		$varName = "colors" & StringUpper(StringLeft($color,1)) & StringTrimLeft($color,1)
;~ 		_GUICtrlListBox_SetItemData($colorsListBox, $counter, Eval($varName))
;~ 		
;~ 		$counter+=1
;~ 		
;~ 	Next
;~ 	GUICtrlSetData($colorsInput, "")
	
EndFunc

Func _save()
	
	;configuration
	_iniWrite($globalConfigPath, "_ini", "specificPath", GUICtrlRead($configPathCombo))
	
	
	;behaviour
;~ 	If GUICtrlRead($promptIfNoArgumentsCheckbox) == 1 Then
;~ 		_setConfiguration("behaviour", "promptIfNoArguments", 1)
;~ 	Else
;~ 		_setConfiguration("behaviour", "promptIfNoArguments", 0)
;~ 	EndIf

	If GUICtrlRead($autoRegisterCheckbox) == 1 Then
		_setConfiguration("behaviour", "autoRegister", 1)
	Else
		_setConfiguration("behaviour", "autoRegister", 0)
	EndIf
	
	If GUICtrlRead($autoDeregisterCheckbox) == 1 Then
		_setConfiguration("behaviour", "autoDeregister", 1)
	Else
		_setConfiguration("behaviour", "autoDeregister", 0)
	EndIf
	
	
	;defaults
	_setConfiguration("defaults", "font", GUICtrlRead($fontInput))
	_setConfiguration("defaults", "fontSize", GUICtrlRead($fontSizeInput))
	_setConfiguration("defaults", "textColor", GUICtrlRead($textColorInput))
	_setConfiguration("defaults", "minimumFontSize", GUICtrlRead($minimumFontSizeInput))
	_setConfiguration("defaults", "bkColor", GUICtrlRead($bkColorCombo))
	_setConfiguration("defaults", "height", GUICtrlRead($heightInput))
	_setConfiguration("defaults", "trans", GUICtrlRead($transInput))
	
	If GUICtrlRead($fadeOutCheckbox) == 1 Then
		_setConfiguration("behaviour", "fadeOut", 1)
	Else
		_setConfiguration("behaviour", "fadeOut", 0)
	EndIf	

	
	;colors
;~ 	Local $text
;~ 	Local $color
;~ 	For $i=0 To _GUICtrlListBox_GetCount($colorsListBox)
;~ 		$colorName = _GUICtrlListBox_GetText($colorsListBox, $i)
;~ 		$colorValue = _GUICtrlListBox_GetItemData($colorsListBox, $i)
;~ 		_setConfiguration("colors", $colorName, $colorValue)
;~ 	Next
	
EndFunc

Func _mainLoop()
	
	While 1
	
	$nMsg = GUIGetMsg()
	
	Switch $nMsg

	Case $GUI_EVENT_CLOSE
		Exit		

	Case $cancelButton
		Exit

	Case $helpButton
		ShellExecute($FPQUI_HELPPATH, "", "", "open")
		If @error Then _error("Could not open help file at "&$FPQUI_HELPPATH, 1, $errorBroadCast, $errorLog, $errorLogDir, $errorLogFile, $errorLogMaxNumberOfLines, 1)		

	Case $configPathBrowseButton
		Local $path = FileOpenDialog(@ScriptName, @ScriptDir, "ini-files (*.ini)|any (*.*)")
		
		If Not @error Then
			_GUICtrlComboBox_SetEditText($configPathCombo, $path)
		EndIf

	Case $configPathDefaultButton
		_GUICtrlComboBox_SetEditText($configPathCombo, "@ScriptDir\data\config_@UserName_@ComputerName.ini")

	Case $Label3
		If GUICtrlRead($autoRegisterCheckbox) == 1 Then
			GUICtrlSetState($autoRegisterCheckbox, $GUI_UNCHECKED)
		Else
			GUICtrlSetState($autoRegisterCheckbox, $GUI_CHECKED)
		EndIf

	Case $Label5
;~ 		If GUICtrlRead($promptIfNoArgumentsCheckbox) == 1 Then
;~ 			GUICtrlSetState($promptIfNoArgumentsCheckbox, $GUI_UNCHECKED)
;~ 		Else
;~ 			GUICtrlSetState($promptIfNoArgumentsCheckbox, $GUI_CHECKED)
;~ 		EndIf		

	Case $Label6
		If GUICtrlRead($autoDeregisterCheckbox) == 1 Then
			GUICtrlSetState($autoDeregisterCheckbox, $GUI_UNCHECKED)
		Else
			GUICtrlSetState($autoDeregisterCheckbox, $GUI_CHECKED)
		EndIf
		
	Case $Label7
		If GUICtrlRead($autoRegisterCheckbox) == 1 Then
			GUICtrlSetState($autoRegisterCheckbox, $GUI_UNCHECKED)
		Else
			GUICtrlSetState($autoRegisterCheckbox, $GUI_CHECKED)
		EndIf		

	Case $minimumFontSizeDefaultButton
		GUICtrlSetData($minimumFontSizeInput, 12)

	Case $selectFontButton
		Local $font = _ChooseFont(GUICtrlRead($fontInput), GUICtrlRead($fontSizeInput))
		If $font <> -1 And IsArray($font) Then
			GUICtrlSetData($fontInput, $font[2])
			GUICtrlSetData($fontSizeInput, $font[3])
			GUICtrlSetData($textColorInput, $font[7])
		EndIf

	Case $fontPropertiesDefaultButton
		GUICtrlSetData($fontInput, "Segoe UI")
		GUICtrlSetData($fontSizeInput, 16)
		GUICtrlSetData($textColorInput, Default)

	Case $heightDefaultButton
		GUICtrlSetData($heightInput, 58)

	Case $bkColorDefaultButton
		_GUICtrlComboBox_SetEditText($bkColorCombo, "blue")

	Case $transDefaultButton
		GUICtrlSetData($transInput, 210)

	Case $resetAllButton
		_initializeGUI()

	Case $saveButton
		_save()
		Exit

;~ 	Case $colorsListBox
;~ 		Local $selection = _GUICtrlListBox_GetCurSel($colorsListBox)
;~ 		
;~ 		If $selection<>-1 Then
;~ 			Local $colorValue = _GUICtrlListBox_GetItemData($colorsListBox, $selection)
;~ 			GUICtrlSetData($colorsInput, $colorValue)
;~ 		EndIf

;~ 	Case $colorsInput
		

;~ 	Case $colorsDefaultButton
		

;~ 	Case $colorsSelectButton
		

;~ 	Case $colorsSaveButton
		
		
	EndSwitch
	
	Sleep(20)
		
	WEnd

EndFunc