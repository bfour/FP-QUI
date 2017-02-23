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

#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>

Func _generateFirstStartGUI()

#Region ### START Koda GUI section ### Form=S:\sabox\grid\FP-QUI\gui\firstStartAssistant.kxf
Global $firstStartGUI = GUICreate("FP-QUIFirstStartAssistant", 532, 442, -1, -1, BitOR($WS_MINIMIZEBOX,$WS_SIZEBOX,$WS_THICKFRAME,$WS_SYSMENU,$WS_CAPTION,$WS_POPUP,$WS_POPUPWINDOW,$WS_GROUP,$WS_BORDER,$WS_CLIPSIBLINGS))
Global $autoStartCheckbox = GUICtrlCreateCheckbox("AutoStart Entry", 8, 88, 513, 17)
GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
GUICtrlSetResizing(-1, $GUI_DOCKLEFT+$GUI_DOCKRIGHT+$GUI_DOCKTOP+$GUI_DOCKHEIGHT)
Global $registerCheckbox = GUICtrlCreateCheckbox("Registry entry", 8, 176, 513, 17)
GUICtrlSetState(-1, $GUI_CHECKED)
GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
GUICtrlSetResizing(-1, $GUI_DOCKLEFT+$GUI_DOCKRIGHT+$GUI_DOCKTOP+$GUI_DOCKHEIGHT)
Global $registerEdit = GUICtrlCreateEdit("", 27, 200, 497, 185, BitOR($ES_READONLY,$ES_WANTRETURN), 0)
GUICtrlSetData(-1, StringFormat("This creates an entry in the registry that points to the location of FP-QUI. This allows applications that are designed for FP-QUI to start it on-demand. In other words, if \r\nFP-QUICore is not running and an application wants to create a QUI, it might try to \r\nstart FP-QUICore.exe, but fails if it cannot find it.\r\n\r\nYou may at any time deregister FP-QUI (remove the registry entry) using the \r\nConfigurationAssistant.\r\nYou may also set an "&Chr(34)&"Auto Register"&Chr(34)&" option, that specifies whether FP-QUICore \r\nregisters its location every time it"&Chr(39)&"s launched.\r\nIn addition, you can specify FP-QUICore to deregister itself when it is terminated by \r\nenabling the "&Chr(34)&"Auto Deregister"&Chr(34)&" option."))
GUICtrlSetResizing(-1, $GUI_DOCKLEFT+$GUI_DOCKRIGHT+$GUI_DOCKTOP)
Global $autoStartEdit = GUICtrlCreateEdit("", 27, 112, 497, 49, BitOR($ES_READONLY,$ES_WANTRETURN), 0)
GUICtrlSetData(-1, StringFormat("FP-QUICore will be started automatically when you login if this is enabled. This \r\nenhances reliability, but consumes memory and some CPU cycles. You may leave \r\nthis uncheckd, it is optional."))
GUICtrlSetResizing(-1, $GUI_DOCKLEFT+$GUI_DOCKRIGHT+$GUI_DOCKTOP)
Global $cancelButton = GUICtrlCreateButton("Cancel", 192, 400, 163, 33, 0)
GUICtrlSetResizing(-1, $GUI_DOCKRIGHT+$GUI_DOCKBOTTOM+$GUI_DOCKWIDTH+$GUI_DOCKHEIGHT)
Global $saveButton = GUICtrlCreateButton("Save", 360, 400, 163, 33, 0)
GUICtrlSetResizing(-1, $GUI_DOCKRIGHT+$GUI_DOCKBOTTOM+$GUI_DOCKWIDTH+$GUI_DOCKHEIGHT)
Global $helpButton = GUICtrlCreateButton("Help", 8, 400, 163, 33, $BS_DEFPUSHBUTTON)
GUICtrlSetResizing(-1, $GUI_DOCKLEFT+$GUI_DOCKBOTTOM+$GUI_DOCKWIDTH+$GUI_DOCKHEIGHT)
Global $Edit3 = GUICtrlCreateEdit("", 8, 8, 441, 65, BitOR($ES_READONLY,$ES_WANTRETURN), 0)
GUICtrlSetData(-1, StringFormat("This seems to be the first time you have launched FP-QUI or FP-QUICore \r\nwith a new configuration (you can have one configuration per user or \r\nmachine or use other criteria). This assistant helps you with essential \r\nsettings that might affect how FP-QUI works for you."))
GUICtrlSetResizing(-1, $GUI_DOCKLEFT+$GUI_DOCKTOP)
Global $Icon1 = GUICtrlCreateIcon(@ScriptDir&"\icon.ico", 0, 464, 16, 48, 48, BitOR($SS_NOTIFY,$WS_GROUP))
GUICtrlSetResizing(-1, $GUI_DOCKRIGHT+$GUI_DOCKTOP+$GUI_DOCKWIDTH+$GUI_DOCKHEIGHT)
#EndRegion ### END Koda GUI section ###

GUICtrlSetImage($Icon1, @ScriptDir&"\icon.ico")
GUICtrlSetData($registerEdit, "This creates an entry in the registry that points to the location of FP-QUI. This allows applications that are designed for FP-QUI to start it on-demand. In other words, if FP-QUICore is not running and an application wants to create a QUI, it might try to start FP-QUICore.exe, but fails if it cannot find it.You may at any time deregister FP-QUI (remove the registry entry) using the ConfigurationAssistant.You may also set an "&Chr(34)&"Auto Register"&Chr(34)&" option, that specifies whether FP-QUICore registers its location every time it"&Chr(39)&"s launched.In addition, you can specify FP-QUICore to deregister itself when it is terminated by enabling the "&Chr(34)&"Auto Deregister"&Chr(34)&" option.")
GUICtrlSetData($autoStartEdit, "FP-QUICore will be started automatically when you login if this is enabled. This enhances reliability, but consumes memory and some CPU cycles. You may leave this uncheckd, it is optional.")
GUICtrlSetData($Edit3, "This seems to be the first time you have launched FP-QUI or FP-QUICore with a new configuration (you can have one configuration per user or machine or use other criteria). This assistant helps you with essential settings that might affect how FP-QUI works for you.")

EndFunc

Func _showFirstStartGUI()
	GUISetState(@SW_SHOW, $firstStartGUI)
EndFunc

Func _hideFirstStartGUI()
	GUISetState(@SW_HIDE, $firstStartGUI)
EndFunc