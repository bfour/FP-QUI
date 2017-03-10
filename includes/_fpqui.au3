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

#include <_fpquiRegister.au3>

#include <_commandLineInterpreter.au3>
#include <_stringReplaceVariables.au3>
#include <_run.au3>
#include <_pipe.au3>
#include <_gridDir.au3>
#include <_path.au3>

Global $FPQUI_CORENOTRUNNING_CODE       = 1
Global $FPQUI_REQUESTFAILED_CODE        = 2
Global $FPQUI_RESPONSEFAILED_CODE       = 4
Global $FPQUI_HANDLEDOESNOTEXIST_CODE   = 8
Global $FPQUI_RETURNPIPEISBLOCKING_CODE = 16
Global $FPQUI_INVALIDPARAMETERS_CODE    = 32
Global $FPQUI_INVALIDARGUMENTS_CODE     = 64

Global $FPQUI_DEFAULT_RETURNPIPE_NAME 	= "_fpqui"&@AutoItPID
Global $FPQUI_DEFAULT_RETURNPIPE_HANDLE = _pipeCreate($FPQUI_DEFAULT_RETURNPIPE_NAME, 0)


Global $FPQUI_DEBUGTIMER = TimerInit()
Func _fpquiDebug($string)
;~ 	ConsoleWrite(TimerDiff($FPQUI_DEBUGTIMER)&" - "&$string&@LF)
EndFunc


Func _fpqui($args, $handle=Default, $createIfNotVisible=Default, $errorHandling=Default, $returnPipeName=Default, $returnPipeHandle=Default)

	_fpquiDebug("_fpqui/")

	If $createIfNotVisible == Default Then $createIfNotVisible=1

   ;prepare error handling
   $errorHandling = _commandLineInterpreter($errorHandling, "coreNotRunning;corePath;requestFailed;sendMaxRetries;sendRetryPause;responseFailed;receiveMaxRetries;receiveRetryPause")

   For $i=0 To UBound($errorHandling)-1
      If $errorHandling[$i][1]=="" Then $errorHandling[$i][1]=Default
   Next

   Local $coreNotRunningHandling  = $errorHandling[0][1]
   Local $corePath                = $errorHandling[1][1]
   Local $requestFailedHandling   = $errorHandling[2][1]
   Local $sendMaxRetries          = $errorHandling[3][1]
   Local $sendRetryPause          = $errorHandling[4][1]
   Local $responseFailedHandling  = $errorHandling[5][1]
   Local $receiveMaxRetries       = $errorHandling[6][1]
   Local $receiveRetryPause       = $errorHandling[7][1]

	;prepare return pipe
	If $returnPipeName 		== Default Then $returnPipeName 	= $FPQUI_DEFAULT_RETURNPIPE_NAME
	If $returnPipeHandle 	== Default Then $returnPipeHandle 	= $FPQUI_DEFAULT_RETURNPIPE_HANDLE

   _fpquiDebug("_fpqui/prepare return pipe done: $returnPipeName="&$returnPipeName&" $returnPipeHandle="&$returnPipeHandle)

   ;check if handle is specified, if not create new QUI
   If $handle == Default Then
      _fpquiDebug("_fpqui/handle unspecified, creating new qui, $args="&$args)
      $handle = _fpquiComm($args, _
               $returnPipeName, $returnPipeHandle, _
               $corePath, $coreNotRunningHandling, _
               $sendMaxRetries, $sendRetryPause, $receiveBlocking, $receiveMaxRetries, $receiveRetryPause, _
               $requestFailedHandling, $responseFailedHandling)
      Return SetError(@error,0,$handle)
   EndIf

   ;handle is specified
   Local $argPrefix= "<winHandle>"& $handle &"</winHandle>"
   If $createIfNotVisible<>"" Then $argPrefix &= "<createIfNotVisible>"& $createIfNotVisible &"</createIfNotVisible>"
   $args = $argPrefix & $args

   _fpquiDebug("_fpqui/handle specified, updating, $argPrefix & $args="&$argPrefix & $args)
   $handle = _fpquiComm($args, $returnPipeName, $returnPipeHandle, $corePath, $coreNotRunningHandling, $sendMaxRetries, $sendRetryPause, $receiveMaxRetries, $receiveRetryPause, $requestFailedHandling, $responseFailedHandling)
   Return SetError(@error,0,$handle)

EndFunc

Func _fpquiDelete($handle, $errorHandling=Default, $returnPipeName=Default, $returnPipeHandle=Default, $corePath=Default)
   Local $return = _fpqui("<delete>"&$handle&"</delete>", Default, "", $errorHandling, $returnPipeName, $returnPipeHandle)
   Return SetError(@error, 0, $return)
EndFunc

