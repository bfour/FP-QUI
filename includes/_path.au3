#cs
	author: Florian Pollak

#ce

#include-once

;in: path
;out: file name without directory as string, on failure: ""
Func _pathGetFileName($path)
	
	Local $pathSplit=StringSplit($path,"\")
	
	If IsArray($pathSplit) And StringInStr($path,"\")<>0  Then
		
		Local $fileName=$pathSplit[$pathSplit[0]] ; [1] C: \ [2] dir \ [3] file.dat --> [3]
		
		Return $fileName
		
	Else
		
		SetError(1)
		Return ""
		
	EndIf
	
EndFunc

;in: path
;out: file extension as string, on failure: "" and @error=1
;note: does not detect, wheter path leads to dir or file
Func _pathGetFileExtension($path)
	
	Local $fileName=_pathGetFileName($path)
	Local $fileNameSplit=StringSplit($fileName,".")
	
	If IsArray($fileNameSplit) And StringInStr($fileName,".")<>0 Then
		
		Local $fileExtension=$fileNameSplit[$fileNameSplit[0]] ; [1] C: \ [2] dir \ [3] file.dat --> [3]

		Return $fileExtension
		
	Else
		
		SetError(1)
		Return ""
		
	EndIf	
EndFunc

;in: path
;out: is file: 1, not is file: 0, error (file does not exist): -1
Func _pathIsFile($path)
	
	Local $attrib=FileGetAttrib($path)
	
	If @error<>0 Then Return -1
	
	;if is dir
	If StringInStr($attrib,"D")<>0 Then 
		Return 0
	Else
		Return 1
	EndIf
	
EndFunc

;in: path
;out: directory without file name as string, on failure: ""
Func _pathGetDir($path)
	
	Local $pathSplit=StringSplit($path,"\")
	Local $dir
	
	If IsArray($pathSplit) Then
		
		;all but the last element: [1] C: \ [2] dir \ [3] file.dat --> 1&2
		For $i=1 To $pathSplit[0]-1
			$dir&=$pathSplit[$i]&"\"
		Next
		
		Return $dir
		
	Else
		
		SetError(1)
		Return ""
		
	EndIf
	
EndFunc

;in: path
;out: directory without file name as string, on failure: ""
Func _pathGetSpecificDirByName($path,$dirName)
		
	Local $pathSplit=StringSplit(@ScriptDir,"\")
	If Not IsArray($pathSplit) Then
		SetError(1)
		Return ""
	EndIf
	
	Local $specifiedDir=""

	For $i=UBound($pathSplit)-1 To 1 Step -1
		
		If $pathSplit[$i]=$dirName Then
			
			For $j=1 To $i
				$specifiedDir&=$pathSplit[$j]&"\"
			Next
			$specifiedDir=StringTrimRight($specifiedDir,1)
			ExitLoop
			
		EndIf
		
	Next
	
	Return $specifiedDir
	
EndFunc

;in: path
;out: is dir: 1, not is dir: 0, error (dir does not exist): -1
Func _pathIsDir($path)

	Local $attrib=FileGetAttrib($path)
	
	If @error<>0 Then Return -1
	
	;if is dir
	If StringInStr($attrib,"D")<>0 Then 
		Return 1
	Else
		Return 0
	EndIf

EndFunc

;in: path
;out: drive name (eg: C: or \\Server)
Func _pathGetDriveName($path)
	
	If StringLeft($path, 1) == '"' Then $path = StringTrimLeft($path, 1)
    If StringRight($path, 1) == '"' Then $path = StringTrimRight($path, 1)
	
	Local $pathSplit=StringSplit($path,"\")
	
	If IsArray($pathSplit) And StringInStr($path,"\")<>0  Then
		
		If StringLeft($path,2)="\\" Then
			Local $driveName="\\"&$pathSplit[3] ; [1] \ [2] \ [3] Server \ [4] --> \\&[3]
		Else
			Local $driveName=$pathSplit[1] ; [1] C: \ [2] dir \ [3] file.dat --> [1]
		EndIf
		
		
		Return $driveName
		
	Else
		
		SetError(1)
		Return ""
		
	EndIf	
	
EndFunc

;in: string root, boolean includeSubFolders, $filesArray
;out: files in root with or without subfolders in array: array[n][0:dir 1:fileName 2:filePath]
Func _pathGetFileArray($root,$includeSubFolders=Default,$filesArray=Default,$foldersOnly=Default)
	
	If DirGetSize($root,2)==-1 Then 
		SetError(1)
		Return ""
	EndIf
	
	
	
	;fix incorrect format for root
	If StringRight($root,1)="\" Then $root=StringTrimRight($root,1)
		
	If $includeSubFolders=Default Then $includeSubFolders=1
		
	If $filesArray=Default Then 
		Local $filesArrayAsParameter=1
		;create empty array
;~ 		Local $array[1][3]=[["","",""]]
		Local $array[1][2]=[["",""]]
		$filesArray=$array
	Else
		Local $filesArrayAsParameter=0
	EndIf
	
	If $foldersOnly=Default Then $foldersOnly=0
	
	
	
	Local $search=FileFindFirstFile($root&"\*")  
	
	While 1
		
		If $search=-1 Then ExitLoop
		
		Local $file=FileFindNextFile($search)
		;no next file or error
		If @error Then ExitLoop
		
		Local $filePath=$root&"\"&$file
		Local $fileAttributes=FileGetAttrib($filePath)
		
		;it's another directory
		If StringInStr($fileAttributes,"D")<>0 And $includeSubFolders==1 Then
			
			$filesArray=_pathGetFileArray($filePath,$includeSubFolders,$filesArray)
			If @error Then
				SetError(1)
				Return ""
			EndIf
		
		;it's a file
		ElseIf $foldersOnly==0 Then
		
			ReDim $filesArray[UBound($filesArray)+1][3]
			$filesArray[UBound($filesArray)-1][0]=$root
			$filesArray[UBound($filesArray)-1][1]=$file
;~ 			$filesArray[UBound($filesArray)-1][2]=$filePath
			
		EndIf
		
	WEnd
	
	FileClose($search)
	
	
	If $filesArrayAsParameter==1 Then 
		For $i=0 To UBound($filesArray)-2
			$filesArray[$i][0]=$filesArray[$i+1][0]
			$filesArray[$i][1]=$filesArray[$i+1][1]
;~ 			$filesArray[$i][2]=$filesArray[$i+1][2]
		Next
		If (UBound($filesArray)-1)>0 Then
			ReDim $filesArray[UBound($filesArray)-1][3]
		Else
			$filesArray=""
		EndIf
	EndIf
	
	
	Return $filesArray
	
EndFunc