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

#Include <GuiComboBox.au3>
#Include <GuiListBox.au3>
#Include <Misc.au3>

#include <_config.au3>
#include <_path.au3>
#include <_error.au3>
#include <_fpqui.au3>

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

	Global $currentFontColorSelection = Default

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
	If $behaviourShowMenuOnFirstStart == 1 Then
		GUICtrlSetState($showMenuOnFirstStartCheckbox, $GUI_CHECKED)
	Else
		GUICtrlSetState($showMenuOnFirstStartCheckbox, $GUI_UNCHECKED)
	EndIf

	If $behaviourAutoRegister == 1 Then
		GUICtrlSetState($autoRegisterCheckbox, $GUI_CHECKED)
	Else
		GUICtrlSetState($autoRegisterCheckbox, $GUI_UNCHECKED)
	EndIf

	If $behaviourAutoDeregister == 1 Then
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
	If GUICtrlRead($showMenuOnFirstStartCheckbox) == 1 Then
		_setConfiguration("behaviour", "showMenuOnFirstStart", 1)
	Else
		_setConfiguration("behaviour", "showMenuOnFirstStart", 0)
	EndIf

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
	_setConfiguration("defaults", "font", 				GUICtrlRead($fontInput))
	_setConfiguration("defaults", "fontSize", 			GUICtrlRead($fontSizeInput))
	_setConfiguration("defaults", "textColor", 			GUICtrlRead($textColorInput))
	_setConfiguration("defaults", "minimumFontSize", 	GUICtrlRead($minimumFontSizeInput))
	_setConfiguration("defaults", "bkColor", 			GUICtrlRead($bkColorCombo))
	_setConfiguration("defaults", "height", 			GUICtrlRead($heightInput))
	_setConfiguration("defaults", "trans", 				GUICtrlRead($transInput))

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

	_hideConfigurationAssistantGUI()
;~ 	_promptForRestart()
	_reinitCore()
	_showTestQUI()

EndFunc

Func _reinitCore()

	Local $return

	$return = _fpqui("<system><reinitDefaults>1</reinitDefaults><reinitBehaviour>1</reinitBehaviour><reinitColors>1</reinitColors></system>", Default, 0, _
			"<coreNotRunning>return</coreNotRunning><requestFailed>return</requestFailed>"& _
			"<sendMaxRetries>8</sendMaxRetries><sendRetryPause>100</sendRetryPause>"& _
			"<receiveMaxRetries>0</receiveMaxRetries><receiveRetryPause>0</receiveRetryPause>", _
			Default, Default)

	; we're awaiting no response --> errCode 4
	Local $error = @error
	If $error>=8 Then _error('Failed to reinitialize FP-QUICore. Please restart FP-QUICore manually. error='&$error, 1, $errorBroadCast, $errorLog, $errorLogDir, $errorLogFile, $errorLogMaxNumberOfLines, 1)

EndFunc

Func _showTestQUI()

	Local $return

	$return = _fpqui("<text>new configuration applied</text><ico>@ScriptDir\icon.ico</ico><replaceVars>1</replaceVars><delay>5000</delay><button><ID1><label>reconfigure</label><cmd>"&@ScriptFullPath&"</cmd></ID1></button>", Default, 1, _
			"<coreNotRunning>tryAndReturn</coreNotRunning>")

;~ 	If @error Then _error('Failed to create test-QUI: @error='&@error, 1, $errorBroadCast, $errorLog, $errorLogDir, $errorLogFile, $errorLogMaxNumberOfLines, 1)
	;TODO fix error (always returns 4 responseFailed)

EndFunc

;~ Func _promptForRestart()
;~
;~ 	If ProcessExists("FP-QUICore.exe") Then
;~
;~ 		Local $answer = MsgBox(4+32, "FP-QUIConfigurationAssistant", "New configuration has been saved to "&_iniFinalPath($globalConfigPath)&". In order for changes to take effect FP-QUICore has to be restarted. Current QUIs will be lost. Do you wish to restart FP-QUICore now?")
;~
;~ 		If $answer == 6 Then ; yes
;~
;~ 			Local $corePath = @ScriptDir&"\FP-QUICore.exe" ;TODO change to more secure method
;~
;~ 			If FileExists($corePath) == 0 Then
;~ 				_error('Failed to find FP-QUICore executable at "'&$corePath&'". Restart aborted.', 1, $errorBroadCast, $errorLog, $errorLogDir, $errorLogFile, $errorLogMaxNumberOfLines, 1)
;~ 			Else
;~ 				ProcessClose("FP-QUICore.exe")
;~ 				Run($corePath)
;~ 				If @error Then _error('Failed to start FP-QUICore. Please restart manually.', 1, $errorBroadCast, $errorLog, $errorLogDir, $errorLogFile, $errorLogMaxNumberOfLines, 1)
;~ 			EndIf
;~
;~ 		EndIf
;~
;~ 	EndIf
;~
;~ EndFunc


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
		_toggleCheckbox($autoRegisterCheckbox)

	Case $Label4
		_toggleCheckbox($showMenuOnFirstStartCheckbox)

	Case $Label6
		_toggleCheckbox($autoDeregisterCheckbox)

	Case $Label7
		If GUICtrlRead($autoRegisterCheckbox) == 1 Then
			GUICtrlSetState($autoRegisterCheckbox, $GUI_UNCHECKED)
		Else
			GUICtrlSetState($autoRegisterCheckbox, $GUI_CHECKED)
		EndIf

	Case $minimumFontSizeDefaultButton
		GUICtrlSetData($minimumFontSizeInput, 12)

	Case $selectFontButton
		Local $font = _ChooseFont(GUICtrlRead($fontInput), GUICtrlRead($fontSizeInput), $currentFontColorSelection)
		If $font <> -1 And IsArray($font) Then
			GUICtrlSetData($fontInput, $font[2])
			GUICtrlSetData($fontSizeInput, $font[3])
			GUICtrlSetData($textColorInput, $font[7])
			$currentFontColorSelection = $font[5]
		EndIf

	Case $fontPropertiesDefaultButton

		If @OSVersion == "WIN_2003" OR @OSVersion == "WIN_XP" OR @OSVersion == "WIN_2000" Then
<<<<<<< HEAD
			GUICtrlSetData($fontInput, "Microsoft Sans Serif")
=======
			GUICtrlSetData($fontInput, "Arial")
>>>>>>> remotes/TUWien/master
		Else
			GUICtrlSetData($fontInput, "Segoe UI")
		EndIf
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

Func _toggleCheckbox(ByRef $checkbox)

	If GUICtrlRead($checkbox) == 1 Then
		GUICtrlSetState($checkbox, $GUI_UNCHECKED)
	Else
		GUICtrlSetState($checkbox, $GUI_CHECKED)
	EndIf

EndFunc