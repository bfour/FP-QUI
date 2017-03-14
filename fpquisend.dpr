 {
 Copyright(c) Alexey Kuryakin 2017, <kouriakine@mail.ru>, RU, LGPL.
 fpquisend - program to send message WM_COPYDATA to FP-QUI process.
 FP-QUI is nice tooltip notification system made by Florian Pollak.
 FP-QUI Copyright 2010-2017 Florian Pollak (bfourdev@gmail.com).
 Notes:
 1) WM_COPYDATA is very fast way of IPC (interprocess communications).
 2) WM_COPYDATA access have no restriction for number of clients. The
    messages may comes from any process (on the localhost of course).
 3) fpquisend is very small and lightweight program so fpquisend call
    much faster compare to FP-QUI.exe.  If FP-QUICore.exe is running,
    it's better to call fpquisend to avoid CPU overload.
 4) fpquisend can be called in try/fallback mode like:
      set msg="<text>Hello.</text>"
      fpquisend %msg% || FP-QUI.exe %msg%
    If FP-QUICore.exe is running, call fpquisend (it's much faster).
    In case of FP-QUICore.exe not running, call FP-QUI.exe to start.
 5) fpquisend may send data coming from first Command Line argument.
 6) Also fpquisend may send data coming from StdIn, i.e. console or
    file or pipe - if command line arguments is empty.
 7) So why not to use fpquisend?
 8) Compiled with Delphi 5.0.
 }
program fpquisend;

{$APPTYPE CONSOLE}

{$ALIGN             OFF}    {$BOOLEVAL          OFF}    {$ASSERTIONS        ON}
{$DEBUGINFO         ON}     {$DEFINITIONINFO    ON}     {$EXTENDEDSYNTAX    ON}
{$LONGSTRINGS       ON}     {$HINTS             ON}     {$IOCHECKS          OFF}
{$WRITEABLECONST    ON}     {$LOCALSYMBOLS      ON}     {$MINENUMSIZE       1}
{$OPENSTRINGS       ON}     {$OPTIMIZATION      ON}     {$OVERFLOWCHECKS    OFF}
{$RANGECHECKS       OFF}    {$REALCOMPATIBILITY OFF}    {$STACKFRAMES       OFF}
{$TYPEDADDRESS      OFF}    {$TYPEINFO          ON}     {$VARSTRINGCHECKS   OFF}
{$WARNINGS          ON}

uses Windows,Messages,tlhelp32;

{$R *.RES}

const CRLF       = #13#10;                    // Line delimiter uses in Win32
const fpQuiMagic = $21495551;                 // Uses to identify WM_COPYDATA = 558454097 = dump('QUI!')
const fpQuiClass = 'AutoIt v3 GUI';           // Expected FP-QUI window class
const fpQuiTitle = 'FP-QUI/dispatcherWindow'; // Expected FP-QUI window title
const fpQuiExeId = 'FP-QUICore.exe';          // Expected FP-QUI EXE filename
const ProgramId  = 'fpquisend';               // Program name identifier
const sAbout     = ProgramId+' Copyright(c) Alexey Kuryakin, 2017 <kouriakine@mail.ru>.'+CRLF
                  +ProgramId+' - program to send message WM_COPYDATA to FP-QUI process.'+CRLF
                  +'Data to send may come from stdin or may be specified as parameter.'+CRLF
                  +'FP-QUI is nice tooltip notification system made by Florian Pollak.'+CRLF
                  +'FP-QUI Copyright(c) 2010-2017 Florian Pollak (bfourdev@gmail.com).'+CRLF
                  +'Usage: '+CRLF
                  +' '+ProgramId+ ' [-o [p]] [d]'+CRLF
                  +' -o - option identifier'+CRLF
                  +' p  - option parameter'+CRLF
                  +' d  - data to send'+CRLF
                  +'Options:'+CRLF
                  +' -h, --help     - show help screen'+CRLF
                  +' -v, --verbose  - set verbose mode'+CRLF
                  +' -b, --binary   - set binary  mode'+CRLF
                  +' -c, --class c  - set window class c'+CRLF
                  +' -t, --title t  - set window title t'+CRLF
                  +' -e, --exe   f  - set exe filename f'+CRLF
                  +' -m, --magic n  - set magic number n'+CRLF
                  +' -d, --data  d  - set data to send d'+CRLF
                  +' -l, --log   l  - set log filename l'+CRLF
                  +'Exit codes:'+CRLF
                  +' 0 - data sent successfully'+CRLF
                  +' 1 - target window not found'+CRLF
                  +' 2 - unexpected exe filename'+CRLF
                  +' 3 - nothing to send, i.e. empty data'+CRLF
                  +' 4 - send operation failed or refused'+CRLF
                  +' 5 - invalid parameters was specified'+CRLF
                  +' 6 - general fault'+CRLF
                  +'Examples:'+CRLF
                  +' 1) Help: '+ProgramId+' --help '+CRLF
                  +' 2) Args: '+ProgramId+' "<text>Hello world.</text>"'+CRLF
                  +' 3) Pipe: cmd /c echo "<text>Hello world.</text>" | '+ProgramId+CRLF
                  +' 4) Logs: '+ProgramId+' -v -l %temp%\'+ProgramId+'.log "<text>Hello world.</text>"'+CRLF
                  +'';

