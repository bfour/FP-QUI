 {
 Copyright(c) Alexey Kuryakin 2017, <kouriakine@mail.ru>, RU, LGPL.
 fpquisend - program to send message WM_COPYDATA to FP-QUI process.
 FP-QUI is nice tooltip notification system made by Florian Pollak.
 FP-QUI Copyright 2010-2017 Florian Pollak (bfourdev@gmail.com).
 Notes:
 1) WM_COPYDATA is very fast way of IPC (interprocess communications).
 2) WM_COPYDATA may be send successfully from restricted user process
    to elevated (admin rights) process. If FP-QUI run as another user
    WM_COPYDATA will work fine any case while named pipe may fails.
 3) WM_COPYDATA access have no restriction for number of clients. The
    messages may comes from any process (on the localhost of course).
 4) fpquisend is very small and lightweight program so fpquisend call
    much faster compare to FP-QUI.exe.  If FP-QUICore.exe is running,
    it's better to call fpquisend to avoid CPU overload.
 5) fpquisend can be called in try/fallback mode like:
      set msg="<text>Hello.</text>"
      fpquisend %msg% || FP-QUI.exe %msg%
    If FP-QUICore.exe is running, call fpquisend (it's much faster).
    In case of FP-QUICore.exe not running, call FP-QUI.exe to start.
 6) fpquisend may send data coming from first Command Line argument.
 7) Also fpquisend may send data coming from StdIn, i.e. console or
    file or pipe - if command line arguments is empty.
 8) So why not to use fpquisend?
 9) Compiled with Delphi 5.0.
 }
program fpquisend;

{$APPTYPE CONSOLE}

uses Windows,Messages,tlhelp32;

{$R *.RES}

const CRLF       = #13#10;                    // Line delimiter uses in Win32
const fpQuiMagic = $21495551;                 // Uses to identify WM_COPYDATA = 558454097
const fpQuiClass = 'AutoIt v3 GUI';           // Expected FP-QUI window class
const fpQuiTitle = 'FP-QUI/dispatcherWindow'; // Expected FP-QUI window title
const fpQuiExeId = 'FP-QUICore.exe';          // Expected FP-QUI EXE filename
const sAbout     = 'fpquisend Copyright(c) Alexey Kuryakin, 2017 <kouriakine@mail.ru>.'+CRLF
                  +'fpquisend - program to send message WM_COPYDATA to FP-QUI process.'+CRLF
                  +'FP-QUI is nice tooltip notification system made by Florian Pollak.'+CRLF
                  +'FP-QUI Copyright(c) 2010-2017 Florian Pollak (bfourdev@gmail.com).'+CRLF
                  +'Usage:'+CRLF
                  +' 1) Args: fpquisend "<text>Hello world.</text>"'+CRLF
                  +' 2) Pipe: cmd /c echo "<text>Hello world.</text>" | fpquisend'+CRLF
                  +' 3) Help: fpquisend --help '+CRLF;

 // Convert integer to string
function IntToStr(i:Integer):AnsiString;
begin
 System.Str(i,Result);
end;

 // Compare strings, case insensitive
function AnsiSameText(const S1,S2:AnsiString): Boolean;
begin
 Result:=CompareString(LOCALE_USER_DEFAULT,NORM_IGNORECASE,PChar(S1),Length(S1),PChar(S2),Length(S2))=2;
end;

// Delete leading & trailing spaces & quotes
function TrimSpacesQuotes(const S:AnsiString):AnsiString;
var I,L:Integer; const Spaces=[#0..' ','"',''''];
begin
 L:=Length(S); I:=1;
 while (I<=L) and (S[I] in Spaces) do Inc(I);
 if I>L then Result := '' else begin
  while S[L] in Spaces do Dec(L);
  Result:=Copy(S,I,L-I+1);
 end;
end;

function iValDef(const S:AnsiString; Def:Integer):Integer;
var code:Integer;
begin
 Val(S, Result, code);
 if code <> 0 then Result := Def;
end;

///////////////////
// WinApi utilities
///////////////////
function GetWindowProcessId(hWnd:HWND):DWORD;
begin
 if IsWindow(hWnd) then GetWindowThreadProcessId(hWnd,@Result) else Result:=0;
end;

function GetConsoleWindow:HWND;
const _GetConsoleWindow:function:HWND stdcall = nil;
begin
 if not Assigned(_GetConsoleWindow) then @_GetConsoleWindow:=GetProcAddress(GetModuleHandle('kernel32.dll'),'GetConsoleWindow');
 if Assigned(_GetConsoleWindow) then Result:=_GetConsoleWindow else Result:=0;
 if (Result<>0) then if not IsWindow(Result) then Result:=0;
end;

function GetExeNameByPid(pid:DWORD):AnsiString;
var NextProc:Boolean; SnapHandle:THandle; ProcEntry:TProcessEntry32;
begin
 Result:='';
 if pid<>0 then begin
  SnapHandle:=CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0);
  if (SnapHandle<>0) and (SnapHandle<>INVALID_HANDLE_VALUE) then
  try
   ProcEntry.dwSize:=SizeOf(ProcEntry);
   NextProc:=Process32First(SnapHandle,ProcEntry);
   while NextProc do begin
    if ProcEntry.th32ProcessID=pid then begin
     Result:=TrimSpacesQuotes(ProcEntry.szExeFile);
     Break;
    end;
    NextProc:=Process32Next(SnapHandle,ProcEntry);
   end;
  finally
   CloseHandle(SnapHandle);
  end;
 end;
end;

