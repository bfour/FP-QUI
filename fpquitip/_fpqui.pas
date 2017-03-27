 {
 ****************************************************************************
 CRW32 project
 Copyright (C) by Kuryakin Alexey, Sarov, Russia, 2017, <kouriakine@mail.ru>
 _fpqui is library to work with tooltip windows via FP-QUI package.
 FP-QUI is nice tooltip notification system made by Florian Pollak.
 FP-QUI Copyright 2010-2017 Florian Pollak (bfourdev@gmail.com).
 Modifications:
 20170323 - Creation
 20170324 - First tested release
 ****************************************************************************
 }
unit _fpqui;

{$I-} {$B-} {$R-} // {$O-} {$W+}

interface 

uses Windows,Messages,SysUtils,tlhelp32;

const                                           // Expected FP-QUI target dispatcher window parameters
 fpQuiClass     = 'AutoIt v3 GUI';              // Expected FP-QUI window class
 fpQuiTitle     = 'FP-QUI/dispatcherWindow';    // Expected FP-QUI window title
 fpQuiExeId     = 'FP-QUICore.exe';             // Expected FP-QUI EXE filename
 fpQuiMagic     = $21495551;                    // Uses to identify WM_COPYDATA = 558454097 = dump('QUI!')
 fpQuiTimeOut   = 5000;                         // Default timeout to run FP-QUI
 fpQuiDemoDelay = 1000;                         // Default delay for FP-QUI demo
 
const                                           // FpQuiManager.RunFpQuiTipExe result codes
 EcfpQuiSuccess = 0;                            // Success
 EcFpQuiNoFound = 1;                            // Target window not found
 EcFpQuiFailExe = 2;                            // Unexpected exe filename
 EcFpQuiBadData = 3;                            // Nothing to send, empty data
 EcFpQuiNotSent = 4;                            // Send operation failed or refused
 EcFpQuiBadArgs = 5;                            // Invalid parameters was specified
 EcfpQuiGenFail = 6;                            // General failure

type
 TFpQuiManager = class(TObject)
 private
  myTargetClass  : AnsiString;
  myTargetTitle  : AnsiString;
  myTargetExeId  : AnsiString;
  myTargetMagic  : Int64;
 private
  function    GetTargetClass:AnsiString;    procedure SetTargetClass(const aClass:AnsiString);
  function    GetTargetTitle:AnsiString;    procedure SetTargetTitle(const aTitle:AnsiString);
  function    GetTargetExeId:AnsiString;    procedure SetTargetExeId(const aExeId:AnsiString);
  function    GetTargetMagic:Int64;         procedure SetTargetMagic(const aMagic:Int64);
 public
  // Target FP-QUI window Class, Title, Exe name ID and Magic command ID
  property    TargetClass:AnsiString        read GetTargetClass     write SetTargetClass;
  property    TargetTitle:AnsiString        read GetTargetTitle     write SetTargetTitle;
  property    TargetExeId:AnsiString        read GetTargetExeId     write SetTargetExeId;
  property    TargetMagic:Int64             read GetTargetMagic     write SetTargetMagic;
 private
  myActualWin     : HWND;
  myActualPid     : DWORD;
  myActualExe     : AnsiString;
  myActualExePath : AnsiString;
  myActualWorkDir : AnsiString;
 private
  function    GetActualWin:HWND;
  function    GetActualPid:DWORD;
  function    GetActualExe:AnsiString;
  function    GetActualExePath:AnsiString;
  function    GetActualWorkDir:AnsiString;
 public
  // Actual (found) target FP-QUI window handle, Process ID, Exe name
  property    ActualWin:HWND                read GetActualWin;
  property    ActualPid:DWORD               read GetActualPid;
  property    ActualExe:AnsiString          read GetActualExe;
  property    ActualExePath:AnsiString      read GetActualExePath;
  property    ActualWorkDir:AnsiString      read GetActualWorkDir;
 public
  // Find actual target window, process, exe file
  function    FindFpQuiWindow(const aClass,aTitle,aExeId:AnsiString):HWND;
  function    FindActualTarget(AllowRun:Boolean):Boolean;
 private
  myTimeOut       : Cardinal;
  myDemoDelay     : Cardinal;
  myErrno         : Integer;
 private
  function    GetTimeOut:Cardinal;          procedure SetTimeOut(aTimeOut:Cardinal);
  function    GetDemoDelay:Cardinal;        procedure SetDemoDelay(aDemoDelay:Cardinal);
  function    GetErrno:Integer;             procedure SetErrno(aErrno:Integer);
 public
  // Run timeout, demo delay, last error code
  property    TimeOut:Cardinal              read GetTimeOut         write SetTimeOut;
  property    DemoDelay:Cardinal            read GetDemoDelay       write SetDemoDelay;
  property    errno:Integer                 read GetErrno           write SetErrno;
 private
  myLog          : AnsiString;
  myVerbose      : Boolean;
  myProgramId    : AnsiString;
 private
  function    GetTheLog:AnsiString;         procedure SetTheLog(const aLog:AnsiString);
  function    GetVerbose:Boolean;           procedure SetVerbose(const aVerbose:Boolean);
  function    GetProgramId:AnsiString;      procedure SetProgramId(const aProgramId:AnsiString);
 public
  // Printing and logging features
  property    theLog:AnsiString             read GetTheLog          write SetTheLog;
  property    verbose:Boolean               read GetVerbose         write SetVerbose;
  property    ProgramId:AnsiString          read GetProgramId       write SetProgramId;
  procedure   Print(const S:AnsiString);
  function    PrintLog(const S:AnsiString):Boolean;
  function    Failure(code:Integer; const msg:AnsiString):Integer;
  function    Success(code:Integer; const msg:AnsiString):Integer;
  function    Usage(code:Integer=0):Integer;
 private
  par            : record
   xml           : AnsiString;
   avi           : AnsiString;
   text          : AnsiString;
   verbose       : AnsiString;
   trans         : AnsiString;
   font          : AnsiString;
   fontSize      : AnsiString;
   bkColor       : AnsiString;
   delay         : AnsiString;
   untilClickAny : AnsiString;
   ico           : AnsiString;
   audio         : AnsiString;
   textColor     : AnsiString;
   noDouble      : AnsiString;
   onClick       : AnsiString;
   progress      : AnsiString;
   guid          : AnsiString;
   delete        : AnsiString;
   sure          : AnsiString; // synonym createIfNotVisible
   run           : AnsiString;
   button        : AnsiString;
   btn1,cmd1     : AnsiString;
   btn2,cmd2     : AnsiString;
   btn3,cmd3     : AnsiString;
   btn4,cmd4     : AnsiString;
   btn5,cmd5     : AnsiString;
   btn6,cmd6     : AnsiString;
   btn7,cmd7     : AnsiString;
   btn8,cmd8     : AnsiString;
   btn9,cmd9     : AnsiString;
  end;
 private
  procedure   ClearAll;
  procedure   SetDefaults;
  procedure   PresetStd(const s1,s2,s3,s4,s5,s6,s7:AnsiString);
  procedure   ParseArgumentPair(const s1,s2:AnsiString);
  procedure   PresetParams(const s1:AnsiString);
  procedure   ParseButtons;
  procedure   ColorCheck;
  function    CheckParameters:Integer;
  function    ComposeMessage:AnsiString;
  function    RunFpQuiCoreExe(aTimeOut:DWORD):DWORD;
 public
  // General functions
  function    GetCmdLineArguments:AnsiString;                                           // Read data from command line
  function    ReadFromStdIn(aMaxLeng:Cardinal=1024*64):AnsiString;                      // Read data from StdIn stream
  function    ReadCmdLineOrStdIn(aMaxLeng:Cardinal=1024*64):AnsiString;                 // Read data from Cmd or StdIn
  function    ParseCommandLine(const CmdLine:AnsiString; Skip:Integer=0):AnsiString;    // Main command parser to XML
  function    SendMessage(const data:AnsiString; AllowRun:Boolean=true):Integer;        // Send message to FP-QUI
  function    RunFpQuiTipExe(arg:AnsiString=''):Integer;                                // Read data, parse and send
  function    RunDemo(aDelay:Cardinal=1000):Integer;                                    // Run list of demo commands
  procedure   Cleanup;                                                                  // Cleanup after data sent
 public
  // Registry and file search routines
  function    ReadFpQuiReg(const Name:AnsiString):AnsiString;       // Read HKEY_LOCAL_MACHINE\SOFTWARE\FP-QUI\Name
  function    FindFile(const aFileName:AnsiString):AnsiString;      // Find a file in FP-QUI search locations
  function    FindFpQuiCoreExe:AnsiString;                          // Find FP-QUICore.exe
  function    FindFpQuiExe:AnsiString;                              // Find FP-QUI.exe
 public
  // Constructor/destructor
  constructor Create;
  destructor  Destroy; override;
  procedure   BeforeDestruction; override;
 end;

