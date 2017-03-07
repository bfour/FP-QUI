@echo off
set prog=send2crwdaq
pushd "%~dp0." && (
 del /f /q %prog%.map
 del /f /q %prog%.~res
 ..\..\bin\filecase /l %prog%.exe
 copy /Y /V %prog%.exe ..\..\bin\
)
popd