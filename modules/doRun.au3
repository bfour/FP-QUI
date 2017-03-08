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

Func _doRun($i)

   If $notificationsOptions[$i][23]<>"" Then

      Local $run=_commandLineInterpreter($notificationsOptions[$i][23],"cmd;repeat;pause")
      Local $cmd=$run[0][1]
      Local $repeat=$run[1][1]
      Local $pause=$run[2][1]

      ;avoid unexpected behaviour
      If $repeat=="" And $pause=="" Then $repeat=1
      If $pause<1000 Then $pause=1000

      Local $runData=_commandLineInterpreter($notificationsOptionsData[$i][23],"timer;repetitions")
      Local $timer=$runData[0][1]
      Local $repetitions=$runData[1][1]

      If (($timer=="" Or $pause=="" Or TimerDiff($timer)>$pause) And ($repetitions=="" Or $repeat=="" Or $repetitions<$repeat)) Then

         _executeCommand($cmd)

         If $pause<>"" Then $timer=TimerInit() ;only store timer if relevant
         If $repeat<>"" Then $repetitions+=1 ;only store repetitions if relevant
         $notificationsOptionsData[$i][23]="<timer>"&$timer&"</timer><repetitions>"&$repetitions&"</repetitions>"

      EndIf

   EndIf

EndFunc