function FpQuiManager:TFpQuiManager;
procedure Kill(var TheObject:TFpQuiManager); overload;

const // Virtual console and exception handler
 TheFpQuiEchoProcedure : procedure(const Msg:AnsiString) = nil;
 TheFpQuiExceptionHandlerProcedure : procedure(E:Exception) = nil;
 
implementation

///////////////////
// Utility routines
///////////////////

const
 CRLF                           = #13#10;
 EnvBufferSize                  = 1024*32;
 myFpQuiManager : TFpQuiManager = nil;

procedure FpQuiExceptionHandler(E:Exception);
begin
 if Assigned(E) then
 if Assigned(TheFpQuiExceptionHandlerProcedure) then
 try
  TheFpQuiExceptionHandlerProcedure(E);
 except
 end;
end;

procedure Echo(const Msg:AnsiString; const LineBreak:AnsiString=CRLF);
begin
 if Assigned(TheFpQuiEchoProcedure) then
 try
  TheFpQuiEchoProcedure(Msg+LineBreak);
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

function FpQuiManager:TFpQuiManager;
begin
 if not Assigned(myFpQuiManager) then
 try
  myFpQuiManager:=TFpQuiManager.Create;
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
 Result:=myFpQuiManager;
end;

procedure Kill(var TheObject:TFpQuiManager); overload;
var P:TObject;
begin
 if Assigned(TheObject) then
 try
  P:=TheObject; TheObject:=nil; P.Free;  // clear the reference before destroying the object
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

///////////////////////////
// General purpose routines
///////////////////////////

 // Convert integer to string with leading zeros to given width
function IntToStrZ(i,w:Integer):AnsiString;
begin
 Result:=IntToStr(i);
 while Length(Result)<w do Result:='0'+Result;
end;

 // Convert string to integer or return default on error
function iValDef(const S:AnsiString; Def:Int64):Int64;
var code:Integer;
begin
 Val(S,Result,code); if code<>0 then Result:=Def;
end;

type
 TCharSet = set of Char;

// Delete leading & trailing spaces & quotes
function TrimChars(const S:AnsiString; Spaces:TCharSet):AnsiString;
var I,L:Integer;
begin
 L:=Length(S); I:=1;
 while (I<=L) and (S[I] in Spaces) do Inc(I);
 if I>L then Result:='' else begin
  while S[L] in Spaces do Dec(L);
  Result:=Copy(S,I,L-I+1);
 end;
end;