function GetEnv(const Name:AnsiString):AnsiString;
var Len:Integer; Buff:array[0..MAX_PATH-1] of char;
begin
 Len:=GetEnvironmentVariable(PChar(Name),Buff,SizeOf(Buff));
 if (Len>0) and (Len<SizeOf(Buff)) then Result:=Buff else Result:='';
end;

 // Send WM_COPYDATA
function wmCopyDataSend(hWin:HWND; Data:PChar; Size:Cardinal; aMagic:Cardinal):LRESULT;
var DataRec:TCopyDataStruct;
begin
 Result:=0;
 if Assigned(Data) and (Size>0) and IsWindow(hWin) then begin
  DataRec.dwData:=aMagic;
  DataRec.cbData:=Size;
  DataRec.lpData:=Data;
  Result:=SendMessage(hWin,WM_COPYDATA,GetConsoleWindow,LPARAM(@DataRec));
 end;
end;

 // Get data to send from the Command Line or from StdIn
function GetDataToSend:AnsiString;
var stdin:THandle; buff:array[0..255] of char; dwLen:DWORD; s:AnsiString;
begin
 // Try to read Command Line argv[1]
 Result:=TrimSpacesQuotes(ParamStr(1));
 if Length(Result)>0 then Exit;
 // Try to read StdIn if empty argv[1]
 stdin:=GetStdHandle(STD_INPUT_HANDLE);
 while ReadFile(stdin,buff,sizeof(buff),dwLen,nil) and (dwLen>0) do begin
  SetString(s,buff,dwLen);
  Result:=Result+s;
 end;
 Result:=TrimSpacesQuotes(Result);
end;

procedure Failure(code:Cardinal; msg:AnsiString);
begin
 if Length(msg)>0 then writeln('Failure: '+msg);
 ExitCode:=code;
 Halt;
end;

procedure Success(code:Cardinal; msg:AnsiString);
begin
 if Length(msg)>0 then writeln('Success: '+msg);
 ExitCode:=code;
end;

procedure Usage(code:Cardinal=0);
begin
 writeln(sAbout);
 ExitCode:=code;
 Halt;
end;

 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 // To have possibility to change FP-QUI window settings after compilation, use environment variables:
 // FP-QUI-Window-Class = AutoIt v3 GUI              - window class uses to seach FP-QUI
 // FP-QUI-Window-Title = FP-QUI/dispatcherWindow    - window title uses to seach FP-QUI
 // FP-QUI-Exe-FileName = FP-QUICore.exe             - expected EXE file name of FP-QUI
 // FP-QUI-Magic-Number = 558454097                  - magic number uses to send WM_COPYDATA
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function theClass:AnsiString;                                                // FP-QUI window Class
begin                                                                        // Uses to find FP-QUI window
 Result:=GetEnv('FP-QUI-Window-Class');                                      // Try to get environment FP-QUI-Window-Class
 if Length(Result)=0 then Result:=fpQuiClass;                                // If none, use default
end;                                                                         // Done
function theTitle:AnsiString;                                                // FP-QUI window Title
begin                                                                        // Uses to find FP-QUI window
 Result:=GetEnv('FP-QUI-Window-Title');                                      // Try to get environment FP-QUI-Window-Title
 if Length(Result)=0 then Result:=fpQuiTitle;                                // If none, use default
end;                                                                         // Done
function theExeId:AnsiString;                                                // FP-QUI EXE filename
begin                                                                        // Uses to find FP-QUI window
 Result:=GetEnv('FP-QUI-Exe-FileName');                                      // Try to get environment FP-QUI-Window-Title
 if Length(Result)=0 then Result:=fpQuiExeId;                                // If none, use default
end;                                                                         // Done
function theMagic:Cardinal;                                                  // FP-QUI magic number
begin                                                                        // Uses to send data to FP-QUI window
 Result:=iValDef(GetEnv('FP-QUI-Magic-Number'),0);                           // Try to get environment FP-QUI-Magic-Number
 if Result=0 then Result:=fpQuiMagic;                                        // If none, use default
end;                                                                         // Done
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

procedure SendMessageToFpQui;                                                // Send WM_COPYDATA message to FP-QUI
var hWin:HWND; pid:DWORD; exe,data:AnsiString;                               //
begin                                                                        //
 hWin:=FindWindowEx(0,0,PChar(theClass),PChar(theTitle));                    // Find FP-QUI window by Class, Title
 if not IsWindow(hWin) then Failure(1,'FP-QUI window not found.');           // Report fail - window was not found
 pid:=GetWindowProcessId(hWin); exe:=GetExeNameByPid(pid);                   // Find process PID and EXE by window
 if not AnsiSameText(exe,theExeId) then Failure(2,'Unexpected EXE name.');   // Report fail if EXE name unexpected
 data:=GetDataToSend;  if Length(data)=0 then Failure(3,'Nothing to send.'); // Get data to send from command line
 if wmCopyDataSend(hWin,PChar(data),Length(data)+1,theMagic)>0               // Try to send WM_COPYDATA and report
 then Success(0,'Sent char['+IntToStr(Length(data)+1)+'] message to '+exe+' PID '+IntToStr(pid))
 else Failure(4,'Fail char['+IntToStr(Length(data)+1)+'] message to '+exe+' PID '+IntToStr(pid));  
end;

begin
 if AnsiSameText(ParamStr(1),'/?') then Usage(0);
 if AnsiSameText(ParamStr(1),'-h') then Usage(0);
 if AnsiSameText(ParamStr(1),'--help') then Usage(0);
 if ParamCount>1 then Failure(5,'Invalid call syntax.'+CRLF+'Help on: fpquisend --help.');
 SendMessageToFpQui;
end.
