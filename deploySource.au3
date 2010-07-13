#include <_stringReplaceVariables.au3>

#include "deploy_shared.au3"

Global $version = $CmdLineRaw

_initialize($version,"source")

_commonFiles($appPath,$basePath)

;includes
;~ FileCopy($includesPath&"\_*.au3",$basePath&"\_includes\",8)

;main code
FileCopy($appPath&"\*.au3",$basePath&"\",8)
FileDelete($basePath&"\deploy*.au3")

;modules
FileCopy($appPath&"\modules",$basePath&"\modules\",8)

;gui
FileCopy($appPath&"\gui",$basePath&"\GUI\",8)

;config
FileCopy($appPath&"\data\config_global.ini",$basePath&"\data\config_global.ini",8)
_setDefaultConfig($basePath&"\data\config_global.ini")


_wrapItUp($basePath)
DirRemove($basePath,1)
