#cs

	FP-QUI allows you to show popups that provide a quick user interface.
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

Func _setConfiguration($category, $key, $value)
	
;~ 	Local $varName = $category & StringUpper(StringLeft($key,1)) & StringTrimLeft($key,1)
;~ MsgBox(1,"$varName",$varName)
;~ 	If IsDeclared($varName) Then Assign($varName, $value)
	
	$return = _iniWrite($globalConfigPath, $category, $key, $value)
	Return SetError(@error, @extended, $return)
	
EndFunc