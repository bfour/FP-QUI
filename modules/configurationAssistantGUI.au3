#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <GUIListBox.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>

#Region ### START Koda GUI section ### Form=E:\sabox\grid\FP-QUI\gui\configurationAssistantGUI.kxf
Global $configurationAssistantGUI = GUICreate("FP-QUIConfigurationAssistant", 858, 347, -1, -1)
GUISetBkColor(0xFFFFFF)
Global $cancelButton = GUICtrlCreateButton("Cancel", 616, 288, 115, 49, $BS_DEFPUSHBUTTON)
Global $saveButton = GUICtrlCreateButton("Save", 736, 288, 115, 49, 0)
Global $resetAllButton = GUICtrlCreateButton("Reset all to Default", 376, 288, 115, 49, $BS_MULTILINE)
Global $helpButton = GUICtrlCreateButton("Help", 496, 288, 115, 49, 0)
Global $Group1 = GUICtrlCreateGroup("Configuration", 8, 8, 561, 97)
Global $configPathCombo = GUICtrlCreateCombo("", 16, 72, 385, 25)
GUICtrlSetData(-1, "@ScriptDir\data\config_@UserName_@ComputerName.ini|@ScriptDir\data\config_@UserName.ini|@ScriptDir\data\config_@ComputerName.ini")
Global $configPathBrowseButton = GUICtrlCreateButton("Browse", 408, 72, 75, 25, 0)
Global $configPathDefaultButton = GUICtrlCreateButton("Default", 488, 72, 75, 25, 0)
Global $Label1 = GUICtrlCreateLabel("Path to configuration file (this may include variables like @Username or @MyDocumentsDir):", 16, 32, 551, 20)
Global $Label2 = GUICtrlCreateLabel("Advice: To make FP-QUI portable, you should use the default value.", 16, 48, 405, 20)
GUICtrlCreateGroup("", -99, -99, 1, 1)
Global $Group2 = GUICtrlCreateGroup("Behaviour", 8, 112, 561, 169)
Global $promptIfNoArgumentsCheckbox = GUICtrlCreateCheckbox("Prompt if no arguments", 16, 136, 545, 17)
Global $autoRegisterCheckbox = GUICtrlCreateCheckbox("Auto Register. (recommendation: checked)", 16, 176, 545, 17)
Global $autoDeregisterCheckbox = GUICtrlCreateCheckbox("Auto Deregister (recommendation: unchecked)", 16, 232, 545, 17)
Global $Label3 = GUICtrlCreateLabel("Automatically stores the location of FP-QUI in the registry when FP-QUICore is launched.", 35, 192, 521, 20)
Global $Label5 = GUICtrlCreateLabel("Shows a GUI when FP-QUI or FP-QUICore are launched without any parameters.", 35, 152, 477, 20)
Global $Label6 = GUICtrlCreateLabel("Deregisters FP-QUI when FP-QUICore is terminated normally (not forced).", 35, 248, 437, 20)
Global $Label7 = GUICtrlCreateLabel("This helps other applications to find FP-QUI and thereby greatly improves its reliability.", 35, 208, 512, 20)
GUICtrlCreateGroup("", -99, -99, 1, 1)
Global $Group3 = GUICtrlCreateGroup("Defaults", 576, 8, 273, 273)
Global $fontInput = GUICtrlCreateInput("", 656, 32, 100, 24)
Global $fontSizeInput = GUICtrlCreateInput("", 656, 64, 100, 24, BitOR($ES_AUTOHSCROLL,$ES_NUMBER))
Global $minimumFontSizeDefaultButton = GUICtrlCreateButton("Default", 784, 128, 59, 25, 0)
Global $Label8 = GUICtrlCreateLabel("Default height", 584, 192, 85, 20, $SS_CENTERIMAGE)
Global $minimumFontSizeInput = GUICtrlCreateInput("", 704, 128, 73, 24, BitOR($ES_AUTOHSCROLL,$ES_NUMBER))
Global $textColorInput = GUICtrlCreateInput("", 656, 96, 100, 24)
Global $heightInput = GUICtrlCreateInput("", 704, 192, 73, 24, BitOR($ES_AUTOHSCROLL,$ES_NUMBER))
Global $selectFontButton = GUICtrlCreateButton("Select Font Properties", 760, 32, 83, 49, $BS_MULTILINE)
Global $fontPropertiesDefaultButton = GUICtrlCreateButton("Default", 760, 88, 83, 33, 0)
Global $Label9 = GUICtrlCreateLabel("Font", 584, 32, 30, 20, $SS_CENTERIMAGE)
Global $Label10 = GUICtrlCreateLabel("Font Size", 584, 64, 59, 20, $SS_CENTERIMAGE)
Global $Label11 = GUICtrlCreateLabel("Font Colour", 584, 96, 72, 20, $SS_CENTERIMAGE)
Global $Label12 = GUICtrlCreateLabel("Minimum Font Size", 584, 128, 115, 20, $SS_CENTERIMAGE)
Global $Label13 = GUICtrlCreateLabel("Background Color", 584, 160, 112, 20)
Global $bkColorCombo = GUICtrlCreateCombo("", 704, 160, 73, 25)
GUICtrlSetData(-1, "blue|green|red|orange|white|black|gray|purple|yellow")
Global $heightDefaultButton = GUICtrlCreateButton("Default", 784, 192, 59, 25, 0)
Global $bkColorDefaultButton = GUICtrlCreateButton("Default", 784, 160, 59, 25, 0)
Global $Label14 = GUICtrlCreateLabel("Transparency", 584, 224, 88, 20, $SS_CENTERIMAGE)
Global $transInput = GUICtrlCreateInput("", 704, 224, 73, 24, BitOR($ES_AUTOHSCROLL,$ES_NUMBER))
Global $fadeOutCheckbox = GUICtrlCreateCheckbox("Fade out", 584, 248, 257, 24)
Global $transDefaultButton = GUICtrlCreateButton("Default", 784, 224, 59, 25, 0)
GUICtrlCreateGroup("", -99, -99, 1, 1)
Global $Group4 = GUICtrlCreateGroup("Colours", 8, 350, 313, 121)
Global $colorsListBox = GUICtrlCreateList("", 16, 374, 137, 82, -1, 0)
GUICtrlSetState(-1, $GUI_HIDE)
Global $colorsInput = GUICtrlCreateInput("", 160, 374, 154, 24)
GUICtrlSetState(-1, $GUI_HIDE)
Global $colorsDefaultButton = GUICtrlCreateButton("Default", 160, 403, 75, 25, 0)
GUICtrlSetState(-1, $GUI_HIDE)
Global $colorsSelectButton = GUICtrlCreateButton("Select", 240, 403, 75, 25, 0)
GUICtrlSetState(-1, $GUI_HIDE)
Global $colorsSaveButton = GUICtrlCreateButton("Save", 160, 431, 155, 25, 0)
GUICtrlSetState(-1, $GUI_HIDE)
GUICtrlCreateGroup("", -99, -99, 1, 1)
GUICtrlSetState(-1, $GUI_HIDE)
#EndRegion ### END Koda GUI section ###



Func _showConfigurationAssistantGUI()
	GUISetState(@SW_SHOW, $configurationAssistantGUI)
EndFunc

Func _hideConfigurationAssistantGUI()
	GUISetState(@SW_HIDE, $configurationAssistantGUI)
EndFunc