// Delete leading & trailing spaces & quotes
function TrimSpacesQuotes(const S:AnsiString):AnsiString;
begin
 Result:=TrimChars(S,[#0..' ','"','''']);
end;

 // Check if string contains relative file path
function IsRelativePath(const S:AnsiString):Boolean;
var i:Integer;
begin
 Result:=false;
 for i:=1 to Length(S) do begin
  if S[i]<=' ' then continue;
  if S[i] in ['\','/'] then exit;
  if (i<Length(S)) and (S[i+1]=':') then exit;
  Result:=true;
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

 // Return file base name without path & extension
function ExtractFileBaseName(const FileName:AnsiString):AnsiString;
begin
 Result:=ChangeFileExt(ExtractFileName(TrimSpacesQuotes(FileName)),'');
end;

 // Return file directory without trailing backslash
function ExtractFileDirectory(const FileName:AnsiString):AnsiString;
begin
 Result:=ExcludeTrailingBackslash(ExtractFilePath(TrimSpacesQuotes(FileName)));
end;

 // Return program directory
function HomeDir:AnsiString;
begin
 Result:=ExtractFileDirectory(ParamStr(0));
end;

 // Command line parser
function GetNextParamStr(P:PChar; var Param:AnsiString):PChar;
var nSize,Len:DWORD; Buffer:PChar;
begin
 if Assigned(P) then begin
  nSize:=EnvBufferSize;
  GetMem(Buffer,nSize);
  try
   while True do begin
    while (P[0]<>#0) and (P[0]<=' ') do Inc(P);
    if (P[0]='"') and (P[1]='"') then Inc(P,2) else Break;
   end;
   Len:=0;
   while (P[0]>' ') and (Len<nSize) do
   if P[0]='"' then begin
    Inc(P);
    while (P[0]<>#0) and (P[0]<>'"') do begin
     Buffer[Len]:=P[0];
     Inc(Len);
     Inc(P);
    end;
    if P[0]<>#0 then Inc(P);
   end else begin
    Buffer[Len]:=P[0];
    Inc(Len);
    Inc(P);
   end;
   SetString(Param,Buffer,Len);
  finally
   FreeMem(Buffer);
  end;
 end;
 Result:=P;
end;

//////////////////
// WinApi routines
//////////////////

 // Get window title
function GetWindowTitle(hWin:HWND):AnsiString;
var Buffer:array[0..MAX_PATH-1] of Char;
begin
 Result:='';
 if (hWin<>0) and IsWindow(hWin) then SetString(Result,Buffer,GetWindowText(hWin,Buffer,SizeOf(Buffer))); 
end;

 // Get window class
function GetWindowClass(hWin:HWND):AnsiString;
var Buffer:array[0..MAX_PATH-1] of Char;
begin
 Result:='';
 if (hWin<>0) and IsWindow(hWin) then SetString(Result,Buffer,GetClassName(hWin,Buffer,SizeOf(Buffer)));
end;

 // Get process ID by window handle
function GetWindowProcessId(hWin:HWND):DWORD;
begin
 Result:=0;
 if (hWin<>0) and IsWindow(hWin) then GetWindowThreadProcessId(hWin,@Result); 
end;

 // Get window handle of current process console
function GetConsoleWindow:HWND;
const _GetConsoleWindow:function:HWND stdcall = nil;
begin
 if not Assigned(_GetConsoleWindow) then @_GetConsoleWindow:=GetProcAddress(GetModuleHandle('kernel32.dll'),'GetConsoleWindow');
 if Assigned(_GetConsoleWindow) then Result:=_GetConsoleWindow else Result:=0;
 if (Result<>0) then if not IsWindow(Result) then Result:=0;
end;

 // Check directory exists
function DirectoryExists(const Name:AnsiString):Boolean;
var Code:Integer;
begin
 Code:=GetFileAttributes(PChar(Name));
 Result:=(Code<>-1) and (FILE_ATTRIBUTE_DIRECTORY and Code <> 0);
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
    if SameText(exe,ProcEntry.szExeFile) then begin
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

 // Get environment variable
function GetEnv(const Name:AnsiString):AnsiString;
var nSize,nLeng:DWORD; Buff:PChar;
begin
 Result:='';
 try
  nSize:=EnvBufferSize;
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
  nSize:=EnvBufferSize;
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

 // Append directory dir\subdir list to search path
 // Parameter subrirs is semicolon separated list of subdirectories
procedure AppendDirToSearchPath(var path:AnsiString; dir,subdirs:AnsiString);
var p:Integer; subdir:AnsiString;
begin
 dir:=Trim(dir); subdirs:=Trim(subdirs);
 if (Length(dir)>0) and DirectoryExists(dir) then begin
  repeat
   p:=Pos(';',subdirs);
   if p>0 then begin
    subdir:=Trim(Copy(subdirs,1,p-1));
    subdirs:=Trim(Copy(subdirs,p+1,Length(subdirs)-p));
   end else begin
    subdir:=Trim(subdirs);
    subdirs:='';
   end;
   if (Length(subdir)>0) then begin
    subdir:=ExpandFileName(AttachTailChar(dir,'\')+subdir);
    if DirectoryExists(subdir) then begin
     p:=Pos(subdir,path);
     if p>1 then if path[p-1]<>';' then p:=0;
     if p>0 then if p+Length(subdir)<=Length(path) then if path[p+Length(subdir)]<>';' then p:=0;
     if p=0 then path:=AttachTailChar(path,';')+subdir;
    end;
   end;
  until Length(subdirs)=0;
 end;
 path:=AttachTailChar(path,';');
end;

function SHGetSpecialFolderPath(hwndOwner:HWND; lpszPath:PChar;  nFolder:Integer; fCreate:BOOL):BOOL; stdcall;
external 'shell32.dll' name 'SHGetSpecialFolderPathA';
 
 // Get shecial folder path by CSIDL
function GetSpecialShellFolderPath(CSIDL:Word):AnsiString;
var Buff:array[0..MAX_PATH] of Char;
begin
 if SHGetSpecialFolderPath(0,Buff,CSIDL,True) then Result:=Buff else Result:='';
end;

 // Get temporary directory
function GetTempDir:AnsiString;
var Buff:array[0..MAX_PATH] of Char;
begin
 SetString(Result,Buff,GetTempPath(SizeOf(Buff),Buff));
end;

 // Return shared work directory - Common Documents or (as fallback) Common Application Data or TEMP
function GetSharedWorkDir:AnsiString;
const CSIDL_COMMON_DOCUMENTS=46; CSIDL_COMMON_APPDATA=35; // shlobj.h
begin
 Result:='';
 if (Length(Result)=0) or not DirectoryExists(Result) then Result:=GetSpecialShellFolderPath(CSIDL_COMMON_DOCUMENTS);
 if (Length(Result)=0) or not DirectoryExists(Result) then Result:=GetSpecialShellFolderPath(CSIDL_COMMON_APPDATA);
 if (Length(Result)=0) or not DirectoryExists(Result) then Result:=GetEnv('TEMP');
 if (Length(Result)=0) or not DirectoryExists(Result) then Result:=GetTempDir;
 Result:=TrimSpacesQuotes(Result);
 if Length(Result)>0 then if Result[Length(Result)] in ['\','/'] then Result:=Copy(Result,1,Length(Result)-1);
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

/////////////////////////////////////
// TFpQuiManager class implementation
/////////////////////////////////////
constructor TFpQuiManager.Create;
begin
 inherited Create;
 SetDefaults;
 myTimeOut:=fpQuiTimeOut;
 myDemoDelay:=fpQuiDemoDelay;
 ProgramId:=ExtractFileBaseName(ParamStr(0));
end;

destructor TFpQuiManager.Destroy;
begin
 ClearAll;
 inherited Destroy;
end;

procedure TFpQuiManager.BeforeDestruction;
begin
 if Self=myFpQuiManager then myFpQuiManager:=nil;
 inherited BeforeDestruction;
end;

function TFpQuiManager.GetTargetClass:AnsiString;
begin
 if Assigned(Self) then Result:=myTargetClass else Result:='';
end;

procedure TFpQuiManager.SetTargetClass(const aClass:AnsiString);
begin
 if Assigned(Self) then myTargetClass:=aClass;
end;

function TFpQuiManager.GetTargetTitle:AnsiString;
begin
 if Assigned(Self) then Result:=myTargetTitle else Result:='';
end;

procedure TFpQuiManager.SetTargetTitle(const aTitle:AnsiString);
begin
 if Assigned(Self) then myTargetTitle:=aTitle;
end;

function TFpQuiManager.GetTargetExeId:AnsiString;
begin
 if Assigned(Self) then Result:=myTargetExeId else Result:='';
end;

procedure TFpQuiManager.SetTargetExeId(const aExeId:AnsiString);
begin
 if Assigned(Self) then myTargetExeId:=aExeId;
end;

function TFpQuiManager.GetTargetMagic:Int64;
begin
 if Assigned(Self) then Result:=myTargetMagic else Result:=0;
end;

procedure TFpQuiManager.SetTargetMagic(const aMagic:Int64);
begin
 if Assigned(Self) then myTargetMagic:=aMagic;
end;

function TFpQuiManager.GetErrno:Integer;
begin
 if Assigned(Self) then Result:=myErrno else Result:=0;
end;

procedure TFpQuiManager.SetErrno(aErrno:Integer);
begin
 if Assigned(Self) then myErrno:=aErrno;
end;

function TFpQuiManager.GetTimeOut:Cardinal;
begin
 if Assigned(Self) then Result:=myTimeOut else Result:=0;
end;

procedure TFpQuiManager.SetTimeOut(aTimeOut:Cardinal);
begin
 if Assigned(Self) then myTimeOut:=aTimeOut;
end;

function TFpQuiManager.GetDemoDelay:Cardinal;
begin
 if Assigned(Self) then Result:=myDemoDelay else Result:=0;
end;

procedure TFpQuiManager.SetDemoDelay(aDemoDelay:Cardinal);
begin
 if Assigned(Self) then myDemoDelay:=aDemoDelay;
end;

function TFpQuiManager.GetTheLog:AnsiString;
begin
 if Assigned(Self) then Result:=myLog else Result:='';
end;

procedure TFpQuiManager.SetTheLog(const aLog:AnsiString);
begin
 if Assigned(Self) then myLog:=TrimSpacesQuotes(aLog);
end;

function TFpQuiManager.GetVerbose:Boolean;
begin
 if Assigned(Self) then Result:=myVerbose else Result:=false;
end;

procedure TFpQuiManager.SetVerbose(const aVerbose:Boolean);
begin
 if Assigned(Self) then myVerbose:=aVerbose;
end;

function TFpQuiManager.GetProgramId:AnsiString;
begin
 if Assigned(Self) then Result:=myProgramId else Result:='';
end;

function TFpQuiManager.GetActualWin:HWND;
begin
 if Assigned(Self) then Result:=myActualWin else Result:=0;
end;

function TFpQuiManager.GetActualPid:DWORD;
begin
 if Assigned(Self) then Result:=myActualPid else Result:=0;
end;

function TFpQuiManager.GetActualExe:AnsiString;
begin
 if Assigned(Self) then Result:=myActualExe else Result:='';
end;

function TFpQuiManager.GetActualExePath:AnsiString;
begin
 if Assigned(Self) then Result:=myActualExePath else Result:='';
end;

function TFpQuiManager.GetActualWorkDir:AnsiString;
begin
 if Assigned(Self) then Result:=myActualWorkDir else Result:='';
end;

procedure TFpQuiManager.SetProgramId(const aProgramId:AnsiString);
begin
 if Assigned(Self) then myProgramId:=aProgramId;
end;

 // Print time stamp and message to log file if one specified
function TFpQuiManager.PrintLog(const S:AnsiString):Boolean;
var F:Text; t:TSystemTime;
begin
 Result:=false;
 if Length(S)>0 then
 if Assigned(Self) then
 if Length(myLog)>0 then
 try
  Assign(F,myLog);
  try
   IOResult;
   GetSystemTime(t);
   if FileExists(myLog) then Append(F) else Rewrite(F);
   if IOResult=0 then writeln(F,IntToStrZ(t.wYear,4)+'.'+IntToStrZ(t.wMonth,2)+'.'+IntToStrZ(t.wDay,2)+'-'
                               +IntToStrZ(t.wHour,2)+':'+IntToStrZ(t.wMinute,2)+':'+IntToStrZ(t.wSecond,2)+'=> '+S);
  finally
   Close(F);
   IOResult;
  end;
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

 // Print message to virtual console and log file
procedure TFpQuiManager.Print(const S:AnsiString);
begin
 if Assigned(Self) then
 try
  if Length(myLog)>0 then PrintLog(S);
  Echo(S);
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

 // Report error and set error code
function TFpQuiManager.Failure(code:Integer; const msg:AnsiString):Integer;
begin
 Result:=code;
 if Assigned(Self) then begin
  if Length(msg)>0 then Print('Failure: '+msg);
  errno:=code;
 end;
end;

 // Report success and set process error code
function TFpQuiManager.Success(code:Integer; const msg:AnsiString):Integer;
begin
 Result:=code;
 if Assigned(Self) then begin
  if Length(msg)>0 then Print('Success: '+msg);
  errno:=code;
 end;
end;

 // Show help screen end exit process
function TFpQuiManager.Usage(code:Integer=0):Integer;
var sAbout:AnsiString;
begin
 Result:=code;
 if Assigned(Self) then
 try
  sAbout        := ProgramId+' Copyright(c) Alexey Kuryakin, 2017 <kouriakine@mail.ru>.'+CRLF
                  +ProgramId+' - program to show tooltip notifications via FP-QUI.'+CRLF
                  +'Data to show may come from stdin or may be specified as parameter.'+CRLF
                  +'FP-QUI is nice tooltip notification system made by Florian Pollak.'+CRLF
                  +'FP-QUI Copyright(c) 2010-2017 Florian Pollak (bfourdev@gmail.com).'+CRLF
                  +'Usage: '+CRLF
                  +' '+ProgramId+ ' [-o [p]] [d]'+CRLF
                  +' -o - option identifier'+CRLF
                  +' p  - option parameter'+CRLF
                  +' d  - data to send'+CRLF
                  +'Options:'+CRLF
                  +' -h, --help     - show help screen'+CRLF
                  +' -v, --verbose  - set verbose mode   (default OFF)'+CRLF
                  +' -c, --class c  - set window class c (default '+fpQuiClass+')'+CRLF
                  +' -t, --title t  - set window title t (default '+fpQuiTitle+')'+CRLF
                  +' -e, --exe   f  - set exe filename f (default '+fpQuiExeId+')'+CRLF
                  +' -m, --magic n  - set magic number n (default '+Format('$%x',[fpQuiMagic])+')'+CRLF
                  +' -d, --data  d  - set data to send d (specified in XML format)'+CRLF
                  +' -l, --log   l  - set log filename l (default OFF)'+CRLF
                  +'Data [d] specify message to send. '+CRLF
                  +'That is list of pairs NAME VALUE which both must be non-empty.'+CRLF
                  +' NAME           VALUE           - Comment'+CRLF
                  +' preset         xxx             - Preset predefined parameters named `xxx`, see below:'+CRLF
                  +'                xxx             - stdOk,stdNo,stdHelp,stdStop,stdDeny,stdAbort,stdError,stdFails,stdSiren,'+CRLF
                  +'                                - stdAlarm,stdAlert,stdBreak,stdCancel,stdNotify,stdTooltip,stdSuccess,'+CRLF
                  +'                                - stdWarning,stdQuestion,stdException,stdAttention,stdInformation,'+CRLF
                  +'                                - stdExclamation'+CRLF
                  +'                                - NB: preset xxx should be first in the list of parameters'+CRLF
                  +' verbose        1               - Verbose mode  (default = 0 is silent execution)'+CRLF
                  +' noDouble       1               - noDouble mode (default = 0 is enable double text)'+CRLF
                  +' text           "Hello world"   - Text to display'+CRLF
                  +' delay          15000           - Close after specified time ms (default 86400000 ms = day)'+CRLF
                  +' audio          notify.wav      - Play sound (*.wav file)'+CRLF
                  +' wav            notify.wav      - Synonym of audio'+CRLF
                  +' ico            notify.ico      - Show icon file (*.ico,*.exe,*.dll)'+CRLF
                  +' avi            alert.avi       - Show avi 32x32 icon file (*.avi)'+CRLF
                  +' bkColor        red             - Background color (default violet) '+CRLF
                  +' textColor      0xFF0000        - Text color (default black)'+CRLF
                  +'                                - Colors: black,white,red,green,blue,purple,orange,violet'+CRLF
                  +'                                -  or Hex RGB as  0xRRGGBB, for example violet=0xBC8BDA'+CRLF
                  +' trans          255             - Transparency 0..255 (default 255)'+CRLF
                  +' font           "PT Mono"       - Font family name (default Tahoma)'+CRLF
                  +' fontSize       16              - Font size, pt (default 16)'+CRLF
                  +' onClick        "cmd arg"       - On click run command "cmd arg"'+CRLF
                  +' cmd0           "cmd arg"       - Symonym of onClick'+CRLF
                  +' untilClickAny  1               - Close on any click (default 1)'+CRLF
                  +' btn1..btn9     "Button label"  - Button 1..9 label text'+CRLF
                  +' cmd1..cmd9     "cmd arg"       - Button 1..9 command'+CRLF
                  +' guid           "{..}"          - Assign target window GUID which uses'+CRLF
                  +'                                - to refresh updateable windows content'+CRLF
                  +' sure           0/1             - Synonym of createIfNotVisible flag'+CRLF
                  +'                                - Uses to be sure that GUID window appears'+CRLF
                  +' createIfNotVisible 0/1         - 0/1=not/create window if one not visible'+CRLF
                  +'                                - Uses only with guid option; default=1'+CRLF
                  +' delete         "{..guid..}"    - delete message window with given GUID'+CRLF
                  +' progress       p               - Show progress bar, p=0..100 percent'+CRLF
                  +'                                - Uses with GUID to update progress'+CRLF
                  +' run            "cmd arg"       - Run command on message received'+CRLF
                  +'                                - Command runs only if window visible'+CRLF
                  +' xml            "<x>..</x>"     - Append xml expression to message'+CRLF
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
                  +' 2) Args: '+ProgramId+' -d "<text>Hello world.</text>"'+CRLF
                  +' 3) Pipe: cmd /c echo xml "<text>Hello world.</text>" | '+ProgramId+CRLF
                  +' 4) Logs: '+ProgramId+' -v -l %temp%\'+ProgramId+'.log xml "<text>Hello world.</text>"'+CRLF
                  +' 5) Data: '+ProgramId+' text "Hello world." preset stdTooltip delay 15000'+CRLF
                  +'';
  Print(sAbout);
  errno:=code;
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

 // Run FP-QUI.exe and wait initialization
function TFpQuiManager.RunFpQuiCoreExe(aTimeOut:DWORD):DWORD;
var si:STARTUPINFO; pi:PROCESS_INFORMATION; tick:DWORD;
begin 
 Result:=0;
 if Assigned(Self) then
 try
  if (Length(ActualWorkDir)=0) or not DirectoryExists(ActualWorkDir)
  then myActualWorkDir:=GetSharedWorkDir;
  if (Length(ActualExePath)=0) or not FileExists(ActualExePath)
  then myActualExePath:=TrimSpacesQuotes(FindFpQuiCoreExe);
  if (Length(ActualExePath)>0) and FileExists(ActualExePath) then begin
   ZeroMemory(@si,sizeof(si)); si.cb:=sizeof(si);
   si.dwFlags:=STARTF_USESHOWWINDOW; si.wShowWindow:=SW_SHOW;
   if CreateProcess(PChar(ActualExePath),nil,nil,nil,FALSE,0,nil,PChar(ActualWorkDir),si,pi) then begin
    Result:=pi.dwProcessId; WaitForInputIdle(pi.hProcess,aTimeOut);
    tick:=GetTickCount;
    while (GetTickCount-tick<aTimeOut)
    and (WaitForSingleObject(pi.hProcess,0)=WAIT_TIMEOUT)
    and not IsWindow(FindFpQuiWindow(TargetClass,TargetTitle,TargetExeId))
    do Sleep(10);
    CloseHandle(pi.hProcess); CloseHandle(pi.hThread);
   end;
   if verbose then if Result<>0
   then Print('Launch "'+ActualExePath+'" PID '+IntToStr(Result))
   else Print('Failed "'+ActualExePath+'"');
  end;
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;


procedure TFpQuiManager.ClearAll;
begin
 if Assigned(Self) then
 try
  myTargetClass:='';
  myTargetTitle:='';
  myTargetExeId:='';
  myTargetMagic:=0;
  myActualWin:=0;
  myActualPid:=0;
  myActualExe:='';
  myActualExePath:='';
  myActualWorkDir:='';
  myLog:='';
  myErrno:=0;
  myTimeOut:=0;
  myDemoDelay:=0;
  myVerbose:=false;
  myProgramId:='';
  par.xml:='';
  par.avi:='';
  par.text:='';
  par.verbose:='';
  par.trans:='';
  par.font:='';
  par.fontSize:='';
  par.bkColor:='';
  par.delay:='';
  par.untilClickAny:='';
  par.ico:='';
  par.audio:='';
  par.textColor:='';
  par.noDouble:='';
  par.onClick:='';
  par.progress:='';
  par.guid:='';
  par.delete:='';
  par.sure:=''; // synonym createIfNotVisible
  par.run:='';
  par.button:='';
  par.btn1:='';
  par.cmd1:='';
  par.btn2:='';
  par.cmd2:='';
  par.btn3:='';
  par.cmd3:='';
  par.btn4:='';
  par.cmd4:='';
  par.btn5:='';
  par.cmd5:='';
  par.btn6:='';
  par.cmd6:='';
  par.btn7:='';
  par.cmd7:='';
  par.btn8:='';
  par.cmd8:='';
  par.btn9:='';
  par.cmd9:='';
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

procedure TFpQuiManager.SetDefaults;
begin
 if Assigned(Self) then
 try
  myTargetClass:=fpQuiClass;
  myTargetTitle:=fpQuiTitle;
  myTargetExeId:=fpQuiExeId;
  myTargetMagic:=fpQuiMagic;
  myLog:='';
  myErrno:=0;
  myVerbose:=false;
  par.xml:='';
  par.avi:='';
  par.text:='?';
  par.verbose:='0';
  par.trans:='255';
  par.font:='Tahoma';
  par.fontSize:='16';
  par.bkColor:='0xBC8BDA';
  par.delay:='86400000';
  par.untilClickAny:='1';
  par.ico:='default.ico';
  par.audio:='default.wav';
  par.textColor:='0x000000';
  par.noDouble:='0';
  par.onClick:='?';
  par.progress:='';
  par.guid:='';
  par.delete:='';
  par.sure:='1'; // synonym createIfNotVisible
  par.run:='';
  par.button:='';
  par.btn1:='';
  par.cmd1:='';
  par.btn2:='';
  par.cmd2:='';
  par.btn3:='';
  par.cmd3:='';
  par.btn4:='';
  par.cmd4:='';
  par.btn5:='';
  par.cmd5:='';
  par.btn6:='';
  par.cmd6:='';
  par.btn7:='';
  par.cmd7:='';
  par.btn8:='';
  par.cmd8:='';
  par.btn9:='';
  par.cmd9:='';
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

procedure TFpQuiManager.Cleanup;
begin
 if Assigned(Self) then SetDefaults;
end;

procedure TFpQuiManager.PresetStd(const s1,s2,s3,s4,s5,s6,s7:AnsiString);
begin
 if Assigned(Self) then
 try
  par.font:=TrimSpacesQuotes(s1);
  par.fontSize:=TrimSpacesQuotes(s2);
  par.bkColor:=TrimSpacesQuotes(s3);
  par.ico:=TrimSpacesQuotes(s4);
  par.audio:=TrimSpacesQuotes(s5);
  par.avi:=TrimSpacesQuotes(s6);
  par.noDouble:=TrimSpacesQuotes(s7);
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

procedure TFpQuiManager.PresetParams(const s1:AnsiString);
begin
 if Assigned(Self) then
 try
  // Preset predefined standard parameters         font            fontSize bkColor   ico                audio              avi                noDouble
  if SameText(s1,'stdOk') then          PresetStd( 'PT Mono Bold', '16',    'green',  'ok.ico',          'ok.wav',          'ok.avi',          '1' ) else
  if SameText(s1,'stdNo') then          PresetStd( 'PT Mono Bold', '16',    'red',    'no.ico',          'no.wav',          'no.avi',          '1' ) else
  if SameText(s1,'stdHelp') then        PresetStd( 'PT Mono Bold', '16',    'blue',   'help.ico',        'help.wav',        'help.avi',        '1' ) else
  if SameText(s1,'stdStop') then        PresetStd( 'PT Mono Bold', '16',    'red',    'stop.ico',        'stop.wav',        'stop.avi',        '1' ) else
  if SameText(s1,'stdDeny') then        PresetStd( 'PT Mono Bold', '16',    'red',    'deny.ico',        'deny.wav',        'deny.avi',        '1' ) else
  if SameText(s1,'stdAbort') then       PresetStd( 'PT Mono Bold', '16',    'red',    'abort.ico',       'abort.wav',       'abort.avi',       '1' ) else
  if SameText(s1,'stdError') then       PresetStd( 'PT Mono Bold', '16',    'red',    'error.ico',       'error.wav',       'error.avi',       '1' ) else
  if SameText(s1,'stdFails') then       PresetStd( 'PT Mono Bold', '16',    'red',    'fails.ico',       'fails.wav',       'fails.avi',       '1' ) else
  if SameText(s1,'stdSiren') then       PresetStd( 'PT Mono Bold', '16',    'red',    'siren.ico',       'siren.wav',       'siren.avi',       '1' ) else
  if SameText(s1,'stdAlarm') then       PresetStd( 'PT Mono Bold', '16',    'red',    'alarm.ico',       'alarm.wav',       'alarm.avi',       '1' ) else
  if SameText(s1,'stdAlert') then       PresetStd( 'PT Mono Bold', '16',    'red',    'alert.ico',       'alert.wav',       'alert.avi',       '1' ) else
  if SameText(s1,'stdBreak') then       PresetStd( 'PT Mono Bold', '16',    'red',    'break.ico',       'break.wav',       'break.avi',       '1' ) else
  if SameText(s1,'stdCancel') then      PresetStd( 'PT Mono Bold', '16',    'red',    'cancel.ico',      'cancel.wav',      'cancel.avi',      '1' ) else
  if SameText(s1,'stdNotify') then      PresetStd( 'PT Mono Bold', '16',    'green',  'notify.ico',      'notify.wav',      'notify.avi',      '1' ) else
  if SameText(s1,'stdTooltip') then     PresetStd( 'PT Mono Bold', '16',    'violet', 'tooltip.ico',     'tooltip.wav',     'tooltip.avi',     '1' ) else
  if SameText(s1,'stdSuccess') then     PresetStd( 'PT Mono Bold', '16',    'green',  'success.ico',     'success.wav',     'success.avi',     '1' ) else
  if SameText(s1,'stdWarning') then     PresetStd( 'PT Mono Bold', '16',    'yellow', 'warning.ico',     'warning.wav',     'warning.avi',     '1' ) else
  if SameText(s1,'stdQuestion') then    PresetStd( 'PT Mono Bold', '16',    'blue',   'question.ico',    'question.wav',    'question.avi',    '1' ) else
  if SameText(s1,'stdException') then   PresetStd( 'PT Mono Bold', '16',    'red',    'exception.ico',   'exception.wav',   'exception.avi',   '1' ) else
  if SameText(s1,'stdAttention') then   PresetStd( 'PT Mono Bold', '16',    'yellow', 'attention.ico',   'attention.wav',   'attention.avi',   '1' ) else
  if SameText(s1,'stdInformation') then PresetStd( 'PT Mono Bold', '16',    'blue',   'information.ico', 'information.wav', 'information.avi', '1' ) else
  if SameText(s1,'stdExclamation') then PresetStd( 'PT Mono Bold', '16',    'yellow', 'exclamation.ico', 'exclamation.wav', 'exclamation.avi', '1' );
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

procedure TFpQuiManager.ParseArgumentPair(const s1,s2:AnsiString);
begin
 if Assigned(Self) then
 try
  if Length(s1)=0 then exit;
  if Length(s2)=0 then exit;
  if SameText(s1,'preset') then                                  PresetParams(s2)         else
  if SameText(s1,'verbose') then     begin   par.verbose         :=  TrimSpacesQuotes(s2); verbose:=SameText(par.verbose,'1') end else
  if SameText(s1,'xml') then                 par.xml := par.xml  +   TrimSpacesQuotes(s2) else
  if SameText(s1,'ico') then                 par.ico             :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'text') then                par.text            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'font') then                par.font            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'delay') then               par.delay           :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'audio') then               par.audio           :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'wav') then                 par.audio           :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'avi') then                 par.avi             :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'trans') then               par.trans           :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'bkColor') then             par.bkColor         :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'fontSize') then            par.fontSize        :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'textColor') then           par.textColor       :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'untilClickAny') then       par.untilClickAny   :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'noDouble') then            par.noDouble        :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'onClick') then             par.onClick         :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'progress') then            par.progress        :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'guid') then                par.guid            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'delete') then              par.delete          :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'createIfNotVisible') then  par.sure            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'sure') then                par.sure            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'run') then                 par.run             :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'btn0') then                par.text            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'cmd0') then                par.onClick         :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'btn1') then                par.btn1            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'cmd1') then                par.cmd1            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'btn2') then                par.btn2            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'cmd2') then                par.cmd2            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'btn3') then                par.btn3            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'cmd3') then                par.cmd3            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'btn4') then                par.btn4            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'cmd4') then                par.cmd4            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'btn5') then                par.btn5            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'cmd5') then                par.cmd5            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'btn6') then                par.btn6            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'cmd6') then                par.cmd6            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'btn7') then                par.btn7            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'cmd7') then                par.cmd7            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'btn8') then                par.btn8            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'cmd8') then                par.cmd8            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'btn9') then                par.btn9            :=  TrimSpacesQuotes(s2) else
  if SameText(s1,'cmd9') then                par.cmd9            :=  TrimSpacesQuotes(s2);
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

