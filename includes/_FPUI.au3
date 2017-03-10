#cs

   Copyright 2015-2017 Florian Pollak (bfourdev@gmail.com)

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
#include <_fpqui.au3>
#include <_log.au3>
#include <TreeViewConstants.au3>
#include <GuiTreeView.au3>

Global $_FPUIUseQUIDefault = 1
Global $_FPUIUseMsgBoxDefault = 0
Global $_FPUIUseConsoleDefault = 0
Global $_FPUIUseTreeViewDefault = Default
Global $_FPUIShowLevel = 1 ; 0:debug 1:info 2:warn 3:error | example: 1 -> only show info and above

_FPUIInitialize()

Func _FPUIInitialize()

   Local $iconPath=@AutoItExe
   ;take icon.ico in current dir as icon if existent
   ;if not, take current exe's icon instead
   If FileExists(@ScriptDir&"\icon.ico")==1 Then $iconPath=@ScriptDir&"\icon.ico"
   If FileExists(@ScriptDir&"\GUI\icon.ico")==1 Then $iconPath=@ScriptDir&"\GUI\icon.ico"
   If FileExists(@ScriptDir&"\GUI\icons\icon.ico")==1 Then $iconPath=@ScriptDir&"\GUI\icons\icon.ico"

   Global $_FPUIQUIDefaults = "<ico>"&$iconPath&"</ico><noDouble>1</noDouble>"
   Global $_FPUILogLikeQUIDefaults = "<untilClick><any>1</any></untilClick><noDouble>1</noDouble>"
   Global $_FPUIRunAsAdminCommand = @ScriptDir&"\tools\FP-RunAsAdmin.exe"

   Global $_FPUIOKIcon = "", $_FPUIDebugIcon = "", $_FPUIInfoIcon = "", $_FPUIWarningIcon = "", $_FPUIErrorIcon = ""
   If FileExists(@ScriptDir&"\GUI\icons\OK.ico")==1 Then $_FPUIOKIcon=@ScriptDir&"\GUI\icons\OK.ico"
   If FileExists(@ScriptDir&"\GUI\icons\debug.ico")==1 Then $_FPUIDebugIcon=@ScriptDir&"\GUI\icons\debug.ico"
   If FileExists(@ScriptDir&"\GUI\icons\info.ico")==1 Then $_FPUIInfoIcon=@ScriptDir&"\GUI\icons\info.ico"
   If FileExists(@ScriptDir&"\GUI\icons\warning.ico")==1 Then $_FPUIWarningIcon=@ScriptDir&"\GUI\icons\warning.ico"
   If FileExists(@ScriptDir&"\GUI\icons\error.ico")==1 Then $_FPUIErrorIcon=@ScriptDir&"\GUI\icons\error.ico"

   ; stores QUI-references for QUIs that subsequently might needs to be updated etc.
   ; (eg. QUIs for background tasks)
   ; [1..n][0 reference-string (uniqueness needs to be ensured when used), 1 QUI-handle]
   Global $_FPUIQUIList[1][2] = [["",""]]

EndFunc

Func _FPUISetQUIDefault($default)
   $_FPUIUseQUIDefault = $default
EndFunc

Func _FPUISetMsgBoxDefault($default)
   $_FPUIUseMsgBoxDefault = $default
EndFunc

Func _FPUISetConsoleDefault($default)
   $_FPUIUseConsoleDefault = $default
EndFunc

Func _FPUISetTreeViewDefault($default)
   $_FPUIUseTreeViewDefault = $default
EndFunc

Func _FPUISetShowLevel($level)
   Switch $level
      Case "debug"
         $_FPUIShowLevel = 0
      Case "info"
         $_FPUIShowLevel = 1
      Case "warning"
         $_FPUIShowLevel = 2
      Case "error"
         $_FPUIShowLevel = 3
   EndSwitch
EndFunc

; $outputMethods: [n][0:name 1:details (handle/flags/customargs) 2:details]
; options: QUI MsgBox TreeView Console
; example: [["QUI", "<bkColor>green</bkColor>"], ["treeView", $handle]]
Func _FPUINotify($message, $explicitDismissRequired = 0, $timeout = 8000, $outputMethods = Default)

   If $outputMethods == Default Then
      Return _FPUINotifyViaQUI($message, $explicitDismissRequired, $timeout, "")
   EndIf

   For $i=0 To UBound($outputMethods)-1
      Switch $outputMethods[$i][0]
      Case "QUI"
         Local $customArgs = $outputMethods[$i][1]
         Return _FPUINotifyViaQUI($message, $explicitDismissRequired, $timeout, $customArgs)
      Case "MsgBox"
         Local $flags = $outputMethods[$i][1]
         If $explicitDismissRequired == 0 Then $timeout = 0
         Return MsgBox($flags, @ScriptName, $message, $timeout)
      Case "TreeView"
         Local $control = $outputMethods[$i][1]
         Local $icon = $outputMethods[$i][2]
         Local $item = _GUICtrlTreeView_InsertItem($control, $message)
         _GUICtrlTreeView_SetIcon($control, $item, $icon)
         _GUICtrlTreeView_EnsureVisible($control, $item)
         _GUICtrlTreeView_SetIndent($control, 0)
         Return $item
      Case "Console"
         ConsoleWrite($message&@LF)
      EndSwitch
   Next

