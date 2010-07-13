Global $FPQUI_REGISTRAR_PATH = @ScriptDir&"\FP-QUIRegistrar.exe"

Func _register($promptUser=Default, $dir=Default, $exe=Default, $coreExe=Default)
	
	If $promptUser == Default Then $promptUser = ""
	If $dir == Default Then $dir = ""
	If $exe == Default Then $exe = ""
	If $coreExe == Default Then $coreExe = ""
	
	Local $arguments = "<mode>register</mode>"& _ 
					   "<promptUser>"&$promptUser&"</promptUser>"& _ 
					   "<dir>"&$dir&"</dir>"& _ 
					   "<exe>"&$exe&"</exe>"& _ 
					   "<coreExe>"&$coreExe&"</coreExe>"
					   
	Local $return
	$return = RunWait($FPQUI_REGISTRAR_PATH&" "&$arguments)
	
	If $return <> 0 Then Return SetError(1, 0, $return)
	
EndFunc

Func _deregister($promptUser=Default)
	
	If $promptUser == Default Then $promptUser = ""
	
	Local $arguments = "<mode>deregister</mode>"& _ 
					   "<promptUser>"&$promptUser&"</promptUser>"
					   
	Local $return
	$return = RunWait($FPQUI_REGISTRAR_PATH&" "&$arguments)
	
	If $return <> 0 Then Return SetError(1, 0, $return)	

EndFunc