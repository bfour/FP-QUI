Global $FPQUI_REGISTRAR_PATH = @ScriptDir&"\FP-QUIRegistrar.exe"

Func _register($promptUser=Default, $dir=Default, $exe=Default, $coreExe=Default, $noWait=Default)
	
	If $promptUser == Default Then $promptUser = ""
	If $dir == Default Then $dir = ""
	If $exe == Default Then $exe = ""
	If $coreExe == Default Then $coreExe = ""
	If $noWait == Default Then $noWait = 0
	
	Local $arguments = "<mode>register</mode>"& _ 
					   "<promptUser>"&$promptUser&"</promptUser>"& _ 
					   "<dir>"&$dir&"</dir>"& _ 
					   "<exe>"&$exe&"</exe>"& _ 
					   "<coreExe>"&$coreExe&"</coreExe>"
					   
	Local $return = 0
	If $noWait==1 Then
		Run($FPQUI_REGISTRAR_PATH&" "&$arguments)
		If @error Then $return = 1
	Else
		$return = RunWait($FPQUI_REGISTRAR_PATH&" "&$arguments)
	EndIf
	
	If $return <> 0 Then Return SetError(1, 0, $return)
	
EndFunc

Func _deregister($promptUser=Default, $noWait=Default)
	
	If $promptUser == Default Then $promptUser = ""
	If $noWait == Default Then $noWait = 0
		
	Local $arguments = "<mode>deregister</mode>"& _ 
					   "<promptUser>"&$promptUser&"</promptUser>"
					   
	Local $return = 0
	If $noWait==1 Then
		Run($FPQUI_REGISTRAR_PATH&" "&$arguments)
		If @error Then $return = 1
	Else
		$return = RunWait($FPQUI_REGISTRAR_PATH&" "&$arguments)
	EndIf
	
	If $return <> 0 Then Return SetError(1, 0, $return)	

EndFunc