EndFunc

Func _FPUINotifyViaQUI($message, $explicitDismissRequired, $timeout, $customArgs)
   Local $args = $_FPUIQUIDefaults
   $args &= "<text>"&$message&"</text>"
   If Not $explicitDismissRequired Then $args &= "<delay>"&$timeout&"</delay>"
   $args &= $customArgs
   Return _fpqui($args)
EndFunc

Func _FPUINotifyOK($message, $QUI=$_FPUIUseQUIDefault, $msgBox=$_FPUIUseMsgBoxDefault, $console=$_FPUIUseConsoleDefault, $treeView = $_FPUIUseTreeViewDefault)
   Local $methods[1][3]
   If $QUI==1 Then _FPUIAddMethod($methods, "QUI", "<bkColor>green</bkColor>"&$_FPUILogLikeQUIDefaults, "")
   If $msgBox==1 Then _FPUIAddMethod($methods, "MsgBox", 0)
   If $console==1 Then _FPUIAddMethod($methods, "Console")
   If $treeView<>Default Then _FPUIAddMethod($methods, "TreeView", $treeView, $_FPUIOKIcon)
   Return _FPUINotify($message, 0, 8000, $methods)
EndFunc

Func _FPUIDebug($message, $QUI=$_FPUIUseQUIDefault, $msgBox=$_FPUIUseMsgBoxDefault, $console=$_FPUIUseConsoleDefault, $treeView = $_FPUIUseTreeViewDefault)
   If $_FPUIShowLevel > 0 Then Return
   Local $methods[1][3]
   If $QUI==1 Then _FPUIAddMethod($methods, "QUI", "<bkColor>white</bkColor>"&$_FPUILogLikeQUIDefaults)
   If $msgBox==1 Then _FPUIAddMethod($methods, "MsgBox", 0)
   If $console==1 Then _FPUIAddMethod($methods, "Console")
   If $treeView<>Default Then _FPUIAddMethod($methods, "TreeView", $treeView, $_FPUIDebugIcon)
   Return _FPUINotify($message, 0, 4000, $methods)
EndFunc

Func _FPUIInfo($message, $QUI=$_FPUIUseQUIDefault, $msgBox=$_FPUIUseMsgBoxDefault, $console=$_FPUIUseConsoleDefault, $treeView = $_FPUIUseTreeViewDefault)
   If $_FPUIShowLevel > 1 Then Return
   Local $methods[1][3]
   If $QUI==1 Then _FPUIAddMethod($methods, "QUI", "<bkColor>blue</bkColor>"&$_FPUILogLikeQUIDefaults)
   If $msgBox==1 Then _FPUIAddMethod($methods, "MsgBox", 64)
   If $console==1 Then _FPUIAddMethod($methods, "Console")
   If $treeView<>Default Then _FPUIAddMethod($methods, "TreeView", $treeView, $_FPUIInfoIcon)
   Return _FPUINotify($message, 0, "", $methods)
EndFunc

Func _FPUIWarning($message, $QUI=$_FPUIUseQUIDefault, $msgBox=$_FPUIUseMsgBoxDefault, $console=$_FPUIUseConsoleDefault, $treeView = $_FPUIUseTreeViewDefault)
   If $_FPUIShowLevel > 2 Then Return
   Local $methods[1][3]
   If $QUI==1 Then _FPUIAddMethod($methods, "QUI", "<bkColor>orange</bkColor>"&$_FPUILogLikeQUIDefaults)
   If $msgBox==1 Then _FPUIAddMethod($methods, "MsgBox", 48)
   If $console==1 Then _FPUIAddMethod($methods, "Console")
   If $treeView<>Default Then _FPUIAddMethod($methods, "TreeView", $treeView, $_FPUIWarningIcon)
   _FPUINotify($message, 0, "", $methods)
EndFunc

