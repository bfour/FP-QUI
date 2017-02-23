;===============================================================================
;
; Function Name:    _addAutoStart()
; Description:      adds an entry to the AutoStart-folder of the current user
; Parameter(s):     $entryName 			- name of the entry that will be created in @StartupDir
; 					$target   	   		- target of the link that will be created
;					$overwrite			- Optional: overwrite existing links with the specified name and a different target (ie: if the links are identical, there will be no overwrite)
;					$promptOverwrite	- Optional: prompt the user for confirmation before overwrite
; Return Value(s): 	On Success   		- path to the link
;                   On Failure   	- Returns path to the link and sets @ERROR > 0
;					@ERROR = 1 		- user aborted overwrite
;					@ERROR = 2 		- failed to write or overwrite link
; Author(s):        Florian Pollak
; Created:          2010-07-13
; Modified:         -
;
;===============================================================================
Func _addAutoStart($entryName, $target, $overwrite=Default, $promptOverwrite=Default)
	
	If $overwrite == Default Then $overwrite = True
	If $promptOverwrite == Default Then $promptOverwrite = False
	
	Local $error = 0
	Local $linkPath=@StartupDir &"\"& $entryName &".lnk"

	If FileExists($linkPath)==1 Then
		;a link with the same name already exists
		
		Local $linkTarget = FileGetShortcut($linkPath)
		$linkTarget = $linkTarget[0]
		
		If $linkTarget <> $target Then
			;the links are not identical
			
			If $overwrite And $promptOverwrite Then
				
				Local $answer = MsgBox(32+4, @ScriptName, 'A link to '&$target&' already exists in your AutoStart folder ('&$linkPath&'). It points to '&$linkInfo[0]&'. Do you want to replace it with a link that points to '&$target&'?')
				If $answer==7 Then Return SetError(1, 0, $linkPath) ;no
					
			ElseIf Not $overwrite Then
					
				;do not overwrite as specified
				Return SetError(0, 0, $linkPath)
				
			EndIf
		
		Else
			;the links ARE identical --> no overwrite, return with no error
			Return SetError($error, 0, $linkPath)
		EndIf
			
	EndIf

	;create shortcut and return
	If FileCreateShortcut($target, $linkPath)<>1 Then $error += 2
	Return SetError($error, 0, $linkPath)

EndFunc

;===============================================================================
;
; Function Name:    _removeAutoStart()
; Description:      removes an entry from the AutoStart-folder of the current user
; Parameter(s):     $entryName 			- name of the entry that will be removed from @StartupDir
; Return Value(s): 	On Success   	- ""
;                   On Failure   	- Returns "" and sets @ERROR > 0
;					@ERROR = 1 		- deletion failed
;					@ERROR = 2		- entry does not exist
;                   @ERROr = 3		- entry does not exist & deletion failed
; Author(s):        Florian Pollak
; Created:          2010-07-13
; Modified:         -
;
;===============================================================================
Func _removeAutoStart($entryName)
	
	Local $error = 0
	Local $entryPath = @StartupDir &"\"& $entryName &".lnk"
	
	If FileExists($entryPath)==0 Then $error += 2
	If FileDelete($entryPath)==0 Then $error += 1
		
	Return SetError($error, 0, "")
	
EndFunc