; incrementally update QUI by specifying the sub-elements with their new values
; (rather than specifying the entire QUI with all elements, including the ones which value remains the same)
Func _fpquiUpdate($args, $handle, $errorHandling=Default, $returnPipeName=Default, $returnPipeHandle=Default, $corePath=Default)
   _fpquiDebug("_fpquiUpdate/$args="&$args&" $handle="&$handle)
   Local $return = _fpqui("<update>"&$args&"<winHandle>"&$handle&"</winHandle></update>", Default, "", $errorHandling, $returnPipeName, $returnPipeHandle)
   Return SetError(@error, 0, $return)
EndFunc

; this handles the communication with QUICore
; (includes handling of case where QUICore is not running)
Func _fpquiComm(ByRef $request, _
      $returnPipeName, $returnPipeHandle, _
		$corePath=Default, $coreNotRunningHandling=Default, _
		$sendMaxRetries=Default, $sendRetryPause=Default, $receiveMaxRetries=Default, $receiveRetryPause=Default, _
		$requestFailedHandling=Default, $responseFailedHandling=Default)

   _fpquiDebug("_fpquiComm/")
   _fpquiDebug("_fpquiComm/ $args="&$request)

   If $coreNotRunningHandling    == Default Then $coreNotRunningHandling = "tryAndReturn"
   If $sendMaxRetries            == Default Then $sendMaxRetries = 6
   If $sendRetryPause            == Default Then $sendRetryPause = 86
   If $receiveMaxRetries         == Default Then $receiveMaxRetries = 6
   If $receiveRetryPause         == Default Then $receiveRetryPause = 86
   If $requestFailedHandling     == Default Then $requestFailedHandling = "cmdLineFallbackAndReturn"
   If $responseFailedHandling    == Default Then $responseFailedHandling = "return"
   If $corePath                  <> Default Then
      If Not FileExists($corePath) Then
         SetError($FPQUI_INVALIDPARAMETERS_CODE)
         Return ""
      EndIf
   EndIf

   Local $pipeReplyCode = "<reply><pipe>"&$returnPipeName&"</pipe></reply>"

;~    _fpquiDebug("_fpquiComm/$sendMaxRetries="&$sendMaxRetries)
;~    _fpquiDebug("_fpquiComm/$sendRetryPause="&$sendRetryPause)
;~    _fpquiDebug("_fpquiComm/$responseFailedHandling="&$responseFailedHandling)
;~    _fpquiDebug("_fpquiComm/$requestFailedHandling="&$requestFailedHandling)
;~    _fpquiDebug("_fpquiComm/$coreNotRunningHandling="&$coreNotRunningHandling)
;~    _fpquiDebug("_fpquiComm/$receiveMaxRetries="&$receiveMaxRetries)
;~    _fpquiDebug("_fpquiComm/$receiveRetryPause="&$receiveRetryPause)
   _fpquiDebug("_fpquiComm/end prep ret pip")

	;initial send request
	If _pipeSend("FP-QUI", $request & $pipeReplyCode, 0) <> 1 Then ; note that $pipeReplyCode is appended as a suffix, thereby causing an override of any other reply-settings in $request

		_fpquiDebug("_fpquiComm/first pipe send failed")

		While 1==1

			;check if core is running
			If Not _NamedPipes_WaitNamedPipe("\\.\pipe\FP-QUI") Then

				_fpquiDebug("_fpquiComm/core pipe inexistent")

				; pipe does not exist --> not running
				Switch $coreNotRunningHandling

				Case "return"
					_fpquiDebug("_fpquiComm/first send req/Case return")
					Return SetError($FPQUI_CORENOTRUNNING_CODE, 0, "")

				Case "tryAndReturn"
					_fpquiDebug("_fpquiComm/first send req/Case tryAndReturn")
					_fpquiFindAndStartCore($corePath)
					If @error Then Return SetError($FPQUI_CORENOTRUNNING_CODE, 0, "")

				Case "tryAndPrompt"
					_fpquiDebug("_fpquiComm/first send req/Case tryAndPrompt")
					Local $answer = MsgBox (6+16, @ScriptName, "This program requires FP-QUICore to be running. FP-QUI can be downloaded at http://fp-qui.sourceforge.net/. You will be prompted for a path to FP-QUICore.exe. You may abort this by clicking on CANCEL, retry by clicking on RETRY or continue by clicking on CONTINUE.")

					Switch $answer

					Case 3 ;abort
						Return SetError($FPQUI_CORENOTRUNNING_CODE, 0, "")
					Case 4, 10 ;retry, try again
						ContinueLoop
					Case 11 ;continue
						Local $path = FileOpenDialog(@ScriptName, @ProgramFilesDir, "exe (*.exe)|all (*.*)", 3, "FP-QUI.exe")
						If @error Then
							Return SetError($FPQUI_CORENOTRUNNING_CODE, 0, "")
						Else
							_fpquiStartAndSaveCore($path)
							If @error Then Return SetError($FPQUI_CORENOTRUNNING_CODE, 0, "")
						EndIf

					EndSwitch

				EndSwitch

			EndIf

		ExitLoop
		WEnd


      ;further send requests
      _fpquiDebug("_fpquiComm/further send requests")
      If _pipeSend("FP-QUI", $request & $pipeReplyCode, $sendMaxRetries, $sendRetryPause) <> 1 Then

         _fpquiDebug("_fpquiComm/further send requests failed")

         ;request failed
         Switch $requestFailedHandling

         Case "return"
            _fpquiDebug("_fpquiComm/further send req/Case return")
            Return SetError(2,0,"") ;requestFailed

         Case "cmdLineFallbackAndReturn"
            _fpquiDebug("_fpquiComm/further send req/Case cmdLineFallbackAndReturn")
            Local $return = _fpquiCommandLineComm($request)
            If Not @error Then
               Return SetError(0,0,$return)
            Else
               Return SetError(2,0,"") ;requestFailed
            EndIf

         Case Else
            _fpquiDebug("_fpquiComm/further send req/Case else --> invalid param")
            Return SetError(32,0,"") ;invalid param

         EndSwitch

      EndIf

   EndIf

   _fpquiDebug("_fpquiComm/send request to core done")

   ; sending request via pipe went fine, receive the answer
   _fpquiDebug("_fpquiComm/receive")
   Local $recv = ""
   Local $responseFailed = False

   For $i = 0 To $receiveMaxRetries

	  _fpquiDebug("_fpquiComm/receive/cycle start")
		$recv = _pipeReceive($returnPipeName, 0, $returnPipeHandle)

	  If @error Then
		 _fpquiDebug("piperecv error="&@error)
		 $responseFailed = True
		 ExitLoop
	  EndIf

	  If $recv <> "" Then ExitLoop
	  Sleep($receiveRetryPause)

   Next

   $recv = StringStripWS($recv, 8)
   _fpquiDebug("_fpquiComm/received: $recv="&$recv&" $responseFailed="&$responseFailed)
   $recv = _commandLineInterpreter($recv, "reply")
   $recv = $recv[0][1]