procedure TFpQuiManager.ColorCheck;
begin
 if Assigned(Self) then
 try
  if SameText(par.bkColor,'default')   then par.bkColor:='violet';
  if SameText(par.textColor,'default') then par.textColor:='black';
  if SameText(par.bkColor,'violet')    then par.bkColor:='0xBC8BDA';
  if SameText(par.textColor,'violet')  then par.textColor:='0xBC8BDA';
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

function XmlTag(tag,value:AnsiString):AnsiString;
begin
 tag:=TrimSpacesQuotes(tag);
 value:=TrimSpacesQuotes(value);
 if (Length(tag)>0) and (Length(value)>0)
 then Result:='<'+tag+'>'+value+'</'+tag+'>'
 else Result:='';
end;

procedure TFpQuiManager.ParseButtons;
begin
 if Assigned(Self) then with par do
 try
  if Length(btn1)>0 then if Length(cmd1)>0 then button:=button+XmlTag('ID1',XmlTag('label',btn1)+XmlTag('cmd',cmd1)+XmlTag('font',font)+XmlTag('fontSize',fontSize));
  if Length(btn2)>0 then if Length(cmd2)>0 then button:=button+XmlTag('ID2',XmlTag('label',btn2)+XmlTag('cmd',cmd2)+XmlTag('font',font)+XmlTag('fontSize',fontSize));
  if Length(btn3)>0 then if Length(cmd3)>0 then button:=button+XmlTag('ID3',XmlTag('label',btn3)+XmlTag('cmd',cmd3)+XmlTag('font',font)+XmlTag('fontSize',fontSize));
  if Length(btn4)>0 then if Length(cmd4)>0 then button:=button+XmlTag('ID4',XmlTag('label',btn4)+XmlTag('cmd',cmd4)+XmlTag('font',font)+XmlTag('fontSize',fontSize));
  if Length(btn5)>0 then if Length(cmd5)>0 then button:=button+XmlTag('ID5',XmlTag('label',btn5)+XmlTag('cmd',cmd5)+XmlTag('font',font)+XmlTag('fontSize',fontSize));
  if Length(btn6)>0 then if Length(cmd6)>0 then button:=button+XmlTag('ID6',XmlTag('label',btn6)+XmlTag('cmd',cmd6)+XmlTag('font',font)+XmlTag('fontSize',fontSize));
  if Length(btn7)>0 then if Length(cmd7)>0 then button:=button+XmlTag('ID7',XmlTag('label',btn7)+XmlTag('cmd',cmd7)+XmlTag('font',font)+XmlTag('fontSize',fontSize));
  if Length(btn8)>0 then if Length(cmd8)>0 then button:=button+XmlTag('ID8',XmlTag('label',btn8)+XmlTag('cmd',cmd8)+XmlTag('font',font)+XmlTag('fontSize',fontSize));
  if Length(btn9)>0 then if Length(cmd9)>0 then button:=button+XmlTag('ID9',XmlTag('label',btn9)+XmlTag('cmd',cmd9)+XmlTag('font',font)+XmlTag('fontSize',fontSize));
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

