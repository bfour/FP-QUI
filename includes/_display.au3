#cs

	author: "SkinnyWhiteGuy" on http://www.autoitscript.com/forum/index.php?showtopic=105921
	modified by Florian Pollak

#ce

#include-once

#include <WinAPIMisc.au3>

;~ #include <Array.au3>
;~ _ArrayDisplay(_displayGetPos())
;~ MsgBox(1,"",_displayGetPosHash())
;~ MsgBox(1,"",_displayGetPrimary())

; return: index (int) of primary display
Func _displayGetPrimary()
   Local $pos = _displayGetPos()
   For $i = 0 To UBound($pos)-1
	  If $pos[$i][4] == True Then Return $i
   Next
   Return SetError(1,0,"")
EndFunc

;out: [n][0:x 1:y 2:width 3:height 4:is primary]
Func _displayGetPos()

	Local $returnArray[1][5]

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
;~ 		 ConsoleWrite(DllStructGetData($struct, "DeviceName") & @TAB & "Primary: " & (BitAND(DllStructGetData($struct, "StateFlags"), $DISPLAY_DEVICE_PRIMARY_DEVICE) > 0) & @CRLF)

			$dev = DllStructCreate($tag_DEVMOD)
			DllStructSetData($dev, "dmSize", DllStructGetSize($dev))
			$enum = DllCall("user32.dll", "int", "EnumDisplaySettings", "str", DllStructGetData($struct, "DeviceName"), "dword", $ENUM_CURRENT_SETTINGS, "ptr", DllStructGetPtr($dev))

			If IsNumber($returnArray[0][0]) Then ReDim $returnArray[UBound($returnArray)+1][UBound($returnArray,2)] ; if not first fill in, upsize

			$returnArray[UBound($returnArray)-1][0] = DllStructGetData($dev, "x")
			$returnArray[UBound($returnArray)-1][1] = DllStructGetData($dev, "y")
			$returnArray[UBound($returnArray)-1][2] = DllStructGetData($dev, "dmPelsWidth")
			$returnArray[UBound($returnArray)-1][3] = DllStructGetData($dev, "dmPelsHeight")
			$returnArray[UBound($returnArray)-1][4] = (BitAND(DllStructGetData($struct, "StateFlags"), $DISPLAY_DEVICE_PRIMARY_DEVICE) > 0) ; is primary?

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