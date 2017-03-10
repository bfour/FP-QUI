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
#include <_stringReplaceVariables.au3>
#include <Array.au3>
#Include <File.au3>
#include <_error.au3>
#include <_path.au3>

; get value for configurable variable
; (this should be a better solution than global variables at the beginning of the script)
Func _iniGetValue($key)
   Switch $key
   Case "defaultsPrefix"
     Return "_iniDefaults_"
   EndSwitch
EndFunc

Func _iniInitialize($globalPath,$specificOverwritePath=Default,$specificPathDefault=Default,$globalReferenceNameDefault=Default,$iniSyncDefault=Default,$iniSyncInteractiveDefault=Default)

   If $specificOverwritePath=Default Then $specificOverwritePath=""
   If $specificPathDefault=Default Then $specificPathDefault=""
   If $globalReferenceNameDefault=Default Then $globalReferenceNameDefault="%_iniGlobalReference%"
   If $iniSyncDefault=Default Then $iniSyncDefault=1
   If $iniSyncInteractiveDefault=Default Then $iniSyncInteractiveDefault=1

   ;if not global-ini-dir exists then create dir
   Local $globalDir=_pathGetDir($globalPath)

   If DirGetSize($globalDir,2)=-1 Then DirCreate($globalDir)


   #cs
   if iniReadSection(„_ini“)-error
      write defaults to file: [_ini] specificPath=; globalReferenceName=%_iniGlobalReference%; iniSync=1; iniSyncInteractive=1
   else
      if specificPath is missing -> set default („“)
      if globalReferenceName is missing -> set default („%_iniGlobalReference%“)
      if iniSync is missing -> set default (1)
      if iniSyncInteractive is missing -> set default (1)
   #ce
   Local $iniSection=IniReadSection($globalPath,"_ini")
   If @error Then
      IniWrite($globalPath,"_ini","specificPath",$specificPathDefault)
      IniWrite($globalPath,"_ini","globalReferenceName",$globalReferenceNameDefault)
      IniWrite($globalPath,"_ini","iniSync",$iniSyncDefault)
      IniWrite($globalPath,"_ini","iniSyncInteractive",$iniSyncInteractiveDefault)
   Else
      If _ArraySearch($iniSection,"specificPath")=-1 Then IniWrite($globalPath,"_ini","specificPath",$specificPathDefault)
      If _ArraySearch($iniSection,"globalReferenceName")=-1 Then IniWrite($globalPath,"_ini","globalReferenceName",$globalReferenceNameDefault)
      If _ArraySearch($iniSection,"iniSync")=-1 Then IniWrite($globalPath,"_ini","iniSync",$iniSyncDefault)
      If _ArraySearch($iniSection,"iniSyncInteractive")=-1 Then IniWrite($globalPath,"_ini","iniSyncInteractive",$iniSyncInteractiveDefault)
   EndIf




   #cs
   if specificOverwritePath =„“ get specific-ini-path from global, else specificOverwritePath
   #ce
   Local $specificPath=_iniFinalPath($globalPath,$specificOverwritePath)

   ;if not specific-ini-dir exists create dir
   Local $specificDir=_pathGetDir($specificPath)

   If DirGetSize($specificDir,2)=-1 Then DirCreate($specificDir)


   #CS
      if iniReadSection(„_ini“)-error
         write defaults to file: get data from global: globalReferenceName, iniSync=[%_iniGlobalReference%]; iniSyncInteractive(1)
      else
         if globalReferenceName missing -> set value from global
         if iniSync missing -> set value from global
         if iniSyncInteractive is missing -> set default (1)
   #CE
   Local $iniSection=IniReadSection($specificPath,"_ini")
   If @error Then

      IniWrite($specificPath,"_ini","specificPath",IniRead($globalPath,"_ini","specificPath",$specificPathDefault))
      IniWrite($specificPath,"_ini","globalReferenceName",IniRead($globalPath,"_ini","globalReferenceName",$globalReferenceNameDefault))
      IniWrite($specificPath,"_ini","iniSync",IniRead($globalPath,"_ini","iniSync",$iniSyncDefault))
      IniWrite($specificPath,"_ini","iniSyncInteractive",IniRead($globalPath,"_ini","iniSyncInteractive",$iniSyncInteractiveDefault))

   Else

      If _ArraySearch($iniSection,"specificPath")==-1 Then _
         IniWrite( _
            $specificPath, _
            "_ini", _
            "specificPath", _
            IniRead($globalPath,"_ini","specificPath",$specificPathDefault))

      If _ArraySearch($iniSection,"globalReferenceName")==-1 Then _
         IniWrite( _
            $specificPath, _
            "_ini", _
            "globalReferenceName", _
            IniRead($globalPath,"_ini","globalReferenceName",$globalReferenceNameDefault))

      If _ArraySearch($iniSection,"iniSync")==-1 Then _
         IniWrite( _
            $specificPath, _
            "_ini", _
            "iniSync", _
            IniRead($globalPath,"_ini","iniSync",$iniSyncDefault))

      If _ArraySearch($iniSection,"iniSyncInteractive")==-1 Then _
         IniWrite( _
            $specificPath, _
            "_ini", _
            "iniSyncInteractive", _
            IniRead($globalPath,"_ini","iniSyncInteractive",$iniSyncInteractiveDefault))

   EndIf

   ;if iniSync (in specific-ini) is 1 then iniSync(globalIniPath,SpecificIniPath)
   If IniRead($specificPath,"_ini","iniSync",$iniSyncDefault)==1 Then _iniSync($globalPath,$specificPath,IniRead($specificPath,"_ini","iniSyncInteractive",$iniSyncInteractiveDefault))

