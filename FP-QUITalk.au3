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

#cs

	author: Florian Pollak
	
	syntax: exe [string]

#ce

#NoTrayIcon

#include <_talk.au3>

;if another instance is already up and running, exit
Local $instances=ProcessList(@ScriptName)
If $instances[0][0]>1 Then Exit

_talk($CmdLineRaw)