function TFpQuiManager.ComposeMessage:AnsiString;
begin
 Result:='';
 if Assigned(Self) then
 try
  if SameText(par.text,'?') then par.text:='';
  if SameText(par.sure,'0') then par.sure:='';
  if SameText(par.onClick,'?') then par.onClick:='';
  if SameText(par.noDouble,'0') then par.noDouble:='';
  if SameText(par.untilClickany,'0') then par.untilClickany:='';
  if Length(par.guid)>0 then
  Result:=Result+XmlTag('guid',                 par.guid)
                +XmlTag('createIfNotVisible',   par.sure);
  Result:=Result+XmlTag('delete',               par.delete)
                +XmlTag('progress',             par.progress)
                +XmlTag('ico',                  par.ico)
                +XmlTag('bkColor',              par.bkColor)
                +XmlTag('textColor',            par.textColor)
                +XmlTag('trans',                par.trans)
                +XmlTag('font',                 par.font)
                +XmlTag('fontSize',             par.fontSize)
                +XmlTag('untilClick',           XmlTag('any',   par.untilClickany))
                +XmlTag('onClick',              XmlTag('any',   par.onClick))
                +XmlTag('audio',                XmlTag('path',  par.audio))
                +XmlTag('run',                  XmlTag('cmd',   par.run))
                +XmlTag('delay',                par.delay)
                +XmlTag('noDouble',             par.noDouble)
                +XmlTag('text',                 par.text)
                +XmlTag('button',               par.button)
                +XmlTag('avi',                  par.avi);
  if Length(par.xml)>0 then Result:=Result+par.xml;
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

 // Parse command line parameters
