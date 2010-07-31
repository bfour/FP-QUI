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

#include-once

#include <_stringReplaceVariables.au3>

Func _initializeDefaults()
	
	Global $defaultFont				= _iniRead($globalConfigPath, "defaults", "font", "Arial")
	Global $defaultFontSize			= _iniRead($globalConfigPath, "defaults", "fontSize", 16)
	Global $defaultMinimumFontSize	= _iniRead($globalConfigPath, "defaults", "minimumFontSize", 12)
	Global $defaultHeight			= _iniRead($globalConfigPath, "defaults", "height", 60)
	Global $defaultTextColor		= _iniRead($globalConfigPath, "defaults", "textColor", Default)
	Global $defaultBkColor			= _iniRead($globalConfigPath, "defaults", "bkColor", 0xFFFF99)
	Global $defaultTrans			= _iniRead($globalConfigPath, "defaults", "trans", 200)
	Global $defaultIcon 			= _stringReplaceVariables(_iniRead($globalConfigPath, "defaults", "icon", "@ScriptDir\icon.ico"))
	Global $defaultIconAviSize		= _iniRead($globalConfigPath, "defaults", "iconAviSize", 48)
	
	Global $defaultWidth = 200
	
EndFunc