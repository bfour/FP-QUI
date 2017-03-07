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

   This is a delegate for sending IPC-messages.
   As AutoIt has no practically usable threading mechanisms it is imperative
   to keep resource intensive tasks away from the QUICore. This delegate is
   typically used by QUICore if replying to a request fails.

   CI:

   exe
      <recip> ... identifier of recipient (eg. name of pipe, handle for wm_copydata)
      <msg> ... message to send to recipient
      <maxRetries> ... maximum number of retries in case contacting recipient fails
      <retryPause> ... pause between retries
      <errorMode>  ... what to do if contacting recipient fails
         QUI          ... show a QUI-notification
         msgbox       ... show a message box
         stdout       ... print on stdout
         pipe         ... send something to pipe
      <errorModePipe>
         specify pipe if pipe has been chosen as errorMode
      <errorMsg>
         what to return on error (default if empty: "pipe send failed" etc. (see below))

#ce

; TODO add wmcopydata options

#NoTrayIcon

#include <_pipe.au3>
#include <_commandLineInterpreter.au3>

#include "modules\initializeErrorHandling.au3"

_initializeErrorHandling()

Local $interface  = "recip;msg;maxRetries;retryPause;errorMode;errorModePipe;errorMsg"
Local $request    = _commandLineInterpreter($CmdLineRaw, $interface)

Local $recip      = $request[0][1]
Local $msg        = $request[1][1]
Local $maxRetries = $request[2][1]
Local $retryPause = $request[3][1]
Local $errorMode  = $request[4][1]
Local $errorPipe  = $request[5][1]
Local $errorMsg   = $request[6][1]

If $recip == ""      Then Exit
If $maxRetries == "" Then $maxRetries = Default
If $retryPause == "" Then $retryPause = Default
If $errorMode == ""  Then $errorMode = "msgbox"
If $errorMsg == ""   Then $errorMsg = 'sending instructions via pipe to "'&$recip&'" failed'


Local $return=_pipeSend($recip, $msg, $maxRetries, $retryPause)

If $return<>1 Then

   Switch $errorMode

      Case "QUI"
         _error($errorMsg,$errorInteractive,$errorBroadcast,$errorLog,$errorLogDir,$errorLogFile,$errorLogMaxNumberOfLines,0)

      Case "msgbox"
         _error($errorMsg,$errorInteractive,$errorBroadcast,$errorLog,$errorLogDir,$errorLogFile,$errorLogMaxNumberOfLines,1)

      Case "stdout"
         ConsoleWrite($errorMsg)

      Case "pipe"
         _pipeSend($errorPipe, $errorMsg)

      Case "log"
         _error($errorMsg,0,0,$errorLog,$errorLogDir,$errorLogFile,$errorLogMaxNumberOfLines)

   EndSwitch

EndIf
