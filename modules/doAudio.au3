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

#include <Sound.au3>

Func _doAudio($i)

   If $notificationsOptions[$i][20]<>"" Then

      ; get instructions
      Local $audio   =_commandLineInterpreter($notificationsOptions[$i][20],"path;repeat;pause;maxVol;shake")
      Local $path      = $audio[0][1]
      Local $repeat   = $audio[1][1]
      Local $pause   = $audio[2][1]
      Local $maxVol   = $audio[3][1]
      Local $shake   = $audio[4][1]

      ; avoid unexpected behaviour
      If $repeat=="" And $pause=="" Then $repeat=1
      If $pause<1000 Then $pause=1000

      ; get stored data
      Local $audioData   = _commandLineInterpreter($notificationsOptionsData[$i][20],"timer;repetitions;IDAvailable;path")
      Local $timer      = $audioData[0][1]
      Local $repetitions   = $audioData[1][1]
      Local $IDAvailable   = $audioData[2][1]
      Local $oldPath       = $audioData[3][1]
      Local $soundID      = $notificationsOptionsData[$i][21]

      ; main
      If (($timer=="" Or $pause=="" Or TimerDiff($timer)>$pause) And ($repetitions=="" Or $repeat=="" Or $repetitions<$repeat)) Then

         If $maxVol<>"" Then
            SoundSetWaveVolume(100)
            Send("{VOLUME_UP 50}")
         EndIf

         Local $fileExtension = _pathGetFileExtension($path)

         If $fileExtension=="wav" Or $fileExtension=="mp3" Then

            If $IDAvailable <> 1 Or $oldPath <> $path Then
               _SoundClose($soundID)
               $soundID = _SoundOpen($path) ; open sound and assing winhandle as alias
               If @error Then
                  _error('failed to open sound: @error='&@error&'; @extended='&@extended, $errorInteractive, $errorBroadcast, $errorLog, $errorLogDir, $errorLogfile, $errorLogMaxNumberOfLines)
                  Return(SetError(@error, @extended, ""))
               EndIf
            EndIf

            _SoundPlay($soundID, 0)
            If @error Then
               _error('failed to play sound: @error='&@error&'; @extended='&@extended, $errorInteractive, $errorBroadcast, $errorLog, $errorLogDir, $errorLogfile, $errorLogMaxNumberOfLines)
               Return(SetError(@error, @extended, ""))
            EndIf

         Else
            ShellExecute($path,"","","open")
         EndIf

         ; shake
         If $shake<>"" Then _shakeNotification($i)

         ; store soundID
         $notificationsOptionsData[$i][21] = $soundID ;TODO find other solution, this is actually reserved for <replaceVar>

         If $pause<>"" Then $timer=TimerInit() ;only store timer if relevant
         If $repeat<>"" Then $repetitions+=1 ;only store repetitions if relevant
         $notificationsOptionsData[$i][20] = "<timer>"&$timer&"</timer><repetitions>"&$repetitions&"</repetitions><IDAvailable>1</IDAvailable><path>"&$path&"</path>"

      EndIf

   EndIf

EndFunc