function TFpQuiManager.ParseCommandLine(const CmdLine:AnsiString; Skip:Integer=0):AnsiString;
var Index:Integer; Ident,Param:AnsiString; P:PChar;
 procedure NextParam(var P:PChar; var Param:AnsiString; var Index:Integer);
 begin
  P:=GetNextParamStr(P,Param); Inc(Index);
 end;
begin
 Result:='';
 P:=PChar(CmdLine);
 if Assigned(P) then
 if Assigned(Self) then
 try
  Index:=0;
  SetDefaults;
  while true do begin
   NextParam(P,Param,Index);
   if Index<=Skip then continue;
   if Length(Param)=0 then Break;
   // Option -v, --verbose : Set verbose mode
   if SameText(Param,'-v') or SameText(Param,'--verbose') then begin
    par.verbose:='1';
    myVerbose:=true;
    continue;
   end;
   // Option -l, --log : Set log filename
   if SameText(Param,'-l') or SameText(Param,'--log') then begin
    NextParam(P,Param,Index);
    theLog:=Param;
    continue;
   end;
   // Option -d, --data : Assign data to send
   if SameText(Param,'-d') or SameText(Param,'--data') then begin
    NextParam(P,Param,Index);
    ParseArgumentPair('xml',Param);
    continue;
   end;
   // Option -c, --class : Assign window class
   if SameText(Param,'-c') or SameText(Param,'--class') then begin   
    NextParam(P,Param,Index);
    TargetClass:=Param;
    continue;
   end;
   // Option -t, --title : Assign window title
   if SameText(Param,'-t') or SameText(Param,'--title') then begin
    NextParam(P,Param,Index);
    TargetTitle:=Param;
    continue;
   end;
   // Option -e, --exe : Assign exe filename
   if SameText(Param,'-e') or SameText(Param,'--exe') then begin
    NextParam(P,Param,Index);
    TargetExeId:=Param;
    continue;
   end;
   // Option -m, --magic : Assign magic number
   if SameText(Param,'-m') or SameText(Param,'--magic') then begin
    NextParam(P,Param,Index);
    TargetMagic:=iValDef(Param,-1);
    continue;
   end;
   Ident:=Param; NextParam(P,Param,Index);
   if Length(Ident)>0 then if Length(Param)>0 then ParseArgumentPair(Ident,Param);
  end;
  if Length(theLog)>0 then theLog:=ExpandFileName(ExpEnv(theLog));
  if Length(par.audio)>0 then par.audio:=FindFile(par.audio);
  if Length(par.ico)>0 then par.ico:=FindFile(par.ico);
  if Length(par.avi)>0 then par.avi:=FindFile(par.avi);
  ParseButtons;
  ColorCheck;
  Result:=ComposeMessage;
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

 // Check parameters is valid