EndFunc

Func _iniSync($source,$target,$interactive)

   Local $error=0

   While 1
      ;read source and target to array
      Local $sourceArray
      _FileReadToArray($source,$sourceArray)
      If @error=1 Then
         _error("_iniSync failed to open "&$source)
         ExitLoop
      ElseIf @error=2 Then
         _error("_iniSync failed to split "&$source)
         ExitLoop
      EndIf
;~ _ArrayDisplay($sourceArray,"$sourceArray")

      Local $targetArray
      _FileReadToArray($target,$targetArray)
      If @error=1 Then
         _error("_iniSync failed to open "&$target)
         ExitLoop
      ElseIf @error=2 Then
         _error("_iniSync failed to split "&$target)
         ExitLoop
      EndIf
;~ _ArrayDisplay($targetArray,"$target")

      ;make bounds of source and target array equal (easier processing), by adding empty elements to the shorter one
      If UBound($sourceArray)>UBound($targetArray) Then
         ReDim $targetArray[UBound($sourceArray)]
      Else
         ReDim $sourceArray[UBound($targetArray)]
      EndIf


      ;compare source and target

      Local $different=0

      ;go through each line of source and compare source and target
      For $i=1 To UBound($sourceArray)-1
         Local $currentLineSource=StringReplace(StringStripWS($sourceArray[$i],3),@TAB,"")
         Local $currentLineTarget=StringReplace(StringStripWS($targetArray[$i],3),@TAB,"")
         Local $cache

         If $currentLineSource<>$currentLineTarget Then

            ;source is empty (target is not)
            If $currentLineSource="" Then
               $different=1
               ExitLoop

            ;source starts with # (comment) (target does not)
            ElseIf StringLeft($currentLineSource,1)="#" Then
               $different=1
               ExitLoop

            ;source starts with [ (section) (target does not)
            ElseIf StringLeft($currentLineSource,1)="[" Then
               $different=1
               ExitLoop

            ;in source, one "=" is preceeded by at least one character which is not a "=" (in target, this is not the case)
            ElseIf _iniStringIsKeyValuePair($currentLineSource) _
               And Not _iniStringIsKeyValuePair($currentLineTarget) _
               Then
                  $different=1
                  ExitLoop

            ;in source, one "=" is preceeded by at least one character which is not a "=" (in target, this is the case as well, however, the keys might be different)
            ElseIf _iniStringIsKeyValuePair($currentLineSource) _
               And _iniStringIsKeyValuePair($currentLineTarget) _
               And StringLeft($currentLineSource,StringInStr($currentLineSource,"=")-1)<>StringLeft($currentLineTarget,StringInStr($currentLineTarget,"=")-1) _
               Then
                  $different=1
                  ExitLoop

               EndIf

            EndIf

;~ MsgBox(1,"$currentLineSource<>$currentLineTarget",$currentLineSource&@CRLF&$currentLineTarget&@CRLF&@CRLF&$different)

      Next

      ; if there is a difference, we need to sync, otherwise nothing needs to be done
      If $different Then

         ;copy source to temp
         Local $tempPath=_pathGetDir($target)&"\_iniSync_temp_"&_pathGetFileName($target)

         Local $fileCopyMode=8
         ;wait for at most ~2 seconds for file to not exist
         For $i=1 To 8
            If FileExists($tempPath) Then
               Sleep(250)
            Else
               ExitLoop
            EndIf
         Next

         If FileExists($tempPath) Then
            Local $answer=MsgBox(4+48+256,@ScriptName&"\_iniSync",'Temporary file "'&$tempPath&'" already exists.'&@CRLF&'Overwrite?')
            If $answer=6 Then $fileCopyMode+=1
         EndIf

         If Not FileCopy($source,$tempPath,$fileCopyMode) Then
            _error('Failed to copy source ('&$source&') to temp ('&$tempPath&'). Mode: '&$fileCopyMode)
            ExitLoop
         EndIf

         ; replace values in temp with values from target
         Local $sourceDataArray=_iniGetDataArrayFromFileArray($sourceArray)
         Local $targetDataArray=_iniGetDataArrayFromFileArray($targetArray)

         ; handle orphaned entries, ie. keys that only exist in target but not in source
         ; sections
         For $i=0 To UBound($targetDataArray)-1

            ; section-entries
            For $j=0 To UBound($targetDataArray,2)-1

               If $targetDataArray[$i][$j][1]<>"" Then

                  ;if key does not exist in source (but in target, obviously), then ask user wheter to delete it or not (if interactive) or simply keep it (if not)
                  Local $errorValue = ""
                  If UBound($sourceDataArray,1)>=$i+1 And UBound($sourceDataArray,2)>=$j+1 Then
                     _iniGetValueFromDataArray($sourceDataArray,$sourceDataArray[$i][0][0],$sourceDataArray[$i][$j][1])
                     $errorValue = @error
                  EndIf

                  If $interactive==1 _
                     And ( _
                     Not(UBound($sourceDataArray,1)>=$i+1) _
                     Or Not(UBound($sourceDataArray,2)>=$j+1) _
                     Or $errorValue _
                     ) Then

                     Local $answer=MsgBox(4+48,@ScriptName&"\_iniSync", _
                     'The following key-value-pair: '&@CRLF& _
                     @CRLF& _
                     '['&$targetDataArray[$i][0][0]&']'&@CRLF& _
                     $targetDataArray[$i][$j][1]&' = '&$targetDataArray[$i][$j][2]&@CRLF& _
                     @CRLF& _
                     'exists in target-ini ('&$target&') but not in source-ini ('&$source&').'&@CRLF& _
                     @CRLF& _
                     'Do you want to delete this entry from target-ini?')

                     ; 7 ... no, don't delete, for which we have to take value from target, ie. old version
                     ; (if yes, don't do anything, since tempFile is a copy of source which doesn't contain this pair)
                     If $answer == 7 Then IniWrite($tempPath,$targetDataArray[$i][$j][0],$targetDataArray[$i][$j][1],$targetDataArray[$i][$j][2])

                  Else
                      ; not interactive, delete entry, ie. do nothing
;~                      IniWrite($tempPath,$targetDataArray[$i][$j][0],$targetDataArray[$i][$j][1],$targetDataArray[$i][$j][2])
                  EndIf

                EndIf

            Next

         Next

         ;if value not in target, then
         ;   if interactive prompt: get value from global or user
         ;   else get value from global (default or existing value if no default specified)
         ; sections
         For $i=0 To UBound($sourceDataArray)-1

            ; section-entries
            For $j=0 To UBound($sourceDataArray,2)-1

               Local $errorValue = ""
               Local $existingValue = ""
               If $sourceDataArray[$i][$j][1]<>"" Then
                  $existingValue = _iniGetValueFromDataArray($targetDataArray,$sourceDataArray[$i][$j][0],$sourceDataArray[$i][$j][1])
                  $errorValue = @error
                EndIf

               If $errorValue<>0 Then
                   ; is not in target

                  ; get default
                  Local $defaultValue = _iniGetDefaultValueFromDataArray($sourceDataArray, $sourceDataArray[$i][$j][0], $sourceDataArray[$i][$j][1])
                  If @error Then $defaultValue = $sourceDataArray[$i][$j][2]

                  If $interactive==1 Then
                     Local $input=InputBox(@ScriptName&"/_iniSync",'ini-Entry exists in source-ini-file but not in target-ini-file. Enter a value or abort to apply value from source.'&@CRLF&@CRLF _
                     &'Details:' _
                     &@CRLF _
                     &'source: '&$source&@CRLF _
                     &'target: '&$target&@CRLF _
                     &'section (source): '&$sourceDataArray[$i][$j][0]&@CRLF _
                     &'key (source): '&$sourceDataArray[$i][$j][1]&@CRLF _
                     &'value (source): '&$sourceDataArray[$i][$j][2]&@CRLF _
                     &'line (source): '&_ArraySearch($sourceArray,$sourceDataArray[$i][$j][1]&"="&$sourceDataArray)&@CRLF _
                     &@CRLF, _
                     $defaultValue, _
                     Default, _
                     500, _
                     300, _
                     Default, _
                     Default)

                     ;cancel pushed or timeout --> set global --> already set (copied source to temp) --> nothing to do
                     If Not @error Then IniWrite($tempPath,$sourceDataArray[$i][$j][0],$sourceDataArray[$i][$j][1],$input)

                  Else
                     ; not interactive, try to take default from global/source, else take existing value from there (already in $defaultValue)
;~                      MsgBox(1,$sourceDataArray[$i][$j][0]&" "&$sourceDataArray[$i][$j][1],$defaultValue)
                     IniWrite($tempPath,$sourceDataArray[$i][$j][0],$sourceDataArray[$i][$j][1],$defaultValue)
                  EndIf

                Else
                  ; is in target, keep
                  IniWrite($tempPath,$sourceDataArray[$i][$j][0],$sourceDataArray[$i][$j][1],$existingValue)
               EndIf

            Next

         Next

;~ MsgBox(1,"move tempFile to target",$tempPath&" "&$target)
         ;move tempFile to target (overwrite)
         FileCopy($tempPath,$target,9)
         ;delete tempFile
         FileDelete($tempPath)

      EndIf

   ExitLoop
   WEnd

EndFunc

; INTERFACE ======================
#cs
in:
section
key
default value
globalPath
specificOverwritePath -> if not empty, this path will be used, regardless of what's specified as specificPath in global
#ce
Func _iniRead($globalPath,$section,$key,$defaultValue,$specificOverwritePath=Default)

   If $specificOverwritePath==Default Then $specificOverwritePath=""

   ;get final path (specificOverwrite-mechanism)
   Local $finalPath=_iniFinalPath($globalPath,$specificOverwritePath)

   Local $value=IniRead($finalPath,$section,$key,$defaultValue)

   Local $globalReferenceName=IniRead($finalPath,"_ini","globalReferenceName","")

   ;if value is reference to global read from global
   If $value==$globalReferenceName Then $value=IniRead($globalPath,$section,$key,$defaultValue)


   Return $value

EndFunc

Func _iniReadSection($globalPath,$sectionName,$specificOverwritePath=Default)

   If $specificOverwritePath==Default Then $specificOverwritePath=""

   Local $finalPath=_iniFinalPath($globalPath,$specificOverwritePath)

   Local $section=IniReadSection($finalPath,$sectionName)

   If @error Then
      SetError(1)
      Return ""
   EndIf

   Local $globalReferenceName=IniRead($finalPath,"_ini","globalReferenceName","")
   ;get (final) values (specificOverwrite-mechanism)
   For $i=1 To UBound($section)-1
      ;if value is reference to global read from global
      If $section[$i][1]==$globalReferenceName Then $section[$i][1]=IniRead($globalPath,$sectionName,$section[$i][0],$section[$i][1])
    Next

   Return $section

EndFunc

Func _iniReadSectionNames($globalPath,$specificOverwritePath=Default,$ignoreIniSection=Default)

   If $specificOverwritePath=Default Then $specificOverwritePath=""
   If $ignoreIniSection=Default Then $ignoreIniSection=1

   Local $finalPath=_iniFinalPath($globalPath,$specificOverwritePath)

   ;read finalPath/section/key
   Local $sectionNames=IniReadSectionNames($finalPath)

   If @error Then
      SetError(1)
      Return ""
   EndIf

   If $ignoreIniSection=1 Then
      Local $cache=_ArraySearch($sectionNames,"_ini")
      If Not @error And $cache>=0 Then
         _ArrayDelete($sectionNames,$cache)
         ;adjust number of entries
         $sectionNames[0]-=1
      EndIf
   EndIf

   Return $sectionNames

EndFunc


Func _iniWrite($globalPath,$section,$key,$value,$specificOverwritePath=Default)

   If $specificOverwritePath=Default Then $specificOverwritePath=""

   ;get final path (specificOverwrite-mechanism)
   Local $finalPath=_iniFinalPath($globalPath,$specificOverwritePath)

   Local $currentValue=IniRead($finalPath,$section,$key,"")

   Local $globalReferenceName=IniRead($finalPath,"_ini","globalReferenceName","")

   ;if value is reference to global write to global
   If $currentValue=$globalReferenceName Then
      Return IniWrite($globalPath,$section,$key,$value)
   Else
      Return IniWrite($finalPath,$section,$key,$value)
   EndIf

EndFunc

Func _iniWriteSection($globalPath,$section,$data,$index=Default,$specificOverwritePath=Default)

   If $index=Default Then $index=1
   If $specificOverwritePath=Default Then $specificOverwritePath=""

   ;get final path (specificOverwrite-mechanism)
   Local $finalPath=_iniFinalPath($globalPath,$specificOverwritePath)

   Local $return=IniWriteSection($finalPath,$section,$data,$index)
   SetError(@error)
   Return $return

EndFunc


Func _iniDelete($globalPath,$section,$key=Default,$specificOverwritePath=Default)

   If $specificOverwritePath=Default Then $specificOverwritePath=""

   ;get final path (specificOverwrite-mechanism)
   Local $finalPath=_iniFinalPath($globalPath,$specificOverwritePath)

   Return IniDelete($finalPath,$section,$key)

EndFunc

;\INTERFACE ======================


Func _iniFinalPath($globalPath,$specificOverwritePath=Default)

   If $specificOverwritePath=Default Then $specificOverwritePath=""

   #CS
   if specificOverwritePath<>““ then
      finalPath=specificOverwritePath
   else
      if globalPath-ini/[_ini]specificPath = „“ then
         finalPath=globalPath
      else
         finalPath = globalPath-ini/[_ini]specificPath
   #CE
   Local $finalPath

   If $specificOverwritePath="" Then
      $finalPath=_stringReplaceVariables(IniRead($globalPath,"_ini","specificPath",""))
      ;if emtpy, then set globalPath
      If $finalPath="" Then $finalPath=$globalPath
   Else
      $finalPath=$specificOverwritePath
   EndIf

   Return $finalPath
EndFunc


;in: string (format: [abc])
;out: section name, on failure: "", @error=1
Func _iniStringGetSectionName($string)

   If Not _iniStringIsSectionTitle($string) Then
      SetError(1)
      Return ""
   Else
      $string=StringReplace($string,"[","")
      $string=StringReplace($string,"]","")
      Return $string
   EndIf

EndFunc

;in: string (format: abc=xyz)
;out: key, on failure: "", @error=1
Func _iniStringGetKey($string)

   If Not _iniStringIsKeyValuePair($string) Then
      SetError(1)
      Return ""
   Else
      Return StringLeft($string,StringInStr($string,"=")-1)
   EndIf

EndFunc

;in: string (format: abc=xyz)
;out: value, on failure: "", @error=1
Func _iniStringGetValue($string)

   If Not _iniStringIsKeyValuePair($string) Then
      SetError(1)
      Return ""
   Else
      Return StringRight($string,StringLen($string)-StringInStr($string,"="))
   EndIf

EndFunc

;in: fileReadToArray-Array
;out: 0based 1D-Array containing section names
Func _iniGetSectionNamesFromFileArray(ByRef $fileArray)

   Local $sectionNames[1]

   For $i=1 To UBound($fileArray)-1
      Local $currentLine=StringStripWS($fileArray[$i],3)
      If StringLeft($currentLine,1)="[" And StringRight($currentLine,1)="]" Then
         If $sectionNames[0]="" Then
            $sectionNames[0]=_iniStringGetSectionName($currentLine)
         Else
            ReDim $sectionNames[UBound($sectionNames)+1]
            $sectionNames[UBound($sectionNames)-1]=_iniStringGetSectionName($currentLine)
         EndIf
      EndIf
   Next

;~ _ArrayDisplay($sectionNames,"_iniGetDataArrayFromFileArray,$sectionNames")

   Return $sectionNames

EndFunc

;in: fileReadToArray-Array, name of section
;out: 0based 2D-Array containing section entries: [n][0:key 1:value]
Func _iniGetSectionFromFileArray(ByRef $fileArray,$sectionName)

   Local $section[1][2]

   For $i=1 To UBound($fileArray)-1

      Local $loopSectionName=_iniStringGetSectionName($fileArray[$i])
      If Not @error And $loopSectionName=$sectionName Then

         While 1

            ;if the last element of $fileArray has already been reached, this section is empty --> return empty String
            If $i+1=UBound($fileArray) Then
;~ _ArrayDisplay($fileArray)
               Return ""
            EndIf

            $i+=1


            Local $key=_iniStringGetKey($fileArray[$i])
            Local $value=_iniStringGetValue($fileArray[$i])

            If Not @error And $key<>"" Then
               If $section[0][0]="" And $section[0][1]="" Then
                  $section[0][0]=$key
                  $section[0][1]=$value
               Else
                  ReDim $section[UBound($section)+1][2]
                  $section[UBound($section)-1][0]=$key
                  $section[UBound($section)-1][1]=$value
               EndIf
            EndIf

            ;if another section or the last element of $fileArray has been reached, $section is complete
            Local $loopSectionName=_iniStringGetSectionName($fileArray[$i])
;~ MsgBox(1,"_iniGetSectionFromFileArray","$loopSectionName: "&$loopSectionName&@CRLF&"@error: "&@error)
            If Not @error Or $i+1=UBound($fileArray) Then
;~ _ArrayDisplay($section,"_iniGetSectionFromFileArray $sectionName"&$sectionName)
               Return $section
               ExitLoop(2)
            EndIf

         WEnd

      EndIf

   Next

EndFunc

;in: fileReadToArray-Array
;out: 3D-Array containing sections, keys and values: [section][entry][0:sectionName 1:key 2:value]
Func _iniGetDataArrayFromFileArray(Byref $fileArray)

   ;get section names -> array [0-n]
   Local $sectionNames=_iniGetSectionNamesFromFileArray($fileArray)

   ;get highest number of entries in a section
   Local $highestNumberOfEntries=1
   Local $cache
   For $i=0 To UBound($sectionNames)-1
      $cache=_iniGetSectionFromFileArray($fileArray,$sectionNames[$i])
      If IsArray($cache) And UBound($cache)>$highestNumberOfEntries Then $highestNumberOfEntries=UBound($cache)
   Next

   Local $dataArray[UBound($sectionNames)][$highestNumberOfEntries][3]
   Local $cache
   ;go through sections
   For $i=0 To UBound($dataArray)-1
      $cache=_iniGetSectionFromFileArray($fileArray,$sectionNames[$i])

      ;go through section entries an add them to array
      For $j=0 To UBound($cache)-1
         $dataArray[$i][$j][0]=$sectionNames[$i] ;section name
         $dataArray[$i][$j][1]=$cache[$j][0] ;key
         $dataArray[$i][$j][2]=$cache[$j][1] ;value
      Next
   Next

   Return $dataArray

EndFunc


;in: dataArray ([section][entry][0:sectionName 1:key 2:value]), section-name (string), key-name (string)
;out: value (string), onError: @error=1
Func _iniGetValueFromDataArray(ByRef $dataArray, $section, $key)

   ;go through sections
   For $i=0 To UBound($dataArray)-1

      ;section found ($i)
      If $dataArray[$i][0][0]==$section Then

         ;go through section-entries
         For $j=0 To UBound($dataArray,2)-1

            ; key found ($j)
            If $dataArray[$i][$j][1]==$key Then
               Return $dataArray[$i][$j][2]
            EndIf

         Next

      EndIf

   Next

   SetError(1)

EndFunc

;in: dataArray ([section][entry][0:sectionName 1:key 2:value]), section-name (string), key-name (string)
;out: default value (string), onError: @error=1
Func _iniGetDefaultValueFromDataArray(ByRef $dataArray, $section, $key)

   Local $returnValue = _iniGetValueFromDataArray($dataArray, _iniGetValue("defaultsPrefix")&$section, $key)
   SetError(@error, @extended)
   Return $returnValue

EndFunc

Func _iniStringIsSectionTitle($string)

   ;prepare String
   $string=StringStripCR($string)
   $string=StringStripWS($string,3)

   If (StringLeft($string,1)="[") _
      And (StringRight($string,1)="]") _
      Then
      Return 1
   Else
      Return 0
   EndIf

EndFunc

Func _iniStringIsKeyValuePair($string)

   ;prepare String
   $string=StringStripCR($string)
   $string=StringStripWS($string,3)

   If Not(StringLeft($string,1)="[") And Not(StringLeft($string,1)="#") And StringRegExp($string,"[^=]+=") Then
      Return 1
   Else
      Return 0
   EndIf

EndFunc