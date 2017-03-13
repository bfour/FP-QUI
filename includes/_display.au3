#cs

   author: "SkinnyWhiteGuy" on http://www.autoitscript.com/forum/index.php?showtopic=105921
   modified by Florian Pollak (bfourdev@gmail.com)

#ce

#include-once

#include <WinAPIMisc.au3>
#include <WinAPIGdi.au3>

Global Const $_DISPLAY_DEFAULTTONULL     = 0x00000000
Global Const $_DISPLAY_DEFAULTTOPRIMARY  = 0x00000001
Global Const $_DISPLAY_DEFAULTTONEAREST  = 0x00000002

Global Const $_DISPLAY_CCHDEVICENAME     = 32
Global Const $_DISPLAY_INFO_OF_PRIMARY   = 0x00000001

;~ #include <Array.au3>
;~ $ar = _displayGetEnum()
;~ Local $ar[4]
;~ _displayGetMonitorInfos(_displayGetFromPoint(1921,0), $ar)
;~ _ArrayDisplay($ar)
;~ _ArrayDisplay($ar)
;~ MsgBox(1,"",_displayGetPosHash())
;~ MsgBox(1,"",_displayGetPrimary())

;out: [n][0:x 1:y 2:width 3:height 4:is primary]
Func _displayGetPos()

   Local $returnArray[1][6]

   Local $tag_DISPLAY_DEVICE = "dword cb;char DeviceName[32];char DeviceString[128];dword StateFlags;char DeviceID[128];char DeviceKey[128]"
   Local $DISPLAY_DEVICE_MIRRORING_DRIVER = 0x00000008
   Local $DISPLAY_DEVICE_PRIMARY_DEVICE = 0x00000004

   Local $tag_POINTL = "long x;long y"
   Local $tag_DEVMOD = "char dmDeviceName[32];ushort dmSpecVersion;ushort dmDriverVersion;short dmSize;" & _
         "ushort dmDriverExtra;dword dmFields;" & $tag_POINTL & ";dword dmDisplayOrientation;dword dmDisplayFixedOutput;" & _
         "short dmColor;short dmDuplex;short dmYResolution;short dmTTOption;short dmCollate;" & _
         "byte dmFormName[32];ushort LogPixels;dword dmBitsPerPel;int dmPelsWidth;dword dmPelsHeight;" & _
         "dword dmDisplayFlags;dword dmDisplayFrequency"
   Local Const $ENUM_CURRENT_SETTINGS = -1

   Local $i = 0

   While 1

      $struct = DllStructCreate($tag_DISPLAY_DEVICE)
      DllStructSetData($struct, "cb", DllStructGetSize($struct))

      Local $enum = DllCall("user32.dll", "int", "EnumDisplayDevices", "ptr", 0, "dword", $i, "ptr", DllStructGetPtr($struct), "dword", 0)
      If Not $enum[0] Then ExitLoop

      If Not BitAND(DllStructGetData($struct, "StateFlags"), $DISPLAY_DEVICE_MIRRORING_DRIVER) Then ; avoid Virtual Displays
;~        ConsoleWrite(DllStructGetData($struct, "DeviceName") & @TAB & "Primary: " & (BitAND(DllStructGetData($struct, "StateFlags"), $DISPLAY_DEVICE_PRIMARY_DEVICE) > 0) & @CRLF)

         $dev = DllStructCreate($tag_DEVMOD)
         DllStructSetData($dev, "dmSize", DllStructGetSize($dev))
         $enum = DllCall("user32.dll", "int", "EnumDisplaySettings", "str", DllStructGetData($struct, "DeviceName"), "dword", $ENUM_CURRENT_SETTINGS, "ptr", DllStructGetPtr($dev))

         If IsNumber($returnArray[0][0]) Then ReDim $returnArray[UBound($returnArray)+1][UBound($returnArray,2)] ; if not first fill in, upsize

         $returnArray[UBound($returnArray)-1][0] = DllStructGetData($dev, "x")
         $returnArray[UBound($returnArray)-1][1] = DllStructGetData($dev, "y")
         $returnArray[UBound($returnArray)-1][2] = DllStructGetData($dev, "dmPelsWidth")
         $returnArray[UBound($returnArray)-1][3] = DllStructGetData($dev, "dmPelsHeight")
         $returnArray[UBound($returnArray)-1][4] = (BitAND(DllStructGetData($struct, "StateFlags"), $DISPLAY_DEVICE_PRIMARY_DEVICE) > 0) ; is primary?
		 $returnArray[UBound($returnArray)-1][5] = DllStructGetData($dev, "dmFields")

      EndIf

      $i += 1

   WEnd

   Return $returnArray