///////////////////////////
// General purpose routines
///////////////////////////

 // Convert integer to string
function IntToStr(i:Integer):AnsiString;
begin
 Str(i,Result);
end;

 // Convert integer to string with leading zeros to given width
function IntToStrZ(i,w:Integer):AnsiString;
begin
 Str(i,Result); while Length(Result)<w do Result:='0'+Result;
end;

 // Convert string to integer or return default on error
function iValDef(const S:AnsiString; Def:Int64):Int64;
var code:Integer;
begin
 Val(S, Result, code);
 if code <> 0 then Result := Def;
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
 if I>L then Result:='' else begin
  while S[L] in Spaces do Dec(L);
  Result:=Copy(S,I,L-I+1);
 end;
end;

 // Check if string contains relative file path
function IsRelativePath(const S:AnsiString):Boolean;
var i:Integer;
begin
 Result:=false;
 for i:=1 to length(S) do begin                // relative path is \??? or ?:???
  if S[i]<=' ' then continue;                  // pass leading spaces
  if S[i] in ['\','/'] then exit;              // first char "\" or "/" means root directory
  if (i<Length(S)) and (S[i+1]=':') then exit; // second char ":" means drive specified
  Result:=true;                                // other first char means relative path
  break;
 end;
end;

 // Attach a char to tail of string if one not present yet
function AttachTailChar(const S:AnsiString; c:Char):AnsiString;
begin
 Result:=S;
 if Length(Result)>0 then
 if Result[Length(Result)]<>c then Result:=Result+c;
end;

 // ExpandFileName expands the given filename to a fully qualified filename.
function ExpandFileName(const FileName:AnsiString):AnsiString;
var FName:PChar; Buffer:array[0..MAX_PATH-1] of Char;
begin
 SetString(Result,Buffer,GetFullPathName(PChar(FileName),SizeOf(Buffer),Buffer,FName));
end;

 // Get current directory
function GetCurrentDir:AnsiString;
var Buffer:array[0..MAX_PATH-1] of Char;
begin
 SetString(Result,Buffer,GetCurrentDirectory(SizeOf(Buffer),Buffer));
end;

 // Return program directory
function HomeDir:AnsiString;
var i:Integer;
begin
 Result:=ParamStr(0);
 for i:=Length(Result) downto 1 do
 if Result[i] in ['\','/'] then begin
  Result:=Copy(Result,1,i-1);
  break;
 end;
end;

//////////////////
// WinApi routines
//////////////////

 // Get process ID by window handle
function GetWindowProcessId(hWnd:HWND):DWORD;
begin
 if IsWindow(hWnd) then GetWindowThreadProcessId(hWnd,@Result) else Result:=0;
end;

 // Get window handle of current process console
function GetConsoleWindow:HWND;
const _GetConsoleWindow:function:HWND stdcall = nil;
begin
 if not Assigned(_GetConsoleWindow) then @_GetConsoleWindow:=GetProcAddress(GetModuleHandle('kernel32.dll'),'GetConsoleWindow');
 if Assigned(_GetConsoleWindow) then Result:=_GetConsoleWindow else Result:=0;
 if (Result<>0) then if not IsWindow(Result) then Result:=0;
end;

 // Get file attributes
function GetFileAttr(const FileName:AnsiString):DWORD;
begin
 Result:=GetFileAttributes(PChar(FileName));
end;

 // Check if file exists
function FileExists(const FileName:AnsiString):Boolean;
const INVALID_FILE_ATTRIBUTES=DWORD(-1);
begin
 if Length(FileName)>0
 then Result:=(GetFileAttributes(PChar(FileName))<>INVALID_FILE_ATTRIBUTES)
 else Result:=false;
end;

 // FileSearch searches for the file given by Name in the list of directories given by DirList.
function FileSearch(const Name,DirList:AnsiString):AnsiString;
var I,P,L:Integer;
begin
 Result:=Name; P:=1;
 L:=Length(DirList);
 while true do begin
  if FileExists(Result) then exit;
  while (P<=L) and (DirList[P]=';') do Inc(P);
  if P>L then Break;
  I:=P; while (P<=L) and (DirList[P]<>';') do Inc(P);
  Result:=ExpandFileName(AttachTailChar(Copy(DirList,I,P-I),'\')+Name);
 end;
 Result:='';
end;

 // Read a string from registry
function ReadReqistryString(RootKey:DWORD; const Path,Name:AnsiString):AnsiString;
var key:HKEY; DataType,BufSize:DWORD; Buffer:array[0..MAX_PATH-1] of char;
begin
 Result:='';
 if RegOpenKeyEx(RootKey,PChar(Path),0,KEY_READ,Key)=ERROR_SUCCESS then
 try
  BufSize:=SizeOf(Buffer); FillChar(Buffer,SizeOf(Buffer),0);
  if RegQueryValueEx(Key,PChar(Name),nil,@DataType,PByte(@Buffer),@BufSize)=ERROR_SUCCESS then
  if (DataType=REG_SZ) and (BufSize>0) and (BufSize<SizeOf(Buffer)) then Result:=Buffer;
 finally
  RegCloseKey(Key);
 end;
end;

 // Get exe filename by process ID
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

 // Find process ID (first of them) by exe filename
function FindProcessPid(const exe:AnsiString):DWORD;
var NextProc:Boolean; SnapHandle:THandle; ProcEntry:TProcessEntry32;
begin
 Result:=0;
 if Length(exe)>0 then begin
  SnapHandle:=CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0);
  if (SnapHandle<>0) and (SnapHandle<>INVALID_HANDLE_VALUE) then
  try
   ProcEntry.dwSize:=SizeOf(ProcEntry);
   NextProc:=Process32First(SnapHandle,ProcEntry);
   while NextProc do begin
    if AnsiSameText(exe,ProcEntry.szExeFile) then begin
     Result:=ProcEntry.th32ProcessID;
     Break;
    end;
    NextProc:=Process32Next(SnapHandle,ProcEntry);
   end;
  finally
   CloseHandle(SnapHandle);
  end;
 end;
end;

const
 EnvBuffSize=1024*32;
 
 // Get environment variable
function GetEnv(const Name:AnsiString):AnsiString;
var nSize,nLeng:DWORD; Buff:PChar;
begin
 Result:='';
 try
  nSize:=EnvBuffSize;
  GetMem(Buff,nSize);
  try
   if Assigned(Buff) then begin
    nLeng:=GetEnvironmentVariable(PChar(Name),Buff,nSize);
    if (nLeng>0) and (nLeng<nSize) then Result:=Buff;
   end;
  finally
   FreeMem(Pointer(Buff));
  end;
 except
  Result:='';
 end;
end;

 // Set environment variable
function SetEnv(const Name,Value:AnsiString):Boolean;
begin
 Result:=SetEnvironmentVariable(PChar(Name),PChar(Value));
end;

 // Expand environment variable
function ExpEnv(const Str:AnsiString):AnsiString;
var nSize,nLeng:DWORD; Buff:PChar;
begin
 Result:=Str;
 if Length(Result)>0 then
 if (Pos('%',Result)>0) or (Pos('!',Result)>0) then
 try
  nSize:=EnvBuffSize;
  GetMem(Buff,nSize);
  try
   if Assigned(Buff) then begin
    nLeng:=ExpandEnvironmentStrings(PChar(Str),Buff,nSize);
    if (nLeng>0) and (nLeng<nSize) then Result:=Buff;
   end;
  finally
   FreeMem(Pointer(Buff));
  end;
 except
  Result:='';
 end;
end;

 // Send WM_COPYDATA message to window and return result from target handler
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

////////////////////////////////
// Application specific routines
////////////////////////////////

const theClass : AnsiString = fpQuiClass;                                    // The target window class
const theTitle : AnsiString = fpQuiTitle;                                    // The target window title
const theExeId : AnsiString = fpQuiExeId;                                    // The target exe filename
const theMagic : Int64      = fpQuiMagic;                                    // The identifier number
const verbose  : Boolean    = false;                                         // Verbose debug print mode
const binary   : Boolean    = false;                                         // Binary mode for pipe data
const theParam : AnsiString = '';                                            // Command line parameter
const theLog   : AnsiString = '';                                            // Log file name
const theOut   : AnsiString = '';

type
 Exception = class(TObject);
 EFailure = class(Exception)
  constructor Create(aErrorCode:Cardinal);
 public
  ErrorCode:Cardinal;
 end;
 
constructor EFailure.Create(aErrorCode:Cardinal);
begin
 inherited Create;
 ErrorCode:=aErrorCode;
end;

function PrintLog(const Log,Str:AnsiString):Boolean;
var F:Text; t:TSystemTime;
begin
 Result:=false;
 if Length(Log)>0 then
 if Length(Str)>0 then begin
  Assign(F,Log);
  try
   IOResult;
   GetSystemTime(t);
   if FileExists(Log) then Append(F) else Rewrite(F);
   if IOResult=0 then writeln(F,IntToStrZ(t.wYear,4)+'.'+IntToStrZ(t.wMonth,2)+'.'+IntToStrZ(t.wDay,2)+'-'
                               +IntToStrZ(t.wHour,2)+':'+IntToStrZ(t.wMinute,2)+':'+IntToStrZ(t.wSecond,2)+'=> '+Str);
  finally
   Close(F);
   IOResult;
  end;
 end;
end;

procedure Print(const S:AnsiString; verb:Boolean=false);
begin
 if IsConsole then writeln(S) else
 if verb or verbose then theOut:=theOut+S+CRLF;
 if Length(theLog)>0 then PrintLog(theLog,S)
end;

 // Report error and exit process with given exit code
procedure Failure(code:Cardinal; msg:AnsiString);
begin
 if Length(msg)>0 then Print('Failure: '+msg);
 raise EFailure.Create(code);
 ExitCode:=code;
 Halt;
end;

 // Report success and set process exit code
procedure Success(code:Cardinal; msg:AnsiString);
begin
 if Length(msg)>0 then Print('Success: '+msg);
 ExitCode:=code;
end;

 // Show help screen end exit process
procedure Usage(code:Cardinal=0);
begin
 Print(sAbout,true);
 raise EFailure.Create(code);
 ExitCode:=code;
 Halt;
end;

/////////////////////////////////
// Main application functionality
/////////////////////////////////

function GetFpQuiReg(const Name:AnsiString):AnsiString;                      // Get FP-QUI parameter
begin                                                                        // from registry string
 Result:=ReadReqistryString(HKEY_LOCAL_MACHINE,'SOFTWARE\FP-QUI',Name);      // HKEY_LOCAL_MACHINE\SOFTWARE\FP-QUI\Name
end;                                                                         // 

function FindFpQuiFile(dir,exe,fallbackexe:AnsiString):AnsiString;           // Find FP-QUI file name from registry
var path:AnsiString;                                                         // or from usual locations
 procedure AttachDir(var path:AnsiString; dir,subdir:AnsiString);            // Attach dir\subdir to search path
 begin                                                                       // 
  if (Length(dir)>0) and FileExists(dir) then begin                          // If dir directory exists
   if Length(subdir)>0 then dir:=AttachTailChar(dir,'\')+subdir;             // and dir\subdir exists
   if FileExists(dir) then path:=AttachTailChar(path,';')+ExpandFileName(dir); // then attach to path
  end;                                                                       // 
  path:=AttachTailChar(path,';')                                             // 
 end;                                                                        // 
begin                                                                        // 
 Result:=''; path:=''; dir:=GetFpQuiReg(dir); exe:=GetFpQuiReg(exe);         // Try registry entries first
 if (Length(dir)>0) and (Length(exe)>0)                                      // If registry entries found
 then Result:=ExpandFileName(AttachTailChar(dir,'\')+exe);                   // Expand full filename
 if FileExists(Result) then exit else Result:='';                            // 
 AttachDir(path,GetEnv('ProgramFiles'),'FP-QUI');                            // Try %ProgramFiles%\FP-QUI
 AttachDir(path,GetEnv('ProgramFiles(x86)'),'FP-QUI');                       // Try %ProgramFiles(x86)%\FP-QUI
 AttachDir(path,GetEnv('CommonProgramFiles'),'FP-QUI');                      // Try %CommonProgramFiles%\FP-QUI
 AttachDir(path,GetEnv('CommonProgramFiles(x86)'),'FP-QUI');                 // Try %CommonProgramFiles(x86)%\FP-QUI
 AttachDir(path,'.','');  AttachDir(path,'.','FP-QUI');                      // Try current directory .\  .\FP-QUI
 AttachDir(path,'..',''); AttachDir(path,'..','FP-QUI');                     // Try parent  directory ..\ ..\FP-QUI
 path:=AttachTailChar(path,';')+GetEnv('PATH');                              // And standard environment PATH
 Result:=FileSearch(fallbackexe,path);                                       // Search fallback exe in search path
 if FileExists(Result) then exit else Result:='';                            // 
end;                                                                         //

function GetFpQuiExe:AnsiString;                                             // Get FP-QUI.exe file name
begin                                                                        // 
 Result:=FindFpQuiFile('dir','exe','FP-QUI.exe');                            // Find in registry or in usual locations
end;                                                                         //

function GetFpQuiCoreExe:AnsiString;                                         // Get FP-QUICore.exe file name
begin                                                                        // 
 Result:=FindFpQuiFile('dir','coreExe',fpQuiExeId);                          // Find in registry or in usual locations
end;                                                                         //

function RunFpQuiExe(WaitTimeOut:DWORD=INFINITE):DWORD;                      // Run FP-QUI.exe and wait initialization
var exe:AnsiString; si:STARTUPINFO; pi:PROCESS_INFORMATION; tick:DWORD;      // 
begin                                                                        // 
 Result:=0; exe:=GetFpQuiCoreExe;                                            // Read exe filename from registry
 if (Length(exe)>0) and FileExists(exe) then begin                           // If one exist
  ZeroMemory(@si,sizeof(si)); si.cb:=sizeof(si);                             // Prepare startup info record
  si.dwFlags:=STARTF_USESHOWWINDOW; si.wShowWindow:=SW_SHOW;                 // Set show mode
  if CreateProcess(PChar(exe),nil,nil,nil,FALSE,0,nil,nil,si,pi) then begin  // Create process
   Result:=pi.dwProcessId; WaitForInputIdle(pi.hProcess,WaitTimeOut);        // Wait some time while FP-QUI initialize
   tick:=GetTickCount;                                                       // 
   while (GetTickCount-tick<WaitTimeOut)                                     // Wait until  timeout
   and not IsWindow(FindWindowEx(0,0,PChar(theClass),PChar(theTitle)))       // or window initialized
   do Sleep(1);                                                              // 
   CloseHandle(pi.hProcess); CloseHandle(pi.hThread);                        // Close process handles
  end;                                                                       // 
  if verbose then if Result<>0                                               // Report result
  then Print('Launch "'+exe+'" PID '+IntToStr(Result))                       // 
  else Print('Failed "'+exe+'"');                                            // 
 end;                                                                        // 
end;                                                                         // 

function GetDataToSend:AnsiString;                                           // Get data to send from the
var stdin:THandle; buff:array[0..255] of char; dwLen:DWORD; s:AnsiString;    // Command Line or from StdIn
begin                                                                        // 
 Result:=TrimSpacesQuotes(theParam);                                         // Try to read Command Line argv[1]
 if (Length(Result)=0) and IsConsole then begin                              // or from StdIn if console exist
  stdin:=GetStdHandle(STD_INPUT_HANDLE);                                     // Try to read StdIn if empty argv[1]
  while ReadFile(stdin,buff,sizeof(buff),dwLen,nil) do begin                 // Read until end of file
   if dwLen>0 then SetString(s,buff,dwLen) else break;                       // Read buffer
   Result:=Result+s;                                                         // Add buffer
  end;                                                                       //
  if not binary then Result:=TrimSpacesQuotes(Result);                       // Remove lead/tail spaces/quotes
 end;                                                                        // 
 if verbose then Print('--data='+Result);                                    // Debug print
end;                                                                         //

procedure ParseArguments;                                                    // Parse command line parameters
var i,Count:Integer; Param:AnsiString;                                       // 
begin                                                                        // 
 Count:=ParamCount; i:=1;                                                    // 
 while i <= Count do begin                                                   // For each parameter
  Param:=ParamStr(i);                                                        // Get command line parameter [i]
  if AnsiSameText(Param,'/?') or AnsiSameText(Param,'-?') then Usage(0);     // Option /?, -?
  if AnsiSameText(Param,'-h') or AnsiSameText(Param,'--help') then Usage(0); // Option -h, --help
  if AnsiSameText(Param,'-v') or AnsiSameText(Param,'--verbose') then begin  // Option -v, --verbose
   verbose:=true; inc(i); continue;                                          // Set verbose mode
  end;                                                                       // 
  if AnsiSameText(Param,'-l') or AnsiSameText(Param,'--log') then begin      // Option -l, --log
   inc(i); theLog:=ParamStr(i); inc(i); continue;                            // Set log filename
  end;                                                                       // 
  if AnsiSameText(Param,'-b') or AnsiSameText(Param,'--binary') then begin   // Option -b, --binary
   binary:=true; inc(i); continue;                                           // Set binary mode
  end;                                                                       // 
  if AnsiSameText(Param,'-d') or AnsiSameText(Param,'--data') then begin     // Option -d, --data
   inc(i); theParam:=ParamStr(i); inc(i); continue;                          // Assign data to send
  end;                                                                       // 
  if AnsiSameText(Param,'-c') or AnsiSameText(Param,'--class') then begin    // Option -c, --class
   inc(i); theClass:=ParamStr(i); inc(i); continue;                          // Assign window class
  end;                                                                       // 
  if AnsiSameText(Param,'-t') or AnsiSameText(Param,'--title') then begin    // Option -t, --title
   inc(i); theTitle:=ParamStr(i); inc(i); continue;                          // Assign window title
  end;                                                                       // 
  if AnsiSameText(Param,'-e') or AnsiSameText(Param,'--exe') then begin      // Option -e, --exe
   inc(i); theExeId:=ParamStr(i); inc(i); continue;                          // Assign exe filename
  end;                                                                       // 
  if AnsiSameText(Param,'-m') or AnsiSameText(Param,'--magic') then begin    // Option -m, --magic
   inc(i); theMagic:=iValDef(ParamStr(i),-1); inc(i); continue;              // Assign magic number
  end;                                                                       // 
  if Length(theParam)=0 then theParam:=Param                                 // Message to send is
  else Failure(5,'Invalid call syntax. Help: '+ProgramId+' --help.');        // first non-option
  inc(i);                                                                    // 
 end;                                                                        // 
 if Length(theLog)>0 then theLog:=ExpandFileName(ExpEnv(theLog));            // Find full log filename
end;                                                                         // 

procedure CheckParameters;                                                   // Check parameters is valid
begin                                                                        // 
 if verbose then begin                                                       // Debug print on verbose  flag
  Print('--class='+theClass); Print('--title='+theTitle);                    //
  Print('--exe='+theExeId);   Print('--magic='+IntToStr(theMagic));          //
 end;                                                                        //
 if Length(theClass)=0                                                       // Check window class
 then Failure(5,'Invalid window class. Help: '+ProgramId+' --help.');        // Halt on errors
 if Length(theTitle)=0                                                       // Check window title
 then Failure(5,'Invalid window title. Help: '+ProgramId+' --help.');        // Exit on errors
 if Length(theExeId)=0                                                       // Check exe filename
 then Failure(5,'Invalid exe filename. Help: '+ProgramId+' --help.');        // Halt on error
 if theMagic<0                                                               // Check magic number
 then Failure(5,'Invalid magic number. Help: '+ProgramId+' --help.');        // Halt on errors
end;                                                                         // 

procedure SendMessageToFpQui;                                                // Send WM_COPYDATA message to FP-QUI
var hWin:HWND; pid:DWORD; exe,data:AnsiString;                               // 
begin                                                                        // 
 hWin:=FindWindowEx(0,0,PChar(theClass),PChar(theTitle));                    // Find FP-QUI window by Class, Title
 if not IsWindow(hWin) then begin                                            // If not found, and QUI not running yet
  if FindProcessPid(fpQuiExeId)=0 then RunFpQuiExe(10000);                   // then try to run FP-QUICore.exe process
  hWin:=FindWindowEx(0,0,PChar(theClass),PChar(theTitle));                   // and try to find FP-QUI window again
 end;                                                                        // 
 if not IsWindow(hWin) then Failure(1,'FP-QUI window not found.');           // Report fail - window was not found
 pid:=GetWindowProcessId(hWin); exe:=GetExeNameByPid(pid);                   // Find process PID and EXE by window
 if not AnsiSameText(exe,theExeId) then Failure(2,'Unexpected EXE name.');   // Report fail if EXE name unexpected
 data:=GetDataToSend;  if Length(data)=0 then Failure(3,'Nothing to send.'); // Get data to send from command line
 if wmCopyDataSend(hWin,PChar(data),Length(data)+1,theMagic)>0               // Try to send WM_COPYDATA and report
 then Success(0,'Sent char['+IntToStr(Length(data)+1)+'] message to '+exe+' PID '+IntToStr(pid))
 else Failure(4,'Lost char['+IntToStr(Length(data)+1)+'] message to '+exe+' PID '+IntToStr(pid));  
end;

begin
 try
  ParseArguments;
  CheckParameters;
  SendMessageToFpQui;
 except
  on E:EFailure do ExitCode:=E.ErrorCode;
  else ExitCode:=6;
 end;
 if not IsConsole and (Length(theOut)>0) then begin
  if ExitCode=0
  then MessageBox(0,PChar(theOut),ProgramId+': Information',MB_OK+MB_ICONINFORMATION)
  else MessageBox(0,PChar(theOut),ProgramId+': Error found',MB_OK+MB_ICONERROR);
 end;
end.
