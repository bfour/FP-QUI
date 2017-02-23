#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.2.12.0
 Author:	Florian Pollak
 
#ce ----------------------------------------------------------------------------

#include-once

;~ _talk('test')
;~ _talk('Daisy, Daisy, give me your answer do.')
;~ MsgBox(1,"","")
;~ Sleep(1861)
;~ _talkListVoices()

; language:
; 409 EN US
; 407 DE DE
; 40a ES ES
; 40c FR FR
; 40b FI FI
Func _talk($string, $language=Default)
	
	If $string=="" Then
		SetError(1)
		Return ""		
	EndIf
	
	If $language==Default Then $language=409
	
    Local $speech = ObjCreate("SAPI.SpVoice")	
	If @error Then
		SetError(1)
		Return ""
	EndIf

	If @OSVersion == "WIN_8" Then
		$speech.Voice = $speech.GetVoices("","Language="&$language).Item(0)
	EndIf

	$speech.Volume=100
	$speech.Speak($string)
    $speech = ""

EndFunc

Func _talkListVoices()
	
	Local $speech = ObjCreate("SAPI.SpVoice")	
	If @error Then
		SetError(1)
		Return ""
	EndIf
	
	$string = "test"
	$voiceType = 1
	
	Local $i = 0, $voice
    Dim $voiceTypes = $speech.GetVoices('', '')
	
    For $voice In $voiceTypes
		
        ConsoleWrite($voiceType & ", " & $i & @LF)
		
        Select
            Case $voiceType == 1 And $i == 0
                ConsoleWrite($voice.GetDescription & @LF)
                $speech.Voice = $speech.GetVoices("","").Item(0)
                $speech.Speak ($string)
                ExitLoop
            Case $voiceType == 2 And $i == 1
                ConsoleWrite($voice.GetDescription & @LF)
                $speech.Voice = $speech.GetVoices("","").Item(1)
                $speech.Speak ($string)
                ExitLoop
            Case $voiceType == 3 And $i == 2
                ConsoleWrite($voice.GetDescription & @LF)
                $speech.Voice = $speech.GetVoices("","").Item(2)
                $speech.Speak ($string)
                ExitLoop
            Case $voiceType == 4 And $i == 3
                ConsoleWrite($voice.GetDescription & @LF)
                $speech.Voice = $speech.GetVoices("","").Item(3)
                $speech.Speak ($string)
                ExitLoop
        EndSelect
        $i += 1 
		
    Next
;~ 	
EndFunc