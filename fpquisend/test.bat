@echo off
SetLocal EnableExtensions EnableDelayedExpansion

rem ***************************************************************************************************
rem fpquisend sends a WM_COPYDATA message to FP-QUI. Data to send may comes from argv[1] or from stdin.
rem Notes:
rem 1) fpquisend is very small and lightweight process, so it running much faster then FP-QUI.exe call.
rem 2) WM_COPYDATA is very fast way to send data via IPC, and have no limitations to number of clients.
rem 3) WM_COPYDATA can be sent successfully from restricted (user) process to elevated (admin) process.
rem 4) fpquisend sending message but not start FP-QUI. So it will be good idea to use fpquisend in try/
rem    fallback mode like:
rem     set msg="<text>Hello.</text>"
rem     fpquisend %msg% || FP-QUI %msg%
rem    If FP-QUICore.exe is running,use fast fpquisend call, otherwise call FP-QUI to start FP-QUICore.
rem ***************************************************************************************************

:Main
call :SendMessageViaCmdLine
call :SendMessageViaStdInPipe
goto :EOF

:SendMessageViaCmdLine
fpquisend "<text>%date%-%time% - fpquisend - CmdLine - Ok.</text> <delay>15000</delay> <trans>255</trans> <font>Courier New Bold</font> <fontSize>16</fontSize> <bkColor>green</bkColor>"
goto :EOF

:SendMessageViaStdInPipe
set message=""
call :Concat message %message% "<text>%date%-%time% - fpquisend - StdIn - Ok.</text>"
call :Concat message %message% "<delay>15000</delay>"
call :Concat message %message% "<trans>255</trans>"
call :Concat message %message% "<font>Courier New Bold</font>"
call :Concat message %message% "<fontSize>16</fontSize>"
call :Concat message %message% "<bkColor>green</bkColor>"
%ComSpec% /c echo %message% | fpquisend
goto :EOF

:Concat
if "%~1" == "" goto :EOF
set %1="%~2 %~3"
goto :EOF