EndFunc

Func _displayGetPosHash()

   Local $pos = _displayGetPos()
   Local $posString = ""
   For $i=0 To UBound($pos)-1
     For $j=0 To UBound($pos,2)-1
       $posString &= $pos[$i][$j]
     Next
   Next

   Return _WinAPI_HashString($posString, True)

EndFunc

; return: $infos[n .. display index][0 .. position, 1 .. position of working area (minus taskbar etc.), 2 .. is primary, 3 .. device name]
Func _displayGetEnum()
   Local $monitors = _WinAPI_EnumDisplayMonitors()
   Local $ret[UBound($monitors)-1][4]
   Local $infos[4]
   For $i = 1 To UBound($monitors)-1
	  _displayGetMonitorInfos($monitors[$i][0], $infos)
	  For $j=0 To UBound($infos)-1
		 $ret[$i-1][$j] = $infos[$j]
	  Next
   Next
   Return $ret
EndFunc

; return: $infos[0 .. position, 1 .. position of working area (minus taskbar etc.), 2 .. is primary, 3 .. device name]
Func _displayGetPrimary()
   Local $monitors = _WinAPI_EnumDisplayMonitors()
   Local $infos[4]
   For $i = 1 To UBound($monitors)-1
	  _displayGetMonitorInfos($monitors[$i][0], $infos)
	  If $infos[2] == 1 Then Return $infos
   Next
EndFunc

; author: Holger
Func _displayGetFromPoint($x, $y)
    $hMonitor = DllCall("user32.dll", "hwnd", "MonitorFromPoint", _
                                            "int", $x, _
                                            "int", $y, _
                                            "int", $_DISPLAY_DEFAULTTONULL)
    Return $hMonitor[0]
EndFunc

; author: Holger
Func _displayGetMonitorInfos($hMonitor, ByRef $arMonitorInfos)
    Local $stMONITORINFOEX = DllStructCreate("dword;int[4];int[4];dword;char[" & $_DISPLAY_CCHDEVICENAME & "]")
    DllStructSetData($stMONITORINFOEX, 1, DllStructGetSize($stMONITORINFOEX))

    $nResult = DllCall("user32.dll", "int", "GetMonitorInfo", _
                                            "hwnd", $hMonitor, _
                                            "ptr", DllStructGetPtr($stMONITORINFOEX))
    If $nResult[0] = 1 Then
        $arMonitorInfos[0] = DllStructGetData($stMONITORINFOEX, 2, 1) & ";" & _
            DllStructGetData($stMONITORINFOEX, 2, 2) & ";" & _
            DllStructGetData($stMONITORINFOEX, 2, 3) & ";" & _
            DllStructGetData($stMONITORINFOEX, 2, 4)
        $arMonitorInfos[1] = DllStructGetData($stMONITORINFOEX, 3, 1) & ";" & _
            DllStructGetData($stMONITORINFOEX, 3, 2) & ";" & _
            DllStructGetData($stMONITORINFOEX, 3, 3) & ";" & _
            DllStructGetData($stMONITORINFOEX, 3, 4)
        $arMonitorInfos[2] = DllStructGetData($stMONITORINFOEX, 4)
        $arMonitorInfos[3] = DllStructGetData($stMONITORINFOEX, 5)
    EndIf

    Return $nResult[0]
EndFunc