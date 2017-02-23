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