#cs

   Copyright 2008-2017 Florian Pollak (bfourdev@gmail.com)

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

DEPRECATED: moved to _log.au3

$interactive:    1:interactive 0:silent
$broadcast:      broadcast errorNotification in cluster

#ce

#include-once
#include <_gridDir.au3>
#include <_log.au3>

Func _error($description,$interactive=Default,$broadcast=Default,$logEnabled=Default,$logDir=Default,$logFile=Default,$logMaxNumberOfLines=Default,$forceMsgBox=Default,$msgBoxTimeout=Default)

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

      Local $iconPath=@AutoItExe
      ;take icon.ico in current dir as icon if existent
      ;if not, take current exe's icon instead
      If FileExists(@ScriptDir&"\icon.ico")==1 Then $iconPath=@ScriptDir&"\icon.ico"


      Local $notifierInstructions='<text>'&StringReplace(@ScriptName,".exe","")&'@'&@ComputerName&': '&$description&'</text><ico>'&$iconPath&'</ico><bkColor>red</bkColor><untilClick><any>1</any></untilClick><noDouble>1</noDouble>'

      Local $gridDir = _gridDir()
      If _gridDir() <> "" And FileExists(_gridDir()&'\FP-QUI\FP-QUI.exe')==1 And $forceMsgBox==0 Then

         ;run FP-QUI
         Run(_gridDir()&'\FP-QUI\FP-QUI.exe '&$notifierInstructions)

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

Func _warning($description,$interactive=Default,$broadcast=Default,$logEnabled=Default,$logDir=Default,$logFile=Default,$logMaxNumberOfLines=Default,$forceMsgBox=Default,$msgBoxTimeout=Default)

   MsgBox(0+48,@ScriptName&"/Warning", _
      @YEAR&@MON&@MDAY&@HOUR&@MIN&@SEC&": " &@UserName&"@"&@ComputerName&":" &@LF& _
      $description, $msgBoxTimeout)

EndFunc

Func _info($description,$interactive=Default,$broadcast=Default,$logEnabled=Default,$logDir=Default,$logFile=Default,$logMaxNumberOfLines=Default,$forceMsgBox=Default,$msgBoxTimeout=Default)

   MsgBox(0+64,@ScriptName&"/Info", _
      @YEAR&@MON&@MDAY&@HOUR&@MIN&@SEC&": " &@UserName&"@"&@ComputerName&":" &@LF& _
      $description, $msgBoxTimeout)

EndFunc