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

Func _initializeBehaviour()
	
;~ 	Global $behaviourPromptIfNoArguments 	= _iniRead($GlobalConfigPath, "behaviour", "promptIfNoArguments", 1)
	Global $behaviourFadeOut 				= _iniRead($GlobalConfigPath, "behaviour", "fadeOut", 1)
	Global $behaviourMaxInstances 			= _iniRead($GlobalConfigPath, "behaviour", "maxInstances", 10)
	Global $behaviourAutoRegister 			= _iniRead($globalConfigPath, "behaviour", "autoRegister", 1)
	Global $behaviourAutoDeregister 		= _iniRead($globalConfigPath, "behaviour", "autoDeregister", 0)
	
	Global $behaviourFirstStart 			= _iniRead($globalConfigPath, "behaviour", "firstStart", 1)
	Global $behaviourshowFirstStartGUI 		= _iniRead($globalConfigPath, "behaviour", "showFirstStartGUI", 1) ;deprecated
	
	Global $behaviourShowMenuOnFirstStart	= _iniRead($globalConfigPath, "behaviour", "showMenuOnFirstStart", 1)
	Global $behaviourShowMenuOnNoArguments 	= _iniRead($globalConfigPath, "behaviour", "showMenuOnNoArguments", 1)
	
EndFunc