#cs
author: Florian Pollak
#ce

#include-once

#include <_ini.au3>

If Not IsDeclared("CONFIG_INIT") Then Global $_configInit = True ;specifies whether initialization shall be executed or not

Global $globalConfigPath=@ScriptDir&"\data\config_global.ini"

If $_configInit Then _iniInitialize($globalConfigPath,"","@ScriptDir\data\config_@UserName_@ComputerName.ini",Default,1,1)