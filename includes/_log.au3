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

#cs
$interactive:    1:interactive 0:silent
$broadcast:      broadcast errorNotification in cluster
#ce

#include-once
#include <File.au3>
#include <Array.au3>
#include <_gridDir.au3>
#include <_FPUI.au3>

Global $_LOG_MAXLINES = 1000
Global $_LOG_MINLINES = 1

;set $maxNumberOfLines and $minNumberOfLines to -1 to disable this feature
Func _log($enabled,$event,$logDir=Default,$logFile=Default,$maxNumberOfLines=Default,$minNumberOfLines=Default)

   If $logDir == Default Then $logDir = @ScriptDir
   If $logFile == Default Then $logFile = @ScriptName&"_log.txt"
   If $maxNumberOfLines == Default Then $maxNumberOfLines = 1000
   If $minNumberOfLines == Default Then $minNumberOfLines = 1

   Local $error=0

   If $enabled Then

      If DirGetSize($logDir,2)=-1 Then DirCreate($logDir)
      $logPath=$logDir&"\"&$logFile

      $section=IniReadSection($logPath,"log")
      _ArrayDelete($section,0)
      $lineCount = _FileCountLines($logPath) - 1

      If IsArray($section) And $lineCount>$maxNumberOfLines Then
         For $i=0 To $lineCount-$maxNumberOfLines Step 1
            If $i<UBound($section) Then
               IniDelete($logPath,"log",$section[$i][0])
            EndIf
         Next
      EndIf

      IniWrite($logPath,"log",@YEAR&"-"&@MON&"-"&@MDAY&"-"&@HOUR&"-"&@MIN&"-"&@SEC&"-"&@MSEC&"_"&Random(0,9,1)&Random(0,9,1),";"&$event&";"&@ComputerName&";"&@UserName&";"&@ScriptName&";"&@AutoItPID)

   EndIf

   If $error<>0 Then SetError($error)

EndFunc

Func _logError($description,$interactive=Default,$broadcast=Default,$logEnabled=Default,$logDir=Default,$logFile=Default,$logMaxNumberOfLines=Default,$forceMsgBox=Default,$msgBoxTimeout=Default)

   If $interactive=Default Then $interactive=1
   If $broadcast=Default Then $broadcast=0

   If $logEnabled=Default Then $logEnabled=0
   If $logDir=Default Then $logDir=@ScriptDir
   If $logFile=Default Then $logFile="log_"&@UserName&"_"&@ComputerName&".txt"
   If $logMaxNumberOfLines=Default Then $logMaxNumberOfLines=1000

   If $forceMsgBox=Default Then $forceMsgBox=0
   If $msgBoxTimeout==Default Then $msgBoxTimeout=0 ;0...no timeout

   ;show
   If $interactive Then

      Local $gridDir = _gridDir()
      If _gridDir() <> "" And FileExists(_gridDir()&'\FP-QUI\FP-QUI.exe')==1 And $forceMsgBox==0 Then

         _FPUIError($description)

      Else

         MsgBox(0+16,@ScriptName&"/Error", _
            @YEAR&@MON&@MDAY&@HOUR&@MIN&@SEC&": " &@UserName&"@"&@ComputerName&":" &@LF& _
            $description&@LF& _
            @LF& _
            "Please help make this software better by filing a bug-report.", $msgBoxTimeout)

      EndIf

      ;broadcast if specified
;~       If $broadcast==1 Then Run('"'&_gridDir()&'\FP-Intercom\FP-IntercomClient.exe" "<recip>%all%</recip><msg>%grid%\FP-QUI\FP-QUI.exe '&$notifierInstructions&'</msg>"')

   EndIf

   ;log
   If $logEnabled==1 Then _log($logEnabled,$description,$logDir,$logFile,$logMaxNumberOfLines)

EndFunc

Func _logWarning($description,$interactive=1,$broadcast=Default,$logEnabled=Default,$logDir=Default,$logFile=Default,$logMaxNumberOfLines=Default,$forceMsgBox=Default,$msgBoxTimeout=Default)

   If $interactive == 1 Then _FPUIWarning($description)

   ; TODO file-logging and broadcasting

EndFunc

Func _logInfo($description,$interactive=1,$broadcast=Default,$logEnabled=Default,$logDir=Default,$logFile=Default,$logMaxNumberOfLines=Default,$forceMsgBox=Default,$msgBoxTimeout=Default)

   If $interactive == 1 Then _FPUIInfo($description)

   ; TODO file-logging and broadcasting

EndFunc

Func _logDebug($description,$interactive=1,$broadcast=Default,$logEnabled=Default,$logDir=Default,$logFile=Default,$logMaxNumberOfLines=Default,$forceMsgBox=Default,$msgBoxTimeout=Default)

   If $interactive == 1 Then _FPUIDebug($description)

EndFunc