function TFpQuiManager.CheckParameters:Integer;
begin
 Result:=EcfpQuiGenFail;
 if Assigned(Self) then
 try
  if verbose then begin
   Print('--class='+TargetClass);
   Print('--title='+TargetTitle);
   Print('--exe='+TargetExeId);
   Print('--magic='+IntToStr(TargetMagic));
  end;
  // Check window class
  if Length(TargetClass)=0 then begin
   Result:=Failure(EcFpQuiBadArgs,'Invalid window class. Help: '+ProgramId+' --help.');
   exit;
  end;
  // Check window title
  if Length(TargetTitle)=0 then begin
   Result:=Failure(EcFpQuiBadArgs,'Invalid window title. Help: '+ProgramId+' --help.');
   exit;
  end;
  // Check exe filename
  if Length(TargetExeId)=0 then begin
   Result:=Failure(EcFpQuiBadArgs,'Invalid exe filename. Help: '+ProgramId+' --help.');
   exit;
  end;
  // Check magic number
  if TargetMagic<0 then begin
   Result:=Failure(EcFpQuiBadArgs,'Invalid magic number. Help: '+ProgramId+' --help.');
   exit;
  end;
  // Check message data
  if Length(par.text)+Length(par.xml)+Length(par.delete)=0 then begin
   Result:=Failure(EcFpQuiBadArgs,'Invalid call syntax. Help: '+ProgramId+' --help.');
   exit;
  end;
  Result:=EcFpQuiSuccess;
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

 // Read FP-QUI parameter from registry string HKEY_LOCAL_MACHINE\SOFTWARE\FP-QUI\Name
function TFpQuiManager.ReadFpQuiReg(const Name:AnsiString):AnsiString;
begin
 Result:='';
 if Length(Name)>0 then
 if Assigned(Self) then
 try
  Result:=ReadReqistryString(HKEY_LOCAL_MACHINE,'SOFTWARE\FP-QUI',Name);
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

function TFpQuiManager.FindFile(const aFileName:AnsiString):AnsiString;
var path:AnsiString;
begin
 Result:='';
 if Assigned(Self) then
 try
  Result:=Trim(aFileName);
  if Length(Result)>0 then
  if not FileExists(Result) then
  if IsRelativePath(Result) then begin
   path:='';
   AppendDirToSearchPath(path,ReadFpQuiReg('dir'),'.;gui');
   AppendDirToSearchPath(path,GetEnv('ProgramFiles'),'FP-QUI;FP-QUI\gui');
   AppendDirToSearchPath(path,GetEnv('ProgramFiles(x86)'),'FP-QUI;FP-QUI\gui');
   AppendDirToSearchPath(path,GetEnv('CommonProgramFiles'),'FP-QUI;FP-QUI\gui');
   AppendDirToSearchPath(path,GetEnv('CommonProgramFiles(x86)'),'FP-QUI;FP-QUI\gui');
   AppendDirToSearchPath(path,GetEnv('UnixRoot'),'add\bin;add\fp-qui;fp-qui\gui');
   AppendDirToSearchPath(path,'.','.;FP-QUI;FP-QUI\gui');
   AppendDirToSearchPath(path,'..','.;FP-QUI;FP-QUI\gui');
   path:=AttachTailChar(AttachTailChar(path,';')+GetEnv('PATH'),';');
   Result:=FileSearch(Result,path);
  end;
  Result:=Trim(Result);
  if (Length(Result)>0) and FileExists(Result) then Result:=ExpandFileName(Result) else Result:='';
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

 // Get FP-QUI.exe file name. Find in registry or in usual locations.
function TFpQuiManager.FindFpQuiExe:AnsiString;
begin
 Result:='';
 if Assigned(Self) then
 try
  Result:=FindFile(ReadFpQuiReg('exe'));
  if (Length(Result)=0) or not FileExists(Result) then Result:=FindFile('FP-QUI.exe');
  if (Length(Result)>0) and FileExists(Result) then Result:=ExpandFileName(Result) else Result:='';
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

 // Get FP-QUICore.exe file name. Find in registry or in usual locations.
function TFpQuiManager.FindFpQuiCoreExe:AnsiString;
begin
 Result:='';
 if Assigned(Self) then
 try
  Result:=FindFile(ReadFpQuiReg('coreExe'));
  if (Length(Result)=0) or not FileExists(Result) then Result:=FindFile(fpQuiExeId);
  if (Length(Result)>0) and FileExists(Result) then Result:=ExpandFileName(Result) else Result:='';
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

type
 PSearchWindowRec = ^TSearchWindowRec;
 TSearchWindowRec = record wClass,wTitle,wExeId:PChar; hWin:HWND; end;

function SearchFpQuiWindow(Handle:HWND; Info:Pointer):BOOL; stdcall;
begin
 Result:=True;
 try
  if Handle<>0 then
  if Assigned(Info) then
  with PSearchWindowRec(Info)^ do
  if GetWindowClass(Handle)=wClass then
  if GetWindowTitle(Handle)=wTitle then
  if SameText(wExeId,GetExeNameByPid(GetWindowProcessId(Handle))) then begin
   Result:=false; hWin:=Handle;
  end;
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

function FindWindowByClassTitleExe(aClass,aTitle,aExeId:AnsiString):HWND;
var R:TSearchWindowRec; Iter:Integer; const MaxIter=32;
begin
 Result:=0;
 try
  aClass:=Trim(aClass); if Length(aClass)=0 then exit;
  aTitle:=Trim(aTitle); if Length(aTitle)=0 then exit;
  aExeId:=Trim(aExeId); if Length(aExeId)=0 then exit;
  // Search via FindWindowEx
  if Result=0 then begin
   for Iter:=1 to MaxIter do begin
    Result:=FindWindowEx(0,Result,PChar(aClass),PChar(aTitle)); if Result=0 then break;
    if SameText(aExeId,GetExeNameByPid(GetWindowProcessId(Result))) then break;
   end;
  end;
  // Search via EnumWindows
  if Result=0 then begin
   R.wClass:=PChar(aClass);
   R.wTitle:=PChar(aTitle);
   R.wExeId:=PChar(aExeId);
   R.hWin:=0;
   EnumWindows(@SearchFpQuiWindow,LPARAM(@R));
   Result:=R.hWin;
  end;
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

 // Find FP-QUI window by Class,Title,Exe file name
