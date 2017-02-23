#cs

	FP-QUI allows you to show popups in the tray area.
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

Global $FPQUI_REGKEY = "HKEY_LOCAL_MACHINE\SOFTWARE\FP-QUI"
Global $FPQUI_DIR_REGVALUE = "dir"
Global $FPQUI_EXE_REGVALUE = "exe"
Global $FPQUI_COREEXE_REGVALUE = "coreExe"

Func _fpquiRegister($promptUser=Default, $dir=Default, $exe=Default, $coreExe=Default)

	If $promptUser == Default Then $promptUser=0
	If $dir == Default Then $dir = @ScriptDir
	If $exe == Default Then $exe = "FP-QUI.exe"
	If $coreExe == Default Then $coreExe = "FP-QUICore.exe"
	
	If $promptUser<>0 Then
		Local $answer = MsgBox(1+64, @ScriptName, 'The following key will be added to your registry: "'&$FPQUI_REGKEY&'"')
		If $answer == 2 Then Return SetError(1,0,"")
	EndIf
	
	Local $return
	
	If $dir<>"" Then $return = RegWrite($FPQUI_REGKEY, $FPQUI_DIR_REGVALUE, "REG_SZ", $dir)
	If @error Then SetError(@error, @extended, $return)

	If $exe<>"" Then $return = RegWrite($FPQUI_REGKEY, $FPQUI_EXE_REGVALUE, "REG_SZ", $exe)
	If @error Then SetError(@error, @extended, $return)

	If $coreExe<>"" Then $return = RegWrite($FPQUI_REGKEY, $FPQUI_COREEXE_REGVALUE, "REG_SZ", $coreExe)
	If @error Then SetError(@error, @extended, $return)

	Return $return

EndFunc


Func _fpquiDeregister($promptUser=Default)
	
	If $promptUser == Default Then $promptUser=0
	
	If $promptUser<>0 Then
		Local $answer = MsgBox(1+64, @ScriptName, 'The following key will be removed from your registry: "'&$FPQUI_REGKEY&'"')
		If $answer == 2 Then Return SetError(1,0,"")
	EndIf
	
	Local $return = RegDelete($FPQUI_REGKEY)
	Return SetError(@error, @extended, $return)
	
EndFunc

Func _fpquiGetRegister($option)

	Local $return
	Local $error

	Switch $option
		
	Case "dir" ;dir
		$return = RegRead($FPQUI_REGKEY, $FPQUI_DIR_REGVALUE)
		Return SetError(@error, @extended, $return)
		
	Case "exe" ;exe
		$return = RegRead($FPQUI_REGKEY, $FPQUI_EXE_REGVALUE)
		Return SetError(@error, @extended, $return)
		
	Case "coreExe" ;coreExe
		$return = RegRead($FPQUI_REGKEY, $FPQUI_COREEXE_REGVALUE)
		Return SetError(@error, @extended, $return)
		
	EndSwitch
	
EndFunc