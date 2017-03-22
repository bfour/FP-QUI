#include <_stringReplaceVariables.au3>

#include "deploy_shared.au3"

Global $version = $CmdLineRaw

_initialize($version,"")

_commonFiles($appPath,$basePath)

;binary
FileCopy($appPath&"\*.exe",$basePath&"\",8)
FileDelete($basePath&"\deploy*.exe")

;icons
FileCopy($appPath&"\*.ico",$basePath&"\",8)


;gui
;~ FileCopy($appPath&"\gui",$basePath&"\GUI\",8)

;config
FileCopy($appPath&"\data\config_global.ini",$basePath&"\data\config_global.ini",8)
_setDefaultConfig($basePath&"\data\config_global.ini")

;documentation
FileCopy($appPath&"\docs\documentation.html", $basePath&"\docs\documentation.html",8)

;tools
FileCopy($appPath&"\tools\*.exe",$basePath&"\tools\",8)
FileCopy($appPath&"\tools\*.ico",$basePath&"\tools\",8)

_wrapItUp($basePath)
DirRemove($basePath,1)