function TFpQuiManager.FindFpQuiWindow(const aClass,aTitle,aExeId:AnsiString):HWND;
begin
 Result:=0;
 if Assigned(Self) then
 try
  Result:=FindWindowByClassTitleExe(aClass,aTitle,aExeId);
  if Result=0 then Result:=FindWindowEx(0,0,PChar(aClass),PChar(aTitle)); // Fallback
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

 // Find actual FP-QUI target window, process etc
function TFpQuiManager.FindActualTarget(AllowRun:Boolean):Boolean;
begin
 Result:=false;
 if Assigned(Self) then
 try
  if (Length(ActualWorkDir)=0) or not DirectoryExists(ActualWorkDir)
  then myActualWorkDir:=GetSharedWorkDir;
  if (Length(myActualExePath)=0) or not FileExists(myActualExePath)
  then myActualExePath:=TrimSpacesQuotes(FindFpQuiCoreExe);
  if (myActualWin<>0) and IsWindow(myActualWin) then begin
   if GetWindowTitle(myActualWin)<>TargetTitle then myActualWin:=0 else
   if GetWindowClass(myActualWin)<>TargetClass then myActualWin:=0;
  end;
  if (myActualWin=0) or not IsWindow(myActualWin)
  then myActualWin:=FindFpQuiWindow(TargetClass,TargetTitle,TargetExeId);
  if AllowRun then
  if (myActualWin=0) or not IsWindow(myActualWin) then begin
   if FindProcessPid(fpQuiExeId)=0 then RunFpQuiCoreExe(TimeOut);
   myActualWin:=FindFpQuiWindow(TargetClass,TargetTitle,TargetExeId);
  end;
  if (myActualWin<>0) and IsWindow(myActualWin) then begin
   myActualPid:=GetWindowProcessId(myActualWin);
   myActualExe:=GetExeNameByPid(myActualPid);
   Result:=true;
  end else begin
   myActualPid:=0;
   myActualExe:='';
  end;
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

 // Send WM_COPYDATA message to FP-QUI; return status
function TFpQuiManager.SendMessage(const data:AnsiString; AllowRun:Boolean=true):Integer;
begin
 Result:=EcfpQuiGenFail;
 if Assigned(Self) then
 try
  if FindActualTarget(AllowRun) then begin
   if not SameText(ActualExe,TargetExeId) then begin
    Result:=Failure(EcFpQuiFailExe,'Unexpected EXE name.');
    exit;
   end;
   if Length(data)=0 then begin
    Result:=Failure(EcFpQuiBadData,'Nothing to send.');
    exit;
   end;
   if wmCopyDataSend(myActualWin,PChar(data),Length(data)+1,TargetMagic)>0 then begin
    Result:=Success(EcFpQuiSuccess,'Sent char['+IntToStr(Length(data)+1)+'] message to '+myActualExe+' PID '+IntToStr(myActualPid));
   end else begin
    Result:=Failure(EcFpQuiNotSent,'Lost char['+IntToStr(Length(data)+1)+'] message to '+myActualExe+' PID '+IntToStr(myActualPid));
   end;
  end else begin
   Result:=Failure(EcFpQuiNoFound,'FP-QUI window not found.');
   exit;
  end;
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

 // Get arguments of Command Line
function TFpQuiManager.GetCmdLineArguments:AnsiString;
var s:AnsiString;
begin
 Result:='';
 if Assigned(Self) then
 try
  Result:=Trim(GetNextParamStr(GetCommandLine,s));
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

 // Try to read StdIn
function TFpQuiManager.ReadFromStdIn(aMaxLeng:Cardinal=1024*64):AnsiString;
var stdin:THandle; buff:array[0..255] of char; dwLen,Count:DWORD; s:AnsiString;
begin
 Result:='';
 if Assigned(Self) then
 try
  if IsConsole then begin
   stdin:=GetStdHandle(STD_INPUT_HANDLE); Count:=0; s:='';
   while ReadFile(stdin,buff,sizeof(buff),dwLen,nil) and (Count<aMaxLeng) do begin
    if dwLen>0 then SetString(s,buff,dwLen) else break;
    inc(Count,dwLen); Result:=Result+s;
   end;
   Result:=Trim(Result);
  end;
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

 // Get data from Command Line argiments or from StdIn
function TFpQuiManager.ReadCmdLineOrStdIn(aMaxLeng:Cardinal=1024*64):AnsiString;
begin
 Result:='';
 if Assigned(Self) then
 try
  Result:=GetCmdLineArguments;
  if (Length(Result)=0) and IsConsole then
  Result:=ReadFromStdIn(aMaxLeng);
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

function TFpQuiManager.RunFpQuiTipExe(arg:AnsiString=''):Integer;
var data:AnsiString;
begin
 Result:=EcfpQuiGenFail;
 if Assigned(Self) then
 try
  arg:=Trim(arg);
  if Length(arg)=0 then
  arg:=ReadCmdLineOrStdIn;
  // Option --demo : Run demo
  if SameText(arg,'--demo') then begin
   Result:=RunDemo(DemoDelay);
   exit;
  end;
  // Option -h, --help : Show help
  if SameText(arg,'-h') or SameText(arg,'--help')
  or SameText(arg,'/?') or SameText(arg,'-?') then begin
   Result:=Usage(0);
   exit;
  end;
  data:=ParseCommandLine(arg);
  if verbose then Print('--data='+data);
  if CheckParameters=EcFpQuiSuccess then SendMessage(data);
  Result:=errno;
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

function TFpQuiManager.RunDemo(aDelay:Cardinal=1000):Integer;
var dpi,dpn,dpp:Integer; presets,s:AnsiString; P:PChar;
const dpiguid='{909BDAF7-B24E-438F-9542-6C4FFC19AA31}';
begin
 Result:=0;
 if Assigned(Self) then
 try
  dpi:=0; dpn:=0;
  presets:='stdOk stdNo stdHelp stdStop stdDeny stdAbort stdError stdFails stdSiren '
          +'stdAlarm stdAlert stdBreak stdCancel stdNotify stdTooltip stdSuccess '
          +'stdWarning stdQuestion stdException stdAttention stdInformation stdExclamation';
  RunFpQuiTipExe(Format('verbose 1 guid %s text "FP-QUI - Demo progress %d%s" preset stdTooltip progress %d',[dpiguid,0,'%',0]));
  RunFpQuiTipExe(Format('verbose 1 text "Defaults" delay 15000',[]));
  Print('');
  P:=PChar(presets);
  while true do begin
   P:=GetNextParamStr(P,s);
   if Length(s)=0 then break;
   Inc(dpn);
  end;;
  P:=PChar(presets);
  while true do begin
   P:=GetNextParamStr(P,s);
   if length(s)=0 then break;
   Inc(dpi); dpp:=100*dpi div dpn;
   RunFpQuiTipExe(Format('verbose 1 guid %s sure 0 text "FP-QUI - Demo progress %d%s" preset stdTooltip progress %d',[dpiguid,dpp,'%',dpp]));
   RunFpQuiTipExe(Format('verbose 1 text "FP-QUI - Demo preset %s" preset %s delay 15000 btn1 "cmd" cmd1 "cmd /c start cmd"',[s,s]));
   if aDelay>0 then Sleep(aDelay);
   Print('');
  end;
  RunFpQuiTipExe(Format('verbose 1 guid %s text "FP-QUI - Demo progress %d%s" preset stdTooltip progress %d delay 15000',[dpiguid,100,'%',100]));
  Result:=errno;
 except
  on E:Exception do FpQuiExceptionHandler(E);
 end;
end;

initialization

finalization

 Kill(myFpQuiManager);

end.
