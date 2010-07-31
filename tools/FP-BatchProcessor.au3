;syntax: <run><cmd>[cmd]</cmd></run><runwait><cmd>[cmd]</cmd><timeout>[timeout]</timeout></runwait><runwait> ...

#include <_run.au3>
#include <_commandLineInterpreter.au3>

$intructions=_commandLineInterpreter($CmdLineRaw)

For $i=0 To UBound($intructions)-1
	
	Local $currentInstruction=_commandLineInterpreter($intructions[$i][1],"cmd;timeout")
	
	Switch $intructions[$i][0]
		
	Case "run"
		_run($currentInstruction[0][1])
		
	Case "runWait"
		_runWait($currentInstruction[0][1],Default,Default,Default,$currentInstruction[1][1])
		
	EndSwitch
	
Next