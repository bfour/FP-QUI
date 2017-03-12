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

#cs ----------------------------------------------------------------------------

 If FP-QUI is started without any command line parameters, it shall run in the background and provide a dispatcher window.
 Invokes for new notifications can be send via a wm_copydata, using the same command line sytanx as for the executable itself.
 If FP-QUI is started with command line paramters and no other instance is running, FP-QUI shall run in the background, provide a dispatcher window and send the parameters to itself.

 exe --|
       |---> (FP-QUIInterface) ---> FP-QUI, dispatcher window, notification
 cmd --|


 In order for an external application to interact with an existing notification, you may provide a specific window-handle as a parameter (just insert <winHandle>[handle]</winHandle> anywhere in your CL params-string).
 When creating a new notification, the window handle is returned
   1.) via stdout
   2.) via wm_copydata


 features and commandLineDescriptors:

 0 <text>
 1 <delay>
 2 <textColor>
 3 <width>
 4 <height>
 5 <bkColor>
   0x****** color-code
   blue
   green
   red
   orange
   white
   black
   gray
   purple
   yellow
 6 <ico>
 7 <onClick>
   <any> ... on any click
   <left> ... on left mouse button
   <right> ... on right mouse button
   <includeButton> ... process clicks on button, too
   you may enclose commands in <shellOpen> (shell execute, verb: open) or <internal> (nested notification commands)
 8 <untilProcessExists>
 9 <untilProcessClose>
 10 <noDouble> ... if <>"", a notification will only be genereated if its signature (cmd-params) is unique. If it is not, the handle of the existing notification with the same signature will be returned (there can't be many, since they would all need at least noDouble<>"" to be equal,).
 11 <untilClick>
      <any> ... on any click
      <prim> ... on left mouse button
      <sec> ... on right mouse button
      <includeButton> ... process clicks on button, too
 12 <beep>
      <string> ... freq;duration|freq;duration|...
      <repeat> ... number of repetitions
      <pause> ... pause between repeats
      <shake> ... shake notification on beep
 13 <x>
 14 <y>
 15 <talk>
      [string] and nothing else
      <string>string</string>
      <repeat>number or "" for infinity</repeat>
      <pause>pause between talk</pause>
      use %text% as string to say what's enclosed in <text>

 16 <font>
 17 <fontSize>
 18 <trans> transparency
 19 <focus> grabs focus if <>""
 20 <audio> plays back an audio-file
      <path> ... path to sound file
      <repeat> ... number of repetitions
      <pause> ... pause between repeats
      <maxVol> ... maximize volume before playback
      <overwriteMute> ... overwrites mute
      <shake> ... shake notification on playback
 21 <replaceVar> if <>"" variables in all options will be replaced by _stringReplaceVariables
 22 <avi> path to show specific avi, empty to show no avi
 23 <run>
      <cmd> ... you may enclose a command in <shellOpen> (shell execute, verb: open) or <internal> (nested notification commands)
      <repeat>
      <pause>
 24 <progress> ... <>"" --> show bar
 25 <button>
      one button: <button><1><label>test</label><cmd>notepad</cmd></1></button>
      three buttons:    <button>
                     <a><label>test</label><cmd>notepad</cmd></a>
                     <d><label>test2</label><cmd>notepad</cmd></d>
                     <third><label>test3</label><cmd>notepad</cmd></third>
                  </button>
      you may enclose commands in <shellOpen> (shell execute, verb: open) or <internal> (nested notification commands)
 26 <winHandle>
 27 <reply>
      <wmcopydataHandle> set to <>"" and provide a valid window handle if you want a wmcopydata reply
      <stdout> set to <>"" if you want an stdout reply
 28 <dispatcherArea> ... overwrite config; [screen1|screen2|screen3 …|x,y,width,height]
 29 <startPos> ... overwrite config; [upperleft|upperright|lowerleft|lowerright|x,y] … relative to dispatcherArea
 30 <direction> ... overwrite config; [down,right|down,left|up,right|up,left] … relative to startPos
 31 <delete> ... deletes winHandle, all other arguments are ignored (.exe <delete>0x000000</delete>)
 32 <update> ... if you want to explicitly declare an update (else any request with <winHandle> <> "" will force an update of all attributes of this notification according to the parameters you provided) you may enclose your request in <update> (<update>[request]</update>)
 33 <createIfNotVisible> ...    <>"": If you update a notification declaring a winhandle and it's not visible this will automatically fall back to creating a new one. This will not work with update, since only part of the signature of the notification is provided (doesn't make sense).
                        =="" (default): no auto create
34 <system>
   multiple instructions are allowed at the same time:
   <menu>             ... <>"" --> show menu if not yet visible
   <reinitDefaults>    ... <>"" --> reinitialize defaults
   <reinitBehaviour>    ... <>"" --> reinitialize behaviour
   <reinitColors>       ... <>"" --> reinitialize colors

35 <noReposAfterHide>
   if <>"" -> inhibit reposition after this QUI has been hidden (by any event)
   increases performance and should be used if it is certain that other deletes will follow this one

   example: <update><winHandle>0x000000</winHandle><text>hello :-)</text></update> will change the text of 0x000000, but will leave all other attributes unchanged

#ce ----------------------------------------------------------------------------

#include <String.au3>
#include <WindowsConstants.au3>
#include <Constants.au3>
#Include <WinAPI.au3>
#Include <GuiAVI.au3>
#include <GuiButton.au3>
#include <GUIConstantsEx.au3>
#Include <Misc.au3>

#include <_log.au3>
#include <_commandLineInterpreter.au3>
#include <_talk.au3>
#include <_config.au3>
#include <_stringReplaceVariables.au3>
#include <_pipe.au3>
#include <_display.au3>
#include <_command.au3>

