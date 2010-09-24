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