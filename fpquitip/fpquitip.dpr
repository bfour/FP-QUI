 {
 Copyright(c) Alexey Kuryakin 2017, <kouriakine@mail.ru>, RU, LGPL.
 fpquitip - program to show tooltip windows via FP-QUI package.
 FP-QUI is nice tooltip notification system made by Florian Pollak.
 FP-QUI Copyright 2010-2017 Florian Pollak (bfourdev@gmail.com).
 Notes:
 1) fpquitip send message WM_COPYDATA to FP-QUI process for fast IPC.
    WM_COPYDATA is very fast way of IPC (interprocess communications).
 2) WM_COPYDATA access have no restriction for number of clients. The
    messages may comes from any process (on the localhost of course).
 3) fpquitip is very small and lightweight program so fpquitip call
    much faster compare to FP-QUI.exe. In case of FP-QUICore.exe not
    running, start FP-QUI.exe first.
 4) fpquitip may send data coming from Command Line argument list.
 5) Also fpquitip may send data coming from StdIn, i.e. console or
    file or pipe - if command line arguments is empty.
 6) fpquitip have simplified command interface compare to XML.
    But XML also supports.
    Example flat/XML, args/pipe:
     fpquitip text "Hello world" delay 10000
     fpquitip xml "<text>Hello world</text><delay>10000</delay>"
     cmd /c echo text "Hello world" delay 10000 | fpquitip
     cmd /c echo xml "<text>Hello world</text><delay>10000</delay>" | fpquitip
 7) So why not to use fpquitip?
 8) Compiled with Delphi 5.0.
 }
program fpquitip;

{$APPTYPE CONSOLE}

{$I-} {$B-} {$R-} // {$O-} {$W+}

uses Windows,Messages,SysUtils,_fpqui;

{$R *.RES}

procedure FpQuiTipExceptionHandler(E:Exception);
begin
 if IsConsole and Assigned(E) then writeln('Exception: '+E.ClassName+' '+E.Message);
end;
 
procedure FpQuiTipEcho(const Msg:AnsiString);
begin
 if IsConsole then write(Msg);
end;

begin
 TheFpQuiEchoProcedure:=FpQuiTipEcho;
 TheFpQuiExceptionHandlerProcedure:=FpQuiTipExceptionHandler;
 FpQuiManager.DemoDelay:=3000;
 ExitCode:=FpQuiManager.RunFpQuiTipExe;
end.