#include "modules\initializeAll.au3"
#include "modules\initializeErrorHandling.au3"
#include "modules\initializeBehaviour.au3"
#include "modules\initializeDefaults.au3"
#include "modules\initializeColors.au3"
#include "modules\initializeInterface.au3"
#include "modules\initializeNotificationsArrays.au3"
#include "modules\initializeDispatcherArea.au3"

#include "modules\positioning.au3"
#include "modules\supporter.au3"
#include "modules\executeCommand.au3"
#include "modules\register.au3"

#include "modules\doCheckLifetime.au3"
#include "modules\doAudio.au3"
#include "modules\doBeep.au3"
#include "modules\doTalk.au3"
#include "modules\doRun.au3"

#include "modules\forwardRequest.au3"
#include "modules\firstStartHandling.au3"

#include "modules\setBehaviour.au3"
#include "modules\mainMenu.au3"
#include "modules\trayMainMenu.au3"

;+++ Alex Kuryakin
#include <wmCopyData.au3>
;--- Alex Kuryakin

OnAutoItExitRegister("_exit")
Opt("GUIOnEventMode",1)

Global $debug = 1
Global $debugTimer = TimerInit()
Global $debugTimerMemory = $debugTimer
Func _debug($string)
   If $debug==1 Then
      Local $diff = TimerDiff($debugTimer)
      ConsoleWrite(Round($diff,2)&" - "&Round($diff-$debugTimerMemory,2)&" - "&$string&@LF)
      $debugTimerMemory = $diff
    EndIf
EndFunc

_start()

Func _start()

   _debug("start")

   ;if another instance is already up and running forward the CmdLine
   If _Singleton("FP-QUICore", 1) == 0 Then
      ; another instance is likely to be existent
      _debug("another instance exists")

      _initializeBehaviour()
      _initializeErrorHandling()

      ;check if maxInstances is reached
      Local $procList = ProcessList(@ScriptName)
      If $procList[0][0] > $behaviourMaxInstances Then
         _logError("maximum number of instances reached: "&$procList[0][0], 0, 0, $errorLog,$errorLogDir,$errorLogFile,$errorLogMaxNumberOfLines)
         Exit
      EndIf

      If $CmdLineRaw<>"" Then
         _debug("command line is not empty, attempting to forward request")
         _forwardRequest($CmdLineRaw)
         _debug("forwardRequest finished")
      Else

         _debug("command line is empty")

         If $behaviourShowMenuOnNoArguments==1 Then
            _debug("calling mainMenu")
            _mainMenu(1)
            _debug("calling mainMenu done")
         Else
            Exit
         EndIf

      EndIf

      Exit

   Else ;there is no other instance

      _debug("singleton returns not 0")

      _initializeAll()
      _handleFirstStart($behaviourFirstStart, $behaviourshowFirstStartGUI)
      If $behaviourAutoRegister==1 Then _register(0, Default, Default, @ScriptName)
      If @error<>0 Then _logError("Failed to add registry entry.",0,$errorBroadCast,$errorLog,$errorLogDir,$errorLogFile,$errorLogMaxNumberOfLines)
      _generateDispatcherWindow()
      _trayMainMenu()

;~       DllCall("psapi.dll","int","EmptyWorkingSet","long",-1) ;reduce memory consumption

      If $behaviourShowMenuOnFirstStart==1 Then _mainMenu()
      If $CmdLineRaw<>"" Then _processRequest($CmdLineRaw)

      _main()

   EndIf

EndFunc



Func _main()

   _debug("main")

   Local $loopPause       = 400
   Local $request         = ""
   Local $cycleCounter    = 0

    ;+++ Alex Kuryakin
   wmCopyDataInit()
    ;--- Alex Kuryakin

   While 1

;~ 	  _debug(@LF&@LF&"cycle start")

      ; <retrieve>
      $cycleCounter += 1
	  $request=""

	  $request=_pipeReceive("FP-QUI",0)
	  If $request=="" Then $request=_pipeReceive("FP-QUI",0) ; TODO fix: *every second recv returns "" regardless of stuff being in the queue

        ;+++ Alex Kuryakin
	  If $request=="" Then
         If $wmCopyDataFifoCount > 0 Then
			_debug("wmCopyDataFifoGet()")
            $request = wmCopyDataFifoGet()
         EndIf
	  EndIf
        ;--- Alex Kuryakin

      If $request<>"" Then _processRequest($request)

	  ; in 9 of 10 cycles, if we have received a request, skip processing
	  ; of existing notifications and be ready for new request immediately
      If Mod($cycleCounter, 10) <> 0 And $request <> "" Then ContinueLoop

      ; </retrieve>

      ; <process>

      For $i=UBound($notificationsHandles)-1 To 1 Step -1
         _doCheckLifetime($i) ; delay, until etc.
         _doRun($i)
         _doAudio($i)
         _doBeep($i)
         _doTalk($i)
      Next

      _processNotificationsDeleteRequests()

      ;adjust loopPause, based on request and existing notifications
      If UBound($notificationsHandles)<=2 And $request=="" Then
         $loopPause = 400
      ElseIf UBound($notificationsHandles)<=4 And $request=="" Then
         $loopPause = 90
      ElseIf UBound($notificationsHandles)>4 And $request=="" Then
         $loopPause = 60
	  ElseIf UBound($notificationsHandles)>10 And $request=="" Then
		 $loopPause = 30
      Else
         $loopPause=1
      EndIf

      Sleep($loopPause)

      ; </process>

       ; <check display update>
;~ ConsoleWrite($cycleCounter)
      If Mod($cycleCounter, 30) == 0 Then
          Local $currentHash = _displayGetPosHash()
         Local $currentTaskbarHash = _taskbarGetPosHash()
