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