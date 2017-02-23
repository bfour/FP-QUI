#include-once

#include <_path.au3>

Func _stringReplaceVariables($string)
	Local $stringCache=$string
	
	If StringInStr($string,"@")<>0 Then
	
		$stringCache=StringReplace($stringCache,"@AppDataCommonDir",@AppDataCommonDir)
		$stringCache=StringReplace($stringCache,"@DesktopCommonDir",@DesktopCommonDir)
		$stringCache=StringReplace($stringCache,"@DocumentsCommonDir",@DocumentsCommonDir)
		$stringCache=StringReplace($stringCache,"@FavoritesCommonDir",@FavoritesCommonDir)
		$stringCache=StringReplace($stringCache,"@ProgramsCommonDir",@ProgramsCommonDir)
		$stringCache=StringReplace($stringCache,"@StartMenuCommonDir",@StartMenuCommonDir)
		$stringCache=StringReplace($stringCache,"@StartupCommonDir",@StartupCommonDir)
		$stringCache=StringReplace($stringCache,"@AppDataDir",@AppDataDir)
		$stringCache=StringReplace($stringCache,"@DesktopDir",@DesktopDir)
		$stringCache=StringReplace($stringCache,"@MyDocumentsDir",@MyDocumentsDir)
		$stringCache=StringReplace($stringCache,"@FavoritesDir",@FavoritesDir)
		$stringCache=StringReplace($stringCache,"@ProgramsDir",@ProgramsDir)
		$stringCache=StringReplace($stringCache,"@StartMenuDir",@StartMenuDir)
		$stringCache=StringReplace($stringCache,"@StartupDir",@StartupDir)
		$stringCache=StringReplace($stringCache,"@UserProfileDir",@UserProfileDir)
		$stringCache=StringReplace($stringCache,"@HomeDrive",@HomeDrive)
		$stringCache=StringReplace($stringCache,"@HomePath",@HomePath)
		$stringCache=StringReplace($stringCache,"@HomeShare",@HomeShare)
		$stringCache=StringReplace($stringCache,"@YEAR",@YEAR)
		$stringCache=StringReplace($stringCache,"@MON",@MON)
		$stringCache=StringReplace($stringCache,"@MDAY",@MDAY)
		$stringCache=StringReplace($stringCache,"@HOUR",@HOUR)
		$stringCache=StringReplace($stringCache,"@MIN",@MIN)
		$stringCache=StringReplace($stringCache,"@SEC",@SEC)
		$stringCache=StringReplace($stringCache,"@LogonDNSDomain",@LogonDNSDomain)
		$stringCache=StringReplace($stringCache,"@LogonDomain",@LogonDomain)
		$stringCache=StringReplace($stringCache,"@LogonServer",@LogonServer)
		$stringCache=StringReplace($stringCache,"@ProgramFilesDir",@ProgramFilesDir)
		$stringCache=StringReplace($stringCache,"@CommonFilesDir",@CommonFilesDir)
		$stringCache=StringReplace($stringCache,"@WindowsDir",@WindowsDir)
		$stringCache=StringReplace($stringCache,"@SystemDir",@SystemDir)
		$stringCache=StringReplace($stringCache,"@TempDir",@TempDir)
		$stringCache=StringReplace($stringCache,"@ComSpec",@ComSpec)
		$stringCache=StringReplace($stringCache,"@CPUArch",@CPUArch)
		$stringCache=StringReplace($stringCache,"@KBLayout",@KBLayout)
		$stringCache=StringReplace($stringCache,"@OSArch",@OSArch)
		$stringCache=StringReplace($stringCache,"@OSLang",@OSLang)
		$stringCache=StringReplace($stringCache,"@OSType",@OSType)
		$stringCache=StringReplace($stringCache,"@OSVersion",@OSVersion)
		$stringCache=StringReplace($stringCache,"@OSBuild",@OSBuild)
		$stringCache=StringReplace($stringCache,"@OSServicePack",@OSServicePack)
		$stringCache=StringReplace($stringCache,"@ComputerName",@ComputerName)
		$stringCache=StringReplace($stringCache,"@UserName",@UserName)
		$stringCache=StringReplace($stringCache,"@IPAddress1",@IPAddress1)
		$stringCache=StringReplace($stringCache,"@IPAddress2",@IPAddress2)
		$stringCache=StringReplace($stringCache,"@IPAddress3",@IPAddress3)
		$stringCache=StringReplace($stringCache,"@IPAddress4",@IPAddress4)
		$stringCache=StringReplace($stringCache,"@DesktopHeight",@DesktopHeight)
		$stringCache=StringReplace($stringCache,"@DesktopWidth",@DesktopWidth)
		$stringCache=StringReplace($stringCache,"@DesktopDepth",@DesktopDepth)
		$stringCache=StringReplace($stringCache,"@DesktopRefresh",@DesktopRefresh)
		$stringCache=StringReplace($stringCache,"@compiled",@compiled)
		$stringCache=StringReplace($stringCache,"@NumParams",@NumParams)
		$stringCache=StringReplace($stringCache,"@ScriptName",@ScriptName)
		$stringCache=StringReplace($stringCache,"@ScriptDir",@ScriptDir)
		$stringCache=StringReplace($stringCache,"@ScriptFullPath",@ScriptFullPath)
		$stringCache=StringReplace($stringCache,"@ScriptLineNumber",@ScriptLineNumber)
		$stringCache=StringReplace($stringCache,"@WorkingDir",@WorkingDir)
		$stringCache=StringReplace($stringCache,"@AutoItExe",@AutoItExe)
		$stringCache=StringReplace($stringCache,"@AutoItPID",@AutoItPID)
		$stringCache=StringReplace($stringCache,"@AutoItVersion",@AutoItVersion)
		$stringCache=StringReplace($stringCache,"@AutoItX64",@AutoItX64)
		
	EndIf

	If StringInStr($string,"%")<>0 Then
		$stringCache=StringReplace($stringCache,"%grid%",_pathGetSpecificDirByName(@ScriptDir,"grid"))
		$stringCache=StringReplace($stringCache,"%sabox%",_pathGetSpecificDirByName(@ScriptDir,"sabox"))
	EndIf
	
	;relative path
	If StringLeft($stringCache,1)="\" And StringLeft($stringCache,2)<>"\\" Then $stringCache=@ScriptDir&$stringCache

	Return $stringCache
EndFunc