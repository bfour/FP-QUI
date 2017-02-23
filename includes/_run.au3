#include-once

#include <_error.au3>

Func _run($cmd,$workingDir=Default,$showFlag=Default,$optFlag=Default,$supressErrorHandling=Default)
	
	If $workingDir==Default Then $workingDir=""
	If $showFlag==Default Then $showFlag=Default
	If $optFlag==Default Then $optFlag=Default
	If $supressErrorHandling==Default Then $supressErrorHandling=0
	
	If Not IsDeclared("errorInteractive") Then Local $errorInteractive=Default
	If Not IsDeclared("errorBroadcast") Then Local $errorBroadcast=Default
	If Not IsDeclared("errorLog") Then Local $errorLog=Default
	If Not IsDeclared("errorLogDir") Then Local $errorLogDir=Default
	If Not IsDeclared("errorLogFile") Then Local $errorLogFile=Default
	If Not IsDeclared("errorLogMaxNumberOfLines") Then Local $errorLogMaxNumberOfLines=Default
	If Not IsDeclared("forceMsgBox") Then Local $errorForceMsgBox=Default
	
	Local $PID=Run($cmd)
	If @error<>0 Then 
		If Not $supressErrorHandling Then _error('executing "'&$cmd&'" failed',$errorInteractive,$errorBroadcast,$errorLog,$errorLogDir,$errorLogFile,$errorLogMaxNumberOfLines,$errorForceMsgBox)
		SetError(1)
	EndIf

	Return $PID

EndFunc

Func _runWait($cmd,$workingDir=Default,$showFlag=Default,$optFlag=Default,$timeout=Default)
	
	If $timeout==Default Then $timeout=""
	
	Local $PID=_run($cmd)
	Local $timer=TimerInit()

	If Not IsDeclared("errorInteractive") Then Local $errorInteractive=Default
	If Not IsDeclared("errorBroadcast") Then Local $errorBroadcast=Default
	If Not IsDeclared("errorLog") Then Local $errorLog=Default
	If Not IsDeclared("errorLogDir") Then Local $errorLogDir=Default
	If Not IsDeclared("errorLogFile") Then Local $errorLogFile=Default
	If Not IsDeclared("errorLogMaxNumberOfLines") Then Local $errorLogMaxNumberOfLines=Default
	If Not IsDeclared("forceMsgBox") Then Local $errorForceMsgBox=Default


	While ProcessExists($PID)<>0
		
		If $timeout<>"" And TimerDiff($timer)>=$timeout Then
			
			_error('timeout of '&$timeout&'ms exeeded when executing "'&$cmd&'"',$errorInteractive,$errorBroadcast,$errorLog,$errorLogDir,$errorLogFile,$errorLogMaxNumberOfLines,$errorForceMsgBox)			
			SetError(1)
			ExitLoop
			
		EndIf
				
		Sleep(250)
		
	WEnd
	
	Return $PID

EndFunc