;TODO implement better return-string validation
   If $responseFailed Or $recv == "" Then

      ;response failed
      Switch $responseFailedHandling
      Case "return"
         _fpquiDebug("_fpquiComm/response failed/Case return")
         Return SetError(4,0,"") ;response failed
      Case Else
         _fpquiDebug("_fpquiComm/response failed/Case else --> invalid param")
         Return SetError(4+32,0,"") ;response failed and invalid param
      EndSwitch

   EndIf

   ;everything's OK :-)
   Return SetError(0,0,$recv)

EndFunc


Func _fpquiFindAndStartCore($corePath=Default)

   If $corePath == Default Then
      ;get path
      Local $dir = _fpquiGetRegister("dir")
      Local $coreExe = _fpquiGetRegister("coreExe")
      $corePath = $dir&"\"&$coreExe
   EndIf

   Run($corePath)

   If @error And $corePath == Default Then
      ;try via grid-folder and usual path
      Run(_gridDir()&"\FP-QUI\FP-QUI.exe")
      If @error Then Return SetError(1,0,"")
   EndIf

   Return SetError(0,0,"")

EndFunc

Func _fpquiStartAndSaveCore($path)

   Run($path)

   If Not @error Then
      _fpquiRegister(False, _pathGetDir($path), "", _pathGetFileName($path))
   Else
      Return SetError(1,0,"")
   EndIf

EndFunc


Func _fpquiCommandLineComm($args)

   _fpquiDebug("_fpquiCommandLineComm/")

   ;get path
   Local $dir = _fpquiGetRegister("dir")
   Local $exe = _fpquiGetRegister("coreExe")
   Local $exePath = $dir&"\"&$exe

   Local $PID = Run($exePath&" "&$args&"<reply><stdout>1</stdout></reply>")

   If Not @error Then
      Local $return = _fpquiGetHandleFromPID($PID)
      If Not @error Then Return SetError(0, 0, $return)
   EndIf

   Return SetError(1,0,"")

EndFunc

Func _fpquiGetHandleFromPID($PID)

   Local $stdoutCache=""
   Local $stdoutBuffer=""
   Local $timer=TimerInit()

   Do
      $stdoutCache=StdoutRead($PID, 0)
      $stdoutBuffer&=$stdoutCache
      Sleep(500)
   Until $stdoutBuffer<>"" Or TimerDiff($timer)>20000

   Local $notificationHandle=StringStripWS($stdoutBuffer, 8)

   If $notificationHandle=="" Then
      SetError(1)
      Return 0
   Else
      Return $notificationHandle
   EndIf

EndFunc