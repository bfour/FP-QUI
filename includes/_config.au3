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

#include <_ini.au3>

If Not IsDeclared("CONFIG_INIT") Then Global $_configInit = True ;specifies whether initialization shall be executed or not

Global $globalConfigPath=@ScriptDir&"\data\config_global.ini"

If $_configInit Then _iniInitialize($globalConfigPath,"","@ScriptDir\data\config_@UserName_@ComputerName.ini",Default,1,1)