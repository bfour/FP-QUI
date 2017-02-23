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

Func _initializeColors()

	Global $colorsAvailable = StringSplit(_iniRead($globalConfigPath,"colors","available","blue;green;red;orange;white;black;gray;purple;yellow"), ";", 3)

	Global $colorsBlue		= _iniRead($globalConfigPath,"colors","blue",0x98C9FA)
	Global $colorsGreen		= _iniRead($globalConfigPath,"colors","green",0xB5EFB4)
	Global $colorsRed		= _iniRead($globalConfigPath,"colors","red",0xFFB7B7)
	Global $colorsOrange	= _iniRead($globalConfigPath,"colors","orange",0xFFBC9B)
	Global $colorsWhite		= _iniRead($globalConfigPath,"colors","white",0xFFFFFF)
	Global $colorsBlack		= _iniRead($globalConfigPath,"colors","black",0x000000)
	Global $colorsGray		= _iniRead($globalConfigPath,"colors","gray",0xC9C9C9)
	Global $colorsPurple	= _iniRead($globalConfigPath,"colors","purple",0xD7AEFF)
	Global $colorsYellow	= _iniRead($globalConfigPath,"colors","yellow",0xFFFFAE)

EndFunc