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

Func _initializeNotificationsArrays()
	
	; [0: GUI-Handle, 1: ico-Handle, 2: avi-Handle, 3: label-Handle, 4: progress-Handle, 5: button-handles (<1>handle</1> etc.)
	Global $notificationsHandles[1][$numberOfHandles]
	; notificationsOptions: n,21: test.wav 
	Global $notificationsOptions[1][$numberOfOptions]
	; $notificationsOptionsData: n,21: how often has sound been played		
	Global $notificationsOptionsData[1][$numberOfOptions]
	
	Global $notificationsDeleteRequests[1] ; Array containing winHandles (/IDs) to be deleted. If a notification is closed a request is stored in this array. Once the main loop has finished, all notificationsArray-entries will be deleted according to this array. This avoids outOfBounds-Errors during the execution of the main loop, when a user generates a click-event that causes a notification to close
	
EndFunc