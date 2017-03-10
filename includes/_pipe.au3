#cs

   Copyright 2010-2017 Florian Pollak (bfourdev@gmail.com

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

#include <String.au3>
#Include <NamedPipes.au3>
#include <_error.au3>

;calling pipeReceive will automatically create a new pipe and this holds its handle
Global $_pipe_defaultPipeHandle = ""

;return: success: 1; failure: 0 and <>1
Func _pipeSend($pipeName, $data, $maxRetries=Default, $retryPause=Default, $retries=Default)

   If $maxRetries == Default Then $maxRetries=20
   If $retryPause == Default Then $retryPause=100   
   If $retries    =  = Default Then $retries=0

   Local Const $vzbEZ_PIPE_NAME = "\\.\pipe\"&$pipeName

   While 1

      Local $file = FileOpen($vzbEZ_PIPE_NAME, 2)

      If $file <> -1 Then
         Local $return = FileWrite($file,$data)
         FileClose($file)
         Return $return
      Else
         FileClose($file)
         If $retries < $maxRetries Then
            $retries += 1
            Sleep($retryPause)
            ContinueLoop
         Else
            SetError(1)
            Return "couldNotOpenPipe"
         EndIf
      EndIf

   WEnd

   Return 0

EndFunc


;out: pipeHandle
;error: 0 ... OK, 1 ... creating the pipe failed, 2 ... initial connect (wait==0) failed
Func _pipeCreate($pipeName, $wait)

   Local $pipePath = "\\.\pipe\"&$pipeName

   Local $sendBufferSize=4096
   Local $receiveBufferSize=4096

   Local $pipeHandle = _NamedPipes_CreateNamedPipe( _
         $pipePath, _
         2, _ ; access-mode (0 inbound, 1 outbound, 2 duplex)
         2, _ ; flags
         0, _ ; security ACL flags (none)
         1, _ ; pipe type mode: 1 .... data is written as stream of messages
         1, _ ; read mode: 1 ... data is read as stream of messages
         Not($wait), _ ; wait mode: 0 - Blocking mode is enabled, 1 - Nonblocking mode is enabled --> Not($wait)
         1, _ ; maximum number of instances that can be created for this pipe -> 1 ... singleton
         $receiveBufferSize, _ ;OutBufSize
         $sendBufferSize, _ ;InpBufSize
         5000, _ ;time out value, in milliseconds (Maximum time, in milliseconds, that can pass before a remote named pipe transfers information)
         0 _ ;pointer to a tagSECURITY_ATTRIBUTES structure
         )

   If $pipeHandle == -1 Then SetError(1)

   ;initial connect if non-blocking
   If $wait==0 Then
      If Not _NamedPipes_ConnectNamedPipe($pipeHandle) Then SetError(2)
   EndIf

   Return $pipeHandle

EndFunc


;arguments:
;   pipeName ... this name will be assigned to defaultPipe if no pipeHandle is specified
;   wait     ... blocking or non-blocking pipe mode
;   pipeHandle ... handle of the pipe to be used
;returns: string that has been received
;error codes:
;   1 ... buffer overflow;
;   2 ... create named pipe failed or provided handle is invalid
;   3 ... initial connect for a non-blocking named pipe failed
Func _pipeReceive($pipeName, $wait=Default, $pipeHandle = Default)

   If $wait == Default Then $wait=1
   If $pipeHandle == Default Then $pipeHandle = $_pipe_defaultPipeHandle

   Local $return=""
   Local $error=""

   If $pipeHandle == "" Then

      Local $pipePath = "\\.\pipe\"&$pipeName

      Local $sendBufferSize=4096
      Local $receiveBufferSize=4096

      ;create a new default pipe
      $_pipe_defaultPipeHandle = _NamedPipes_CreateNamedPipe( _
         $pipePath, _
         2, _ ;access-mode (0 inbound, 1 outbound, 2 duplex)
         2, _ ;flags
         0, _ ;security ACL flags (none)
         1, _ ;message mode (not byte-mode)
         1, _ ;read mode
         Not($wait), _ ;0 - Blocking mode is enabled, 1 - Nonblocking mode is enabled --> Not($wait)
         1, _ ;maximum number of instances that can be created for this pipe
         $receiveBufferSize, _ ;OutBufSize
         $sendBufferSize, _ ;InpBufSize
         5000, _ ;time out value, in milliseconds (Maximum time, in milliseconds, that can pass before a remote named pipe transfers information)
         0 _ ;pointer to a tagSECURITY_ATTRIBUTES structure
         )

      $pipeHandle = $_pipe_defaultPipeHandle

      If $pipeHandle == -1 Then
         ;_CreateNamedPipe() failed or provided handle invalid
         SetError(2)
         Return ""
      EndIf

      ;initial connect if non-blocking
      If $wait==0 Then
         If Not _NamedPipes_ConnectNamedPipe($pipeHandle) Then
            SetError(3)
            Return ""
         EndIf
      EndIf

   EndIf


   If $pipeHandle == -1 Then
      ;_CreateNamedPipe() failed or provided handle invalid
      SetError(2)
      Return ""
   EndIf

   If $wait==1 Then _NamedPipes_ConnectNamedPipe($pipeHandle)

   ;peek
   Local $cache=_NamedPipes_PeekNamedPipe($pipeHandle)

   Local $error=@error ;error: 0 ... data received, all fine; 230 no input; 109 ...  empty message received (?)

	;$cache[0]=_StringReverse($cache[0])
   $return=$cache[0]

;~       ConsoleWrite(@LF)
;~       ConsoleWrite($error&" (error); ")
;~       ConsoleWrite($cache[1]&" (Bytes read from the pipe); ")
;~       ConsoleWrite($cache[2]&" (Total bytes available to be read); ")
;~       ConsoleWrite($cache[3]&" (Bytes remaining to be read for this message); ")

   If $cache[2]-$cache[1]>0 Then
      ;pipe-buffer overflow
      SetError(1)
      Return ""
   EndIf

   ;if blocking pipe, simply disconnect and reconnect on next loop begin
   If $wait==1 Then
      _NamedPipes_DisconnectNamedPipe($pipeHandle)
   ;if non-blocking pipe, we need to flush the pipe by disconnecting and reconnecting
   ;to avoid unnecessary CPU consumption, we only do this if we actually received something and the buffer is not empty
   ElseIf $cache[0]<>"" Then
      _NamedPipes_DisconnectNamedPipe($pipeHandle)
      _NamedPipes_ConnectNamedPipe($pipeHandle)
   EndIf

   ;return
   Return $return

EndFunc