#include <_stringReplaceVariables.au3>
#include <_run.au3>
#include <_path.au3>

Global Const $7zPath = _stringReplaceVariables("%sabox%\superglobal\7zip\App\7-Zip\7z.exe")

Global Const $includesPath = _stringReplaceVariables("%grid%\FP-AutoItDevGrid\tools\AutoIt\Include")
Global Const $appPath = @ScriptDir
Global Const $changelogPath = $appPath&"\changelog.txt"


Func _initialize($version,$suffix)
		
	While 1
		
		If $version=="" Then $version = InputBox(@ScriptName,"enter version",@YEAR&@MON&@MDAY&"T"&@HOUR)
			
		If @error Then Exit
			
		Global $basePath = @ScriptDir&"\dist\FP-QUI_v"&$version&$suffix
		
		If DirGetSize($basePath,2) <> -1 Then 
			MsgBox(0,@ScriptName,"Version already exists, try again.")
			ContinueLoop
		EndIf
		
		ExitLoop
	
	WEnd

	DirCreate($basePath)
	
EndFunc


Func _commonFiles($appPath,$basePath)
	
	FileCopy($appPath&"\license.txt",$basePath)
	FileCopy($appPath&"\readme.txt",$basePath)
	FileCopy($appPath&"\changelog.txt",$basePath)
	
EndFunc


Func _setDefaultConfig($path)
	
	IniWrite($path,"_ini","specificPath","")
	IniWrite($path,"_ini","iniSyncInteractive",0)

	IniWrite($path,"defaults","font","Microsoft Sans Serif")
	IniWrite($path,"defaults","fontSize",12)
	IniWrite($path,"defaults","iconAviSize",32)
	
;~ 	IniWrite($path,"behaviour","promptIfNoArguments",0) ;deprecated
	IniWrite($path,"behaviour","fadeOut",1)
	IniWrite($path,"behaviour","maxInstances",10)
	IniWrite($path,"behaviour","autoRegister",0)
	IniWrite($path,"behaviour","autoDeregister",0)
	IniWrite($path,"behaviour","firstStart",1)
	IniWrite($path,"behaviour","showMenuOnFirstStart",1)
	IniWrite($path,"behaviour","showMenuOnNoArguments",1)
	
EndFunc

Func _wrapItUp($path)
	
	Local $name = _pathGetFileName($path)
	Local $dir = _pathGetDir($path)
	
	_runWait($7zPath&" a "&$dir&"\"&$name&".zip "&$path&"\*")
	
EndFunc


Func _addChangeLogEntry($stringArray,$version)
	
	_FileWriteToLine($changeLogPath,1,"")
;~ 	_FileWriteToLine($changeLogPath,1,"")

	For $string In $stringArray
		_FileWriteToLine($changeLogPath,1,$string)
	Next

	_FileWriteToLine($changeLogPath,1,"")
	_FileWriteToLine($changeLogPath,1,$version)
	_FileWriteToLine($changeLogPath,1,"======")
	
EndFunc