;~ _debug("last taskbhash: "&   $currentTaskbarHash)
         If $lastDisplayHash <> $currentHash Or $lastTaskbarHash <> $currentTaskbarHash Then
            $lastDisplayHash = $currentHash
            $lastTaskbarHash = $currentTaskbarHash
            $dispatcherArea = _getDispatcherArea()
            _debug("display changed, new disp area: "&$dispatcherArea[0]&","&$dispatcherArea[1]&","&$dispatcherArea[2]&","&$dispatcherArea[3]&@LF)
            WinMove($dispatcherWindow, "", $dispatcherArea[0], $dispatcherArea[1], $dispatcherArea[2], $dispatcherArea[3], 1)
            _repositionAll()
         EndIf
       EndIf

      ; </check display update>

   WEnd

EndFunc


Func _processRequest($requestString)

   _debug("process request: "&$requestString)

   Local $options=_commandLineInterpreter($requestString,$cmdLineDescriptorRequest)
   _debug("process request: options parse end")

   ;replaceVar
;~    $options=_replaceVar($options)
   _replaceVar($options) ; by ref!
   _debug("process request: options replace var end")

   ;check requestString
   Local $requestArray=_commandLineInterpreter($requestString)
   _debug("process request: requestArray build end")
   Local $validDescriptors=StringSplit($cmdLineDescriptorRequest,";",3)
   Local $valid=0
   Local $invalidDescriptors=""

   For $i=0 To UBound($requestArray)-1

      $valid=0

      For $j=0 To UBound($validDescriptors)-1
         If $validDescriptors[$j]=$requestArray[$i][0] Then
            $valid=1
            ExitLoop
         EndIf
      Next

      If $valid==0 Then $invalidDescriptors&=$requestArray[$i][0]&";"

   Next

   If $invalidDescriptors<>"" Then _logError("invalid descriptor(s): "&$invalidDescriptors,$errorInteractive,$errorBroadcast,$errorLog,$errorLogDir,$errorLogFile,$errorLogMaxNumberOfLines)

   _debug("process request: descriptor validation end")

   ;go
   Local $reply=""

   If $options[32][1]<>"" Then ; update

      _debug("process request: update")

      ; we simply append the update without the "update" tags to the current requestString (options), to force an overwrite of the attributes to be updated

      $winHandle = _commandLineInterpreter($options[32][1],"winHandle")
      $winHandle = $winHandle[0][1]

;TODO: maybe we should return this error message via stdout or wmcopydata if applicable
      If $winHandle == "" Then
         _logError('You did not specify a winHandle within your update request: "'&$options[32][1]&'"',$errorInteractive,$errorBroadcast,$errorLog,$errorLogDir,$errorLogFile,$errorLogMaxNumberOfLines,1)
         SetError(1)
         Return ""
      EndIf

      Local $ID=_handleToID($winHandle)

      Local $currentRequestArray[UBound($notificationsOptions,2)]
      For $i=0 To UBound($currentRequestArray)-1
         $currentRequestArray[$i]=$notificationsOptions[$ID][$i]
      Next

      Local $currentRequestString=_optionsArrayToString($currentRequestArray)

      $requestString = _commandLineInterpreter($requestString,"update")
      $requestString = $requestString[0][1]

	  _debug($currentRequestString &"#########"& $requestString&@LF)

      _processRequest($currentRequestString & $requestString)

      ;this time we do not want to send a reply (this has already been done in the function-call above if specified)
      $options[27][1]=""

   ElseIf $options[31][1]<>"" Then ; delete

      _debug("process request: delete")

      Local $ID=_handleToID($options[31][1])
      If Not @error Then _hideNotification($ID)

      $reply=$options[31][1]

   ElseIf $options[26][1] <> "" Then ;winHandle<>"" --> update notif

	  _debug("process request/update winhandle specified/start")

      ;if this notification is visible (and exists) simply do an update
      If _notificationVisible($options[26][1])==1 Then
         _updateNotification($options)
         $reply=$options[26][1]
      ;else
      ElseIf $options[33][1]<>"" Then ;createIfNotVisible
         Local $return=_processGenerateNotificationRequest($requestString,$options)
         $reply=$notificationsHandles[$return[0]][0] ;return[0] ... ID
      EndIf