Func _FPUIError($message, $QUI=$_FPUIUseQUIDefault, $msgBox=$_FPUIUseMsgBoxDefault, $console=$_FPUIUseConsoleDefault, $treeView = $_FPUIUseTreeViewDefault)
   Local $methods[1][3]
   If $QUI==1 Then _FPUIAddMethod($methods, "QUI", "<bkColor>red</bkColor>"&$_FPUILogLikeQUIDefaults)
   If $msgBox==1 Then _FPUIAddMethod($methods, "MsgBox", 16)
   If $console==1 Then _FPUIAddMethod($methods, "Console")
   If $treeView<>Default Then _FPUIAddMethod($methods, "TreeView", $treeView, $_FPUIErrorIcon)
   Return _FPUINotify($message, 0, "", $methods)
EndFunc

Func _FPUIAddMethod(ByRef $methods, $name, $opt1="", $opt2="")
   ReDim $methods[UBound($methods)+1][3]
   Local $idx = UBound($methods)-1
   $methods[$idx][0] = $name
   $methods[$idx][1] = $opt1
   $methods[$idx][2] = $opt2
EndFunc

Func _FPUIIntent($description, $command, $requireAdmin = 0)

   If $requireAdmin == 1 Then
     If Not FileExists($_FPUIRunAsAdminCommand) Then
       SetError(1)
       _logError('RunAsAdminCommand refers to file that does not exist. Admin rights required for intent "'&$description&'".')
       Return
     EndIf
     $command = $_FPUIRunAsAdminCommand & " " & $command
   EndIf

   Local $args = $_FPUIQUIDefaults
   $args &= "<text>"&$description&"</text>"
   $args &= "<bkColor>gray</bkColor>"
   $args &= "<button><ID1><label>apply</label><cmd>"&$command&"</cmd></ID1></button>"
   $args &= "<untilClick><includeButton>1</includeButton><any>1</any></untilClick>"

   Return _fpqui($args)

EndFunc

Func _FPUITask($text, $PID = @AutoItPID, $progress = "", $extraParams = "")

   ; lookup existing QUI via PID
   Local $QUIHandle = _FPUIQUIListLookup($_FPUIQUIList, $PID)

   Local $args = ""
   If $text <> Default Then $args &= "<text>"&$text&"</text>"
   $args &= "<progress>"&$progress&"</progress><audio></audio><bkColor></bkColor><avi>S:\sabox\grid\data\GUI\avis\busy_indicator_32x32.avi</avi>"

   If $QUIHandle=="" Then
     $args = $_FPUIQUIDefaults & $args
     $args &= "<untilProcessClose>"&$PID&"</untilProcessClose>"
     $args &= "<button><ID1><label>abort</label><cmd>taskkill /PID "&$PID&"</cmd></ID1></button>"
     $args &= $extraParams
     $QUIHandle = _fpqui($args)
   Else
     $args &= $extraParams
     $QUIHandle = _fpquiUpdate($args, $QUIHandle)
   EndIf

   _FPUIQUIListSet($_FPUIQUIList, $PID, $QUIHandle)
   Return $QUIHandle

EndFunc

; show status of task and indicate the task needs attention
Func _FPUITaskAttention($text, $PID = @AutoItPID, $progress = "", $extraParams = "")
   Return _FPUITask($text, $PID, "", "<bkColor>orange</bkColor><avi>S:\sabox\grid\data\GUI\avis\warning_indicator_32x32.avi</avi><audio><path>S:\sabox\grid\data\audio\Star Trek\fav\alarm01.mp3</path><pause>1861</pause></audio>"&$extraParams)
EndFunc

; show status of task and indicate the task is done
Func _FPUITaskDone($text = "done", $PID = @AutoItPID)
   Return _FPUITask($text, $PID, "", "<bkColor>green</bkColor><avi></avi><delay>8161</delay><untilProcessClose></untilProcessClose>")
EndFunc

; returns QUI-handle corresponding to given reference string
; @error 1: not found
Func _FPUIQUIListLookup(ByRef $QUIList, $referenceString)

   For $i = 1 To UBound($QUIList)-1
     If $QUIList[$i][0] == $referenceString Then Return $QUIList[$i][1]
   Next

   SetError(1)
   Return ""

EndFunc

Func _FPUIQUIListSet(ByRef $QUIList, $referenceString, $QUIHandle)

   ; update existing entry if exists
   For $i = 1 To UBound($QUIList)-1
     If $QUIList[$i][0] == $referenceString Then
       $QUIList[$i][1] = $QUIHandle
       Return
     EndIf
   Next

   ; new entry
   ReDim $QUIList[UBound($QUIList)+1][UBound($QUIList,2)]
   $QUIList[UBound($QUIList)-1][0] = $referenceString
   $QUIList[UBound($QUIList)-1][1] = $QUIHandle

EndFunc