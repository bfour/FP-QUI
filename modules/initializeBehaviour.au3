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

#include <_config.au3>

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