@echo off

"%~dp0FP-QUIRegistrar.exe" "<mode>register</mode>"

type "%~dp0data\config_user.ini" > "%~dp0data\config_%UserName%_%ComputerName%.ini"