;~ _debug("process request/update winhandle specified/end")

   ElseIf $options[34][1]<>"" Then ; system

      Local $instructions = _commandLineInterpreter($options[34][1])

      For $j=0 To UBound($instructions)-1

         Switch $instructions[$j][0]

         Case "menu"
            If $instructions[$j][1] <> "" Then _mainMenu(0)
         Case "reinitDefaults"
            If $instructions[$j][1] <> "" Then _initializeDefaults()
         Case "reinitBehaviour"
            If $instructions[$j][1] <> "" Then _initializeBehaviour()
         Case "reinitColors"
            If $instructions[$j][1] <> "" Then _initializeColors()
         EndSwitch

         $reply = "ACK"

      Next

   Else ;generate notif

      Local $return=_processGenerateNotificationRequest($requestString,$options)
      $reply=$notificationsHandles[$return[0]][0] ;return[0] ... ID

   EndIf

   ; reply (even if no notif has been created because it's not unique but has to be)
   $reply = "<reply>"&$reply&"</reply>"
   Local $replyInstructions = _commandLineInterpreter($options[27][1], "pipe;wmcopydataHandle;stdout")
   Local $replyPipe         = $replyInstructions[0][1]
   Local $replyCDHandle     = $replyInstructions[1][1]
   Local $replyStdout       = $replyInstructions[2][1]

	  ;via pipe
	If $replyPipe<>"" Then
		;try once (we have to be quick, this is one single thread)
		If _pipeSend($replyPipe,$reply,0) <> 1 Then
		    _debug("process request/reply failed to pipe "&$replyPipe&" with reply "&$reply&", calling intracom")
			;if that doesn't work, delegate this task to another process (this one shall not be interrupted)
			Local $return=_runEx(@ScriptDir&"\FP-QUIIntracom.exe <recip>"&$replyPipe&"</recip><msg>"&$reply&"</msg><errorMode>log</errorMode><errorMsg>FP-QUIIntracom failed to handle a pipe transaction: $replyPipe="&$replyPipe&"; $reply="&$reply&"</errorMsg><retryPause>1000</retryPause><maxRetries>20</maxRetries>")
		EndIf
	EndIf

      ; via wmcdhandle
   If $replyCDHandle<>"" Then
      ; try once (we have to be quick, this is one single thread)
      If wmCopyDataSend($replyCDHandle, $reply) <> 1 Then
         ;if that doesn't work, delegate this task to another process (this one shall not be interrupted)
         Local $return=_runEx(@ScriptDir&"\FP-QUIIntracom.exe <recip>"&$replyCDHandle&"</recip><msg>"&$reply&"</msg><errorMode>log</errorMode><errorMsg>FP-QUIIntracom failed to handle a wmcopydata transaction: $replyCDHandle="&$replyCDHandle&"; $reply="&$reply&"</errorMsg><retryPause>1000</retryPause><maxRetries>20</maxRetries>")
      EndIf
   EndIf

      ;via stdout
   If $replyStdout <> "" Then ConsoleWrite($reply)

EndFunc

;interprets a request for generating a new notification (for instance, checks whether the signature exists and is relevant)
;in:  $requestString,$options
;out: [0: ID of the newly created or already existing notification, 1: 1...already existed 0...was unique]
Func _processGenerateNotificationRequest($requestString,$options)

   _debug("process request/generate")
   Local $returnArray[2]
   Local $noDouble=$options[10][1]
   Local $ID=-1

   If $noDouble<>"" Then $ID=_notifGetDouble($options)
;~ _debug("process request/generate/_notifGetDouble end")

   ;if no need for not-double or no double found
   If $noDouble=="" Or $ID==-1 Then

      $ID=_generateNotification()
      _updateNotification($options,$notificationsHandles[$ID][0])
      _showNotification($ID)

      $returnArray[1] = 0 ;did not already exist

   Else
      $returnArray[1] = 1
   EndIf

   $returnArray[0] = $ID

;~ _debug("process request/generate/generate end, result: $returnArray[0]="&$returnArray[0]&", $returnArray[1]="&$returnArray[1])
   Return $returnArray

EndFunc

Func _GUIPrimaryUpClick()
   _GUIClick("primaryUp",@GUI_WinHandle)
EndFunc

Func _GUISecondaryUpClick()
   _GUIClick("secondaryUp",@GUI_WinHandle)
EndFunc

Func _GUIClick($type,$winHandle)

;~ _debug("GUIClick: $type="&$type&" $winHandle="&$winHandle)
;~ _debug("notif handles array ubound="&UBound($notificationsHandles))
;~ _debug("notif options array ubound="&UBound($notificationsOptions))

   Local $mousePos=GUIGetCursorInfo($winHandle)
   Local $ID=_handleToID($winHandle)

   Local $buttonClicked=0

   If $type=="primaryUp" And $notificationsHandles[$ID][5]<>"" Then

      ;buttons
      Local $buttons=_commandLineInterpreter($notificationsHandles[$ID][5])
      Local $buttonsLocations[UBound($buttons)][4]
      Local $buttonClicked=0

      For $i=0 To UBound($buttons)-1

         ;if mouse was over button, the button has been clicked
         If $buttons[$i][1]==$mousePos[4] Then

            $buttonClicked=1

            Local $cmd=_commandLineInterpreter($notificationsOptions[$ID][25],$buttons[$i][0])
            $cmd=_commandLineInterpreter($cmd[0][1],"cmd")
            $cmd=$cmd[0][1]

            _executeCommand($cmd)

         EndIf

      Next

   EndIf



   Local $onClick=_commandLineInterpreter($notificationsOptions[$ID][7],"any;prim;sec;includeButton")
   Local $onClickButtonClicked=($buttonClicked==1 And $onClick[3][1]=="") ;if 0, onClick "thinks" button was not pressed

   ;onClick any
   If    ($onClick[0][1]<>"" And $onClickButtonClicked==False) Then _executeCommand($onClick[0][1])

   ;onClick prim
   If    ($type=="primaryUp" And $onClick[1][1]<>"" And $onClickButtonClicked==False) Then _executeCommand($onClick[1][1])

   ;onclick sec
   If    ($type=="secondaryUp" And $onClick[2][1]<>"" And $onClickButtonClicked==False) Then _executeCommand($onClick[2][1])



   Local $untilClick=_commandLineInterpreter($notificationsOptions[$ID][11],"any;prim;sec;includeButton")
   Local $untilClickButtonClicked=($buttonClicked==1 And $untilClick[3][1]=="") ;if 0, untilClick "thinks" button was not pressed

;~    If    (($untilClick[0][1]<>"" And $untilClickButtonClicked==False) _
;~       Or _
;~       ($type=="primaryUp" And $untilClick[1][1]<>"" And $untilClickButtonClicked==False) _
;~       Or _
;~       ($type=="secondaryUp" And $untilClick[2][1]<>"" And $untilClickButtonClicked==False)) _
;~    Then

   If    (($untilClick[0][1]<>"" And $untilClickButtonClicked==False) _
      Or _
      ($type=="primaryUp" And $untilClick[1][1]<>"" And $untilClickButtonClicked==False) _
      Or _
      ($type=="secondaryUp" And $untilClickButtonClicked==False)) _ ;always close on secondary (override)
   Then
      _hideNotification($ID)
   EndIf


EndFunc

Func _generateDispatcherWindow()

    _debug("generating dispatcher window:" &$dispatcherArea[0]&","&$dispatcherArea[1]&","&$dispatcherArea[2]&","&$dispatcherArea[3])
   Global $dispatcherWindow=GUICreate($dispatcherWindowTitle,$dispatcherArea[2],$dispatcherArea[3],$dispatcherArea[0],$dispatcherArea[1])

   ;dummy button, used for determining needed width
   Global $dummyButton=GUICtrlCreateButton("",0,0,0,0)

;~ WinSetTrans($dispatcherWindow,"",200)
;~ GUISetState()

EndFunc

;generates window and empty array-entrys (-->ID)
;return: ID
Func _generateNotification()

   ;register notification
   ReDim $notificationsHandles[UBound($notificationsHandles)+1][$numberOfHandles]
   ReDim $notificationsOptions[UBound($notificationsOptions)+1][$numberOfOptions]
   ReDim $notificationsOptionsData[UBound($notificationsOptionsData)+1][$numberOfOptions]

   Local $ID=UBound($notificationsHandles)-1


   ;set this startpos to opposite corner of start pos (ie: bottomright --> topleft)
   Local $x=0
   Local $y=0

   If StringInStr($startPos,"left")<>0 Then
      $x=$dispatcherArea[2] ;dispatcher width (right)
   ElseIf StringInStr($startPos,"right")<>0 Then
      $x=0
   EndIf

   If StringInStr($startPos,"top")<>0 Then
      $y=$dispatcherArea[3] ;dispatcher height (bottom)
   ElseIf StringInStr($startPos,"bottom")<>0 Then
      $y=0
   EndIf


   ;generate GUI
   Local $winHandle=GUICreate("FP-QUI/child_"&$ID,$x,$y,0,0,-2147483648,136,$dispatcherWindow)
   WinSetTitle($winHandle,"","FP-QUI/child_"&$winHandle)

   ;onEvent
   GUISetOnEvent($GUI_EVENT_PRIMARYUP,"_GUIPrimaryUpClick",$winHandle)
   GUISetOnEvent($GUI_EVENT_SECONDARYUP,"_GUISecondaryUpClick",$winHandle)

   ;save GUI handle
   $notificationsHandles[$ID][0]=$winHandle

   Return $ID

EndFunc

Func _updateNotification($options,$handle=Default)

_debug("start update func")

   ;which notification?
   Local $winHandle
   If $handle==Default Then
      $winHandle=$options[26][1]
   Else
      $winHandle=$handle
   EndIf

   Local $ID=_handleToID($winHandle)

   ; replace myHandle
   _replaceMyHandle($options, $winHandle) ; by ref!

   If $ID<>0 Then ;else invalid handle --> invalid ID

      ;preprocessing
      ;set default icon if qui would be completely empty
      If $options[0][1] == "" And $options[6][1] == "" And $options[24][1] == "" And $options[25][1] == "" And $options[22][1] == "" Then $options[6][1] = $defaultIcon



_debug("store options start")

      ;locally store options
      ;text
      Local $text=$options[0][1]

      ;delay
      Local $delay=$options[1][1]

      ;textColor
      Local $textColor
      If $options[2][1]=="" Then
         $textColor=$defaultTextColor
      Else
         $textColor=$options[2][1]
      EndIf

      ;height
      Local $height=$options[4][1]

      ;bkColor
      Local $bkColor
      If $options[5][1]=="" Then
         $bkColor=$defaultBkColor
      Else
         $bkColor=$options[5][1]
      EndIf

      Switch $options[5][1]

         Case "blue"
            $bkColor=$colorsBlue
         Case "green"
            $bkColor=$colorsGreen
         Case "red"
            $bkColor=$colorsRed
         Case "orange"
            $bkColor=$colorsOrange
         Case "white"
            $bkColor=$colorsWhite
         Case "black"
            $bkColor=$colorsBlack
         Case "gray"
            $bkColor=$colorsGray
         Case "purple"
            $bkColor=$colorsPurple
         Case "yellow"
            $bkColor=$colorsYellow

      EndSwitch

      ;if bkColor is still invalid, set 0x98C9FA
      If StringRegExp($bkColor,"0x[0123456789ABCDEFabcdef]{1,6}")==0 Then $bkColor=0x98C9FA


      ;ico
      Local $icon=$options[6][1]

      ;onClick
      Local $onClick=$options[7][1]

      ;untilProcessExists
      Local $untilProcessExists=$options[8][1]

      ;untilProcessClose
      Local $untilProcessClose=$options[9][1]

      ;untilProcessTimeout
      Local $untilProcessTimeout=$options[10][1]

      ;untilClickTop
      Local $untilClickTop=$options[11][1]

      ;untilClickBottom
      Local $untilClickBottom=$options[12][1]

      ;talk
      Local $talk=$options[15][1]

      ;font
      Local $font
      If $options[16][1]=="" Then
         $font=$defaultFont
      Else
         $font=$options[16][1]
      EndIf

      ;fontSize
      Local $fontSize
      If $options[17][1]=="" Then
         $fontSize=$defaultFontSize
      Else
         $fontSize=$options[17][1]
      EndIf

      ;trans
      Local $trans
      If $options[18][1]=="" Then
         $trans=$defaultTrans
      Else
         $trans=$options[18][1]
      EndIf

      ;focus
      Local $focus=$options[19][1]

      ;audio
      Local $audio=$options[20][1]

      ;beep
      Local $beep=$options[12][1]

      ;avi
      Local $avi=$options[22][1]

      ;run
      Local $run=$options[23][1]

      ;progress
      Local $progress=$options[24][1]

      ;button
      Local $button=$options[25][1]


_debug("store options end, prepare handles start")

      ;prepare handles

      ;notificationsHandles: [0: GUI-Handle, 1: ico-Handle, 2: avi-Handle, 3: label-Handle, 4: progress-Handle, 5: button-handles (<1>handle</1> etc.)

      Local $labelHandle=""
      If $text<>"" Then
         If $notificationsHandles[$ID][3]=="" Then
            $labelHandle=GUICtrlCreateLabel("",0,0,0,0,0x0201)
         Else
            $labelHandle=$notificationsHandles[$ID][3]
         EndIf
      Else
         If $notificationsHandles[$ID][3]<>"" Then
            GUICtrlDelete($notificationsHandles[$ID][3])
         EndIf
      EndIf

      Local $iconHandle=""
      If $icon<>"" Then
         If $notificationsHandles[$ID][1]=="" Then
            $iconHandle=GUICtrlCreateIcon("",-1,0,0,0,0)
         Else
            $iconHandle=$notificationsHandles[$ID][1]
         EndIf
      Else
         If $notificationsHandles[$ID][1]<>"" Then
            GUICtrlDelete($notificationsHandles[$ID][1])
         EndIf
      EndIf

      Local $aviHandle=""
      If $avi<>"" Then
         If $notificationsHandles[$ID][2]=="" Then
            $aviHandle=GUICtrlCreateAvi($avi,0,0,0,0,0)
            _GUICtrlAVI_Play($aviHandle)
         Else
            $aviHandle=$notificationsHandles[$ID][2]
         EndIf
      Else
         If $notificationsHandles[$ID][2]<>"" Then
            GUICtrlDelete($notificationsHandles[$ID][2])
         EndIf
      EndIf

      Local $progressHandle=""
      If $progress<>"" Then
         If $notificationsHandles[$ID][4]=="" Then
            $progressHandle=GUICtrlCreateProgress(0,0,0,0,1)
         Else
            $progressHandle=$notificationsHandles[$ID][4]
         EndIf
      Else
         If $notificationsHandles[$ID][4]<>"" Then
            GUICtrlDelete($notificationsHandles[$ID][4])
         EndIf
      EndIf

      Local $buttonHandles=""
      If $notificationsOptions[$ID][25]<>$button Then

         ;delete existing buttons
         Local $existingButtons=_commandLineInterpreter($notificationsHandles[$ID][5])

         For $i=0 To UBound($existingButtons)-1
            GUICtrlDelete($existingButtons[$i][1])
         Next

         Local $newButtons=_commandLineInterpreter($button)

         For $i=0 To UBound($newButtons)-1

            Local $newButtonsOptions=_commandLineInterpreter($newButtons[$i][1],"label;font;fontSize")

            Local $buttonHandle=GUICtrlCreateButton($newButtonsOptions[0][1],0,0,0,0,$BS_NOTIFY+$BS_MULTILINE)
            GUICtrlSetFont($buttonHandle,$newButtonsOptions[2][1],"","",$newButtonsOptions[1][1])

            GUICtrlSetResizing($buttonHandle, $GUI_DOCKALL)

            $buttonHandles&="<"&$newButtons[$i][0]&">"&$buttonHandle&"</"&$newButtons[$i][0]&">"

         Next

      Else
         $buttonHandles=$notificationsHandles[$ID][5]
      EndIf



      ;store handles
      ;[0: GUI-Handle, 1: ico-Handle, 2: avi-Handle, 3: label-Handle, 4: progress-Handle, 5: button-handles (<1>handle</1> etc.)
      $notificationsHandles[$ID][1]=$iconHandle
      $notificationsHandles[$ID][2]=$aviHandle
      $notificationsHandles[$ID][3]=$labelHandle
      $notificationsHandles[$ID][4]=$progressHandle
      $notificationsHandles[$ID][5]=$buttonHandles



_debug("prep handles end, set size and pos start")
      ;set size and position

         ;sub-globals
      Local $spacing = 4
      Local $cursor = $spacing ;think of it as a cursor, its position shows where a new GUI-item (button etc.) can be inserted (already includes a border between it and the prev item)
;~       Local $maxY = $spacing ;"lowest" y-point (highest y-value, right after the lowest GUI-item)

      Local $labelSize = _getOptimalButtonSize($text, $font, $fontSize)

      ;icon, aci etc. need to know the height, they are processed before label etc. is processed, which, however, determines the height
      If $height<>"" Then ;if height is specified, use this value
         ;already declared
      Else ;else use labelheight
         $height = $labelSize[1]
      EndIf

      ;ensure minimum height
      If $height < $defaultIconAviSize+2*$spacing   Then $height = $defaultIconAviSize+2*$spacing
      If $height < $labelSize[1]                Then $height = $labelSize[1]


         ;icon
      If $icon <> "" Then
_debug("icon")

         Local $iconWidth = $defaultIconAviSize
         Local $iconHeight = $defaultIconAviSize
         Local $iconX = $cursor
         Local $iconY = ($height/2)-($iconHeight/2)

         GUICtrlSetPos($iconHandle,$iconX,$iconY,$iconWidth,$iconHeight)

         $cursor += $iconWidth + $spacing
;~          If $iconY + $iconHeight > $maxY Then $maxY = $iconY + $iconHeight

      EndIf


         ;avi
      If $avi <> "" Then

         Local $aviWidth=$defaultIconAviSize
         Local $aviHeight=$defaultIconAviSize
         Local $aviX=$cursor
         Local $aviY=($height/2)-($aviHeight/2)

         GUICtrlSetPos($aviHandle,$aviX,$aviY,$aviWidth,$aviHeight)

         $cursor += $aviWidth + $spacing
;~          If $aviY + $aviHeight > $maxY Then $maxY = $aviY + $aviHeight

      EndIf


         ;label
      If $text<>"" Then

         Local $labelWidth = $labelSize[0] + 50
         Local $labelHeight=$height
         Local $labelX=$cursor
         Local $labelY=0

         If $progress<>"" Then $labelHeight-=15

         GUICtrlSetPos($labelHandle,$labelX,$labelY,$labelWidth,$labelHeight)

         $cursor += $labelWidth + $spacing
;~          If $labelY + $labelHeight > $maxY Then $maxY = $labelY + $labelHeight

      EndIf


         ;progress
      If $progress <> "" Then

         Local $progressWidth
         Local $progressHeight
         Local $progressX
         Local $progressY

         If $text <> "" Then ;text is set

            $progressWidth = $labelWidth
            $progressHeight = $height - ($labelHeight + $spacing)
            $progressX = $labelX
            $progressY = $labelY + $labelHeight

         Else ;no label is set

            $progressWidth = $defaultWidth - 2*$spacing
            $progressHeight = $height - 2*$spacing
            $progressX = $cursor
            $progressY = $spacing

            $cursor += $progressWidth + $spacing
;~             If $progressY + $progressHeight > $maxY Then $maxY = $progressY + $progressHeight

         EndIf

         GUICtrlSetPos($progressHandle,$progressX,$progressY,$progressWidth,$progressHeight)

      EndIf


         ;buttons
      If $button<>"" Then

         Local $buttonHeight = $height - 2*$spacing
         Local $buttonY = $spacing

         ;get buttons
         $buttonsArray = _commandLineInterpreter($button)
         $buttonsHandlesArray = _commandLineInterpreter($buttonHandles)


         ;position each button and update cursor
         For $i=0 To UBound($buttonsArray)-1

            Local $buttonOptions = _commandLineInterpreter($buttonsArray[$i][1],"label;font;fontSize")
            Local $idealButtonSize=_getOptimalButtonSize($buttonOptions[0][1], $buttonOptions[1][1], $buttonOptions[2][1])

            Local $buttonWidth = $idealButtonSize[0] + 2*$spacing
            GUICtrlSetPos($buttonsHandlesArray[$i][1], $cursor, $buttonY, $buttonWidth, $buttonHeight)

            $cursor += $buttonWidth + $spacing

         Next

;~          If $buttonY + $buttonHeight > $maxY Then $maxY = $buttonY + $buttonHeight

      EndIf


         ;post-calculations
            ;width
      Local $width
      If $notificationsOptions[$ID][3] <> "" Then ;if width is specified --> override

         $width = $notificationsOptions[$ID][3]

      Else ;else

         ;set to cursor
         $width = $cursor

         ;if we are out of dispatcher-bounds and text is not empty and font is not specified, try to decrease the font to minimum
         If $width>$dispatcherArea[2] And $text<>"" And $options[17][1]=="" Then

            Local $newLabelWidth
            Local $diff

            ;decrease font size by one until minimum is reached
            For $i=$fontSize To $defaultMinimumFontSize Step -1

               ;calc new label size
               $newLabelWidth=_getOptimalButtonSize($text, $font, $i)
               $diff = $labelWidth - $newLabelWidth[0]
               ;if the current width minus the difference is small enough or we reached minFontSize--> set and break
               If ($width - $diff) <= $dispatcherArea[2] Or $i==$defaultMinimumFontSize Then

                  $width = $width - $diff

                  ;set label
                  $fontSize = $i
                  GUICtrlSetPos($labelHandle,$labelX,$labelY,$newLabelWidth[0])

                  ;set progress if necessary
                  If $progress<>"" Then GUICtrlSetPos($progressHandle, $labelX, $labelY, $newLabelWidth[0])

                  ;set buttons if necessary
                  If $button<>"" Then
                     $cursor = $labelX + $newLabelWidth[0] + $spacing
                     For $i=0 To UBound($buttonsArray)-1
                        Local $buttonOptions = _commandLineInterpreter($buttonsArray[$i][1],"label;font;fontSize")
                        Local $idealButtonSize=_getOptimalButtonSize($buttonOptions[0][1], $buttonOptions[1][1], $buttonOptions[2][1])
                        Local $buttonWidth = $idealButtonSize[0] + 2*$spacing
                        GUICtrlSetPos($buttonsHandlesArray[$i][1], $cursor, $buttonY, $buttonWidth)
                        $cursor += $buttonWidth + $spacing
                     Next
                  EndIf

                  ExitLoop

               EndIf

            Next

         EndIf

      EndIf

         ;window
      _setSize($ID, $width, $height)
      _setOptimalPos($ID)

      ;set data

         ;window
      If $bkColor<>$notificationsOptions[$ID][5] Then
         GUISetBkColor($bkColor,$notificationsHandles[$ID][0])
         ;force redraw (hotfix)
         _WinAPI_RedrawWindow($notificationsHandles[$ID][0])
      EndIf

         ;trans
      If $trans<>$notificationsOptions[$ID][18] Then WinSetTrans($notificationsHandles[$ID][0],"",$trans)

         ;label
      If $labelHandle<>"" And ($text<>$notificationsOptions[$ID][0] Or $textColor<>$notificationsOptions[$ID][2] Or $font<>$notificationsOptions[$ID][16]) Then
         GUICtrlSetData($labelHandle,$text)
         GUICtrlSetColor($labelHandle,$textColor)
         GUICtrlSetFont($labelHandle,$fontSize,"","",$font)
      EndIf

         ;icon
      If $iconHandle<>"" And $icon<>$notificationsOptions[$ID][6] Then GUICtrlSetImage($iconHandle,$icon)

         ;avi
      If $avi<>$notificationsOptions[$ID][22] And $aviHandle<>"" Then
         _GUICtrlAVI_Close($aviHandle)
         _GUICtrlAVI_Open($aviHandle,$avi)
         _GUICtrlAVI_Play($aviHandle)
      EndIf

         ;progress
      If $progress<>$notificationsOptions[$ID][24] And $progressHandle<>"" Then GUICtrlSetData($progressHandle,$progress)

_debug("set data end, spec func start")

      ;special functions

      ;always reset the timer on update
         ;delay
;~       If $delay<>$notificationsOptions[$ID][1] Then
         ;reset timer
         $notificationsOptionsData[$ID][1]=TimerInit()
;~       EndIf

         ;talk
;~       If $talk<>$notificationsOptions[$ID][15] Then
;~          If $talk<>"" Then _runEx('"'&@ScriptDir&'\FP-QUITalk.exe" '&$talk)
;~       EndIf

         ;focus
      If $focus<>$notificationsOptions[$ID][19] Then
         If $focus<>"" Then WinActivate($notificationsHandles[$ID][0])
      EndIf

         ;audio
      If $audio<>$notificationsOptions[$ID][20] Then
         ;reset data
         $notificationsOptionsData[$ID][20]=""
      EndIf

         ;beep
      If $beep<>$notificationsOptions[$ID][12] Then
         ;reset data
         $notificationsOptionsData[$ID][12]=""
      EndIf


         ;Run
      If $run<>$notificationsOptions[$ID][23] Then
         ;reset data
         $notificationsOptionsData[$ID][23]=""
      EndIf

_debug("spec func end")



      ;force redraw (hotfix)
      _WinAPI_RedrawWindow($notificationsHandles[$ID][0])

_debug("redraw fix end")

      ;store new options to options-array
      For $i=0 To UBound($options)-1
         $notificationsOptions[$ID][$i]=$options[$i][1]
      Next

_debug("store opt end")

   EndIf

EndFunc

Func _showNotification($ID)

   Local $winHandle=$notificationsHandles[$ID][0]
   Local $currentPos=WinGetPos($winHandle)

   _WinAPI_SetWindowPos($winHandle,$HWND_TOP,$currentPos[0],$currentPos[1],$currentPos[2],$currentPos[3],$SWP_NOACTIVATE + $SWP_NOZORDER + $SWP_NOREPOSITION + $SWP_NOSIZE + $SWP_SHOWWINDOW)

   ;if specified, grab focus
   If $notificationsOptions[$ID][19]<>"" Then WinActivate($winHandle)

;~    DllCall("user32.dll","int","AnimateWindow","hwnd",$winHandle,"int",100,"long",0x00040008);slide-in from bottom
;~    GUISetState(@SW_SHOW,$winHandle)

EndFunc

Func _hideNotification($ID)

   Local $winHandle=$notificationsHandles[$ID][0]

   If $ID<>"" And $winHandle<>"" Then
   ;~    DllCall("user32.dll","int","AnimateWindow","hwnd",$winHandle,"int",100,"long",0x00050004);slide-out to bottom

      ;fade out
      If $behaviourFadeOut==1 Then

         Local $trans = $defaultTrans
         If $notificationsOptions[$ID][18]<>"" Then $trans=$notificationsOptions[$ID][18]

         For $i=$trans To 0 Step -30
            WinSetTrans($winHandle,"",$i)
            Sleep(1)
         Next

      EndIf

      ;hide GUI (it still exists, until the delete request has been processed)
      GUISetState(@SW_HIDE,$winHandle)

;~        If $notificationsOptions[$ID][35]=="" Then _reflow($ID)
If $notificationsOptions[$ID][35]=="" Then _repositionAll()

      ;add a delete request
      ReDim $notificationsDeleteRequests[UBound($notificationsDeleteRequests)+1]
      $notificationsDeleteRequests[UBound($notificationsDeleteRequests)-1]=$winHandle

   EndIf

EndFunc

Func _shakeNotification($ID)

   Local $notifPos=WinGetPos($notificationsHandles[$ID][0])

   WinMove($notificationsHandles[$ID][0],"",$notifPos[0]-5,$notifPos[1],Default,Default,1)
   WinMove($notificationsHandles[$ID][0],"",$notifPos[0]+5,$notifPos[1],Default,Default,1)
   WinMove($notificationsHandles[$ID][0],"",$notifPos[0]-5,$notifPos[1],Default,Default,1)
   WinMove($notificationsHandles[$ID][0],"",$notifPos[0],$notifPos[1],Default,Default,1)

EndFunc

Func _processNotificationsDeleteRequests()

   ; Make a copy of this array. All requests that are added while this func executes are ignored. This avoids outOfBounds-Errors.
   Local $deleteRequest=$notificationsDeleteRequests

   For $i=1 To UBound($deleteRequest)-1

      Local $ID=_handleToID($deleteRequest[$i])


      If $ID <> "" Then

         ; delete GUI
         GUIDelete($deleteRequest[$i])

         ; close sound handle (if there's none this will simply fail)
         _SoundClose($notificationsOptionsData[$ID][21])
;~          If @error Then _logError('failed to close sound, @error='&@error, 0, 0, $errorLog, $errorLogDir, $errorLogfile, $errorLogMaxNumberOfLines)

         ; delete entries as specified
         _ArrayDelete($notificationsHandles,$ID)
         _ArrayDelete($notificationsOptions,$ID)
         _ArrayDelete($notificationsOptionsData,$ID)

      EndIf

      ;delete entry in notificationsDeleteRequests that has just been processed
      Local $j=1
      Local $UBoundMemory=UBound($notificationsDeleteRequests)

      While 1

         If $j>UBound($notificationsDeleteRequests)-1 Then
            ;if we're out of bounds, because the array has been modified, start again
            If UBound($notificationsDeleteRequests)<>$UBoundMemory Then
               $j=1
               ContinueLoop
            ;else, an error has occured, since we haven't yet deleted the entry
            Else
               _logError('something is wrong here: could not remove delete request "'&$deleteRequest[$i]&'" from requestArray, while deleting the other array entries seems to have been successful',$errorInteractive,$errorBroadcast,$errorLog,$errorLogDir,$errorLogfile,$errorLogMaxNumberOfLines)
            EndIf
         EndIf

         If $notificationsDeleteRequests[$j]==$deleteRequest[$i] Then
            _ArrayDelete($notificationsDeleteRequests,$j)
            ExitLoop
         EndIf

      WEnd

   Next

EndFunc

Func _exit()
   _debug("_exit")
   If $behaviourAutoDeregister == 1 Then _deregister(0, 1)
   If @error Then _logError("Deregistering FP-QUI failed:"&@LF&"@error="&@error&@LF&"@extended="&@extended&@LF&"$behaviourAutoRegister="&$behaviourAutoRegister, $errorInteractive, $errorInteractive, $errorLog, $errorLogDir, $errorLogFile, $errorLogMaxNumberOfLines, 1)
EndFunc