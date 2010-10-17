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

Func _initializeInterface()
	
	Global $cmdLineDescriptorRequest="text;delay;textColor;width;height;bkColor;ico;onClick;untilProcessExists;untilProcessClose;noDouble;untilClick;beep;x;y;talk;font;fontSize;trans;focus;audio;replaceVar;avi;run;progress;button;winHandle;reply;dispatcherArea;startPos;direction;delete;update;createIfNotVisible;system;noReposAfterHide"
	Global $numberOfOptions=UBound(StringSplit($cmdLineDescriptorRequest,";",3))
	
	Global $numberOfHandles=6
	
EndFunc


