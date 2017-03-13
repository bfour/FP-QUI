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

#include <MsgBoxConstants.au3>
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

	_hideConfigurationAssistantGUI()
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
	_fpqui("<text>new configuration applied</text><ico>@ScriptDir\icon.ico</ico><replaceVars>1</replaceVars><delay>7000</delay><button><ID1><label>reconfigure</label><cmd>"&@ScriptFullPath&"</cmd></ID1></button>", Default, 1, _
			"<coreNotRunning>tryAndReturn</coreNotRunning>")
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
			GUICtrlSetData($fontInput, "Microsoft Sans Serif")
			GUICtrlSetData($fontInput, "Arial")
		Else
			GUICtrlSetData($fontInput, "Segoe UI")
		EndIf
		GUICtrlSetData($fontSizeInput, 14)
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