#cs 

	arguments:
	<mode>
		register
		deregister

	<dir>
		"" ... Default
	<exe>
		"" ... Default
	<coreExe>
		"" ... Default
	
	<promptUser>
		"" ... Default
		
	exit codes:
	0 ... no error
	1 ... error

#ce

#RequireAdmin

#include <_fpquiRegister.au3>
#include <_commandLineInterpreter.au3>

Global $cmd = _commandLineInterpreter($CmdLineRaw, "mode;dir;exe;coreExe;promptUser")

Global $mode = $cmd[0][1]
Global $dir = $cmd[1][1]
Global $exe = $cmd[2][1]
Global $coreExe = $cmd[3][1]
Global $promptUser = $cmd[4][1]

Switch $mode
	
	Case "register"
	
		If $dir=="" Then $dir = Default
		If $exe=="" Then $exe = Default
		If $coreExe=="" Then $coreExe = Default
		If $promptUser=="" Then $promptUser = Default

		_fpquiRegister($promptUser, $dir, $exe, $coreExe)
		If @error Then Exit(1)
	
	Case "deregister"
	
		_fpquiDeregister($promptUser)
		If @error==2 Then Exit(1)
			
	Case Else
		Exit(1)
	
EndSwitch