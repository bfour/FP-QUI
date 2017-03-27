#cs

   Specially for FP-QUI: WM_COPYDATA support library
   wmCopyData.au3 Copyright 2017 Alexey Kuryakin (kouriakine@mail.ru)

   FP-QUI Copyright 2010-2017 Florian Pollak (bfourdev@gmail.com)

#ce

;global const $WM_COPYDATA = 0x004A     ; https://msdn.microsoft.com/en-us/library/windows/desktop/ms649011(v=vs.85).aspx
global const $fpQuiMagic  = 0x21495551  ; = dump of 'QUI!' as integer - uses as message idetifier in COPYDATASTRUCT.dwData

global const $wmCopyDataFifoSize  = 256                                 ; FIFO size
global       $wmCopyDataFifoCount = 0                                   ; FIFO count
global       $wmCopyDataFifoHead  = 0                                   ; FIFO head
global       $wmCopyDataFifoBuff[$wmCopyDataFifoSize]                   ; FIFO buffer

Global       $_WMCOPYDATA_IS_INITIALIZED = False

func wmCopyDataFifoInit()                                               ; Initialize FIFO
    $wmCopyDataFifoCount = 0                                            ; Clear Counter
    $wmCopyDataFifoHead  = 0                                            ; Clear Head
    for $i = 0 to $wmCopyDataFifoSize - 1                               ; For each item
        $wmCopyDataFifoBuff[$i] = ''                                    ; Clear the item
    next                                                                ;
endfunc                                                                 ; Done

func wmCopyDataFifoPut($sData)                                          ; Put data to FIFO tail
    if $wmCopyDataFifoCount < $wmCopyDataFifoSize then                  ; If not overflow
        local $tail = ($wmCopyDataFifoHead + $wmCopyDataFifoCount)      ; Flat tail index
        $tail = Mod($tail,$wmCopyDataFifoSize)                          ; Cycled tail index
        $wmCopyDataFifoBuff[$tail] = $sData                             ; Put data to tail
        $wmCopyDataFifoCount = $wmCopyDataFifoCount + 1                 ; Increment Count
        return 1                                                        ; Report success
    endif                                                               ; Otherwise
    return 0                                                            ; Report failure
endfunc                                                                 ; Done

func wmCopyDataFifoGet()                                                ; Get data from FIFO head
    if $wmCopyDataFifoCount > 0 then                                    ; If not empty
        local $head = $wmCopyDataFifoHead                               ; Get head index
        local $sData = $wmCopyDataFifoBuff[$head]                       ; Get data from head
        $wmCopyDataFifoHead = Mod($head + 1,$wmCopyDataFifoSize)        ; Next cycled head index
        $wmCopyDataFifoCount = $wmCopyDataFifoCount - 1                 ; Decrement Count
        $wmCopyDataFifoBuff[$head] = ''                                 ; Clear item to free memory
        return $sData                                                   ; Return data
    endif                                                               ; Otherwise
    return ''                                                           ; Return empty
endfunc                                                                 ; Done

func HANDLE_WM_COPYDATA($hWnd, $msgID, $wParam, $lParam)                ; Handler of WM_COPYDATA message
    local $tCOPYDATA = DllStructCreate('dword;dword;ptr', $lParam)      ; COPYDATASTRUCT:
    local $dwData = DllStructGetData($tCOPYDATA, 1)                     ; Data identifier
    local $cbData = DllStructGetData($tCOPYDATA, 2)                     ; Data byte size
    local $lpData = DllStructGetData($tCOPYDATA, 3)                     ; Data pointer
    if ( $dwData == $fpQuiMagic ) then                                  ; Identifier Ok?
        local $tMsg = DllStructCreate('char[' & $cbData & ']', $lpData) ; Extract data
        local $wmData = DllStructGetData($tMsg, 1)                      ; And get as string
        local $wmFlag = wmCopyDataFifoPut($wmData)                      ; Put received data to FIFO
        return $wmFlag                                                  ; Notify sender - data was handled
    endif                                                               ; If data identifier is not valid,
    return 0                                                            ; Notify sender - data not handled
endfunc                                                                 ; Done HANDLE_WM_COPYDATA

func wmCopyDataInit()                                                  ; Initialize WM_COPYDATA handling
   If $_WMCOPYDATA_IS_INITIALIZED Then Return
   GUIRegisterMsg($WM_COPYDATA, 'HANDLE_WM_COPYDATA')                  ; Register message handler
   wmCopyDataFifoInit()                                                ; Initialize messages FIFO
   $_WMCOPYDATA_IS_INITIALIZED = True
endfunc                                                                ; Done wmCopyDataInit

func wmCopyDataSend($hWnd, $sData)                                      ; Send WM_COPYDATA message
    local $dwData = $fpQuiMagic                                         ; Data identifier
    local $cbData = StringLen($sData) + 1                               ; Data size
    local $tMsg = DllStructCreate('char[' & $cbData & ']')              ; Allocate buffer
    DllStructSetData($tMsg, 1, $sData)                                  ; Set data buffer
    local $lpData = DllStructGetPtr($tMsg)                              ; Data pointer
    local $tCOPYDATA = DllStructCreate('dword;dword;ptr')               ; COPYDATASTRUCT:
    DllStructSetData($tCOPYDATA, 1, $dwData)                            ; Set data identifier
    DllStructSetData($tCOPYDATA, 2, $cbData)                            ; Set data size
    DllStructSetData($tCOPYDATA, 3, $lpData)                            ; Set data pointer
    local $pCOPYDATA = DllStructGetPtr($tCOPYDATA)                      ; COPYDATASTRUCT pointer
    $Ret = DllCall('user32.dll', 'lparam', 'SendMessage',               ; SendMessage API call
                   'hwnd', $hWnd,                                       ; Target window handle
                   'int',  $WM_COPYDATA,                                ; Message ID
                   'wparam', 0,                                         ; wparam should be source window handle
                   'lparam', $pCOPYDATA)                                ; lparam should be COPYDATASTRUCT pointer
    if (@error) or ($Ret[0] = -1) then                                  ; Check result
        return 0                                                        ; Notify error
    endif                                                               ;
    return $Ret[0]                                                      ; Result 1/0=success/fail sent
endfunc                                                                 ; Done wmCopyDataSend

