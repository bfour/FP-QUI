##############################################################
### Copyright Alexey Kuryakin 2017 (kouriakine@mail.ru) ######
##############################################################

##############################################################
### Load language files.
##############################################################
LoadLanguageFile "${NSISDIR}\Contrib\Language files\English.nlf"
LoadLanguageFile "${NSISDIR}\Contrib\Language files\Russian.nlf"

##############################################################
### General product dependent constants.
##############################################################
!define PRODUCT "FP-QUI"
Name "${PRODUCT}"
OutFile "..\..\..\install-daqgroup-notifier.exe"
InstallDir "$PROGRAMFILES\${PRODUCT}"
LangString CaptionText ${LANG_ENGLISH} "Install $(^Name) (built ${__DATE__}-${__TIME__})"
LangString CaptionText ${LANG_RUSSIAN} "Установка $(^Name) (сборка ${__DATE__}-${__TIME__})"
Caption "$(CaptionText)"
!define VersionMajor    "1"
!define VersionMinor    "0"
!define DisplayVersion  "${VersionMajor}.${VersionMinor}"
!define Publisher       "FP-QUI Copyright 2010-2017 Florian Pollak (bfourdev@gmail.com). Installer & addon tools contribution: Alexey Kuryakin (kouriakine@mail.ru)"
!define URLUpdateInfo   "https://github.com/bfour/FP-QUI"
!define URLInfoAbout    "https://bfourdev.wordpress.com/fp-qui"
!define HelpLink        "https://sourceforge.net/projects/fp-qui"

##############################################################
### General installer options.
##############################################################
SetCompressor /FINAL /SOLID lzma
SetCompressorDictSize 64
SetDatablockOptimize on
SetCompress force
CRCCheck force
XPStyle on
SetFont "Courier New" 12
InstallColors AAAAAA 000000
InstProgressFlags smooth colored
ShowInstDetails show
ShowUninstDetails show

##############################################################
### Compilation time scripts.
##############################################################
!system "Release.cmd"

##############################################################
### License page.
##############################################################
Page License
LicenseLangString LicenseSource ${LANG_ENGLISH} "license.txt"
LicenseLangString LicenseSource ${LANG_RUSSIAN} "license.txt"
LicenseData $(LicenseSource)

##############################################################
### Components page.
##############################################################
Page Components

##############################################################
### Directory page.
##############################################################
Page Directory

##############################################################
### InstFiles page. Put installation sections there.
##############################################################
Page InstFiles

!macro StopRunningProduct
  DetailPrint ""
  DetailPrint "Stop running ${PRODUCT}..."
  DetailPrint ""
  SetOutPath "$TEMP"
  nsExec::Exec /OEM /TIMEOUT=10000 'taskkill /F /FI "WINDOWTITLE eq FP-QUI/dispatcherWindow" /FI "IMAGENAME eq FP-QUICore.exe"'
  Pop $0 # return value/error/timeout
  DetailPrint "Return value: $0"
  nsExec::Exec /OEM /TIMEOUT=10000 'ping -n 3 127.0.0.1' # delay 3 sec
  Pop $0 # return value/error/timeout
  DetailPrint "Return value: $0"
!macroend

!macro DeleteProductRegistry
  DetailPrint ""
  DetailPrint "Unregister ${PRODUCT}..."
  DetailPrint ""
  SetOutPath "$TEMP"
  DeleteRegKey HKLM "SOFTWARE\${PRODUCT}"
  DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT}"
!macroend

!macro DeleteProductCommonFiles
   DetailPrint ""
   DetailPrint "Delete ${PRODUCT} common files..."
   DetailPrint ""
   SetOutPath "$WINDIR"
   Delete fpquitip.exe
   Delete fpquitipw.exe
   Delete fpquitip.txt
   Delete fpquitip.htm
   Delete fpquisend.exe
   Delete fpquisendw.exe
   Delete fpquisend.txt
   Delete fpquisend.htm
!macroend

!macro DeleteProductProgramFiles
  DetailPrint ""
  DetailPrint "Delete ${PRODUCT} program files..."
  DetailPrint ""
  SetOutPath "$TEMP"
  IfFileExists "$INSTDIR\*.*" 0 +2
  RMDir /r "$INSTDIR"
!macroend

!macro InstallProductRegistry
  DetailPrint ""
  DetailPrint "Register ${PRODUCT}..."
  DetailPrint ""
  SetOutPath "$INSTDIR"
  WriteRegStr HKLM "SOFTWARE\${PRODUCT}" "dir" "$INSTDIR"
  WriteRegStr HKLM "SOFTWARE\${PRODUCT}" "exe" "FP-QUI.exe"
  WriteRegStr HKLM "SOFTWARE\${PRODUCT}" "coreExe" "FP-QUICore.exe"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT}" "DisplayName" "${PRODUCT} - Tooltip Notification System"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT}" "DisplayIcon" "$INSTDIR\icon.ico"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT}" "VersionMajor" "${VersionMajor}"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT}" "VersionMinor" "${VersionMinor}"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT}" "DisplayVersion" "${DisplayVersion}"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT}" "Publisher" "${Publisher}"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT}" "URLUpdateInfo" "${URLUpdateInfo}"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT}" "URLInfoAbout" "${URLInfoAbout}"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT}" "HelpLink" "${HelpLink}"
!macroend

!macro InstallProductCommonFiles
  DetailPrint ""
  DetailPrint "Install ${PRODUCT} common files..."
  DetailPrint ""
  SetOutPath "$WINDIR"
  File "fpquitip.exe"
  File "fpquitipw.exe"
  File "fpquitip.txt"
  File "fpquitip.htm"
  File "fpquisend.exe"
  File "fpquisendw.exe"
  File "fpquisend.txt"
  File "fpquisend.htm"
!macroend

!macro InstallProductProgramFiles
  DetailPrint ""
  DetailPrint "Install ${PRODUCT} program files..."
  DetailPrint ""
  SetOutPath "$INSTDIR"
  File /r /x "*.nsi" "*.*"
!macroend

!macro LaunchProduct
  DetailPrint ""
  DetailPrint "Launch ${PRODUCT}..."
  DetailPrint ""
  SetOutPath "$TEMP"
  nsExec::Exec /OEM /TIMEOUT=10000 '"$INSTDIR\FP-QUI.exe" "<text>${PRODUCT} installation complete.</text><delay>15000</delay><ico>$INSTDIR\icon.ico</ico>"'
  Pop $0 # return value/error/timeout
  DetailPrint "Return value: $0"
  nsExec::Exec /OEM /TIMEOUT=10000 'ping -n 3 127.0.0.1' # delay 3 sec
  Pop $0 # return value/error/timeout
  DetailPrint "Return value: $0"
!macroend

!macro LaunchProductDemo
  DetailPrint ""
  DetailPrint "Show DEMO for ${PRODUCT}..."
  DetailPrint ""
  SetOutPath "$TEMP"
  nsExec::Exec /OEM /TIMEOUT=10000 '"$INSTDIR\fpquitip.exe" --demo'
  Pop $0 # return value/error/timeout
  DetailPrint "Return value: $0"
!macroend

LangString SectionCheckAccessRights ${LANG_ENGLISH} "Check access rights..."
LangString SectionCheckAccessRights ${LANG_RUSSIAN} "Проверка прав доступа..."
Section "-$(SectionCheckAccessRights)"
  SectionIn RO # Section is read-only
  Call CheckAccessRights
SectionEnd

LangString SectionProductStop ${LANG_ENGLISH} "Stop running ${PRODUCT}"
LangString SectionProductStop ${LANG_RUSSIAN} "Завершить работу ${PRODUCT}"
Section "!$(SectionProductStop)"
  SectionIn RO # Section is read-only
  SetShellVarContext all
  !insertmacro StopRunningProduct
SectionEnd

LangString SectionProductRemove ${LANG_ENGLISH} "Remove old ${PRODUCT}"
LangString SectionProductRemove ${LANG_RUSSIAN} "Удалить старый ${PRODUCT}"
Section "!$(SectionProductRemove)"
  SectionIn RO # Section is read-only
  SetShellVarContext all
  !insertmacro DeleteProductRegistry
  !insertmacro DeleteProductCommonFiles
  !insertmacro DeleteProductProgramFiles
SectionEnd

LangString SectionFqQui ${LANG_ENGLISH} "Install ${PRODUCT}"
LangString SectionFqQui ${LANG_RUSSIAN} "Установить ${PRODUCT}"
Section "!$(SectionFqQui)"
  SectionIn RO # Section is read-only
  SetShellVarContext all
  !insertmacro InstallProductCommonFiles
  !insertmacro InstallProductProgramFiles
  WriteUninstaller $INSTDIR\Uninstall.Exe
SectionEnd

LangString SectionRegisterProduct ${LANG_ENGLISH} "Register ${PRODUCT}"
LangString SectionRegisterProduct ${LANG_RUSSIAN} "Зарегистрировать ${PRODUCT}"
Section "!$(SectionRegisterProduct)"
  SectionIn RO # Section is read-only
  SetShellVarContext all
  !insertmacro InstallProductRegistry
SectionEnd

LangString SectionLaunchProduct ${LANG_ENGLISH} "Launch $(^Name)"
LangString SectionLaunchProduct ${LANG_RUSSIAN} "Запустить $(^Name)"
Section "!$(SectionLaunchProduct)"
  SetShellVarContext all
  !insertmacro LaunchProduct
SectionEnd

LangString SectionLaunchDemo ${LANG_ENGLISH} "Launch DEMO"
LangString SectionLaunchDemo ${LANG_RUSSIAN} "Запустить DEMO"
Section /o "$(SectionLaunchDemo)"
  SetShellVarContext all
  !insertmacro LaunchProductDemo
SectionEnd

LangString SectionCheckErrors ${LANG_ENGLISH} "Check errors..."
LangString SectionCheckErrors ${LANG_RUSSIAN} "Проверить статус..."
LangString CheckErrorsOkMsg ${LANG_ENGLISH} "Ok, no errors found during installation."
LangString CheckErrorsOkMsg ${LANG_RUSSIAN} "Ok, при инсталляции ошибок не найдено."
LangString CheckErrorsFailsMsg ${LANG_ENGLISH} "ATTENTION: some errors found during installation!"
LangString CheckErrorsFailsMsg ${LANG_RUSSIAN} "ВНИМАНИЕ: при инсталляции были найдены ошибки."
Section "-$(SectionCheckErrors)"
  SectionIn RO # Section is read-only
  IfErrors +2 0
  DetailPrint "$(CheckErrorsOkMsg)"
  IfErrors 0 +2
  DetailPrint "$(CheckErrorsFailsMsg)"
SectionEnd

##############################################################
### Uninstall confirmation page.
##############################################################
UninstPage uninstConfirm

##############################################################
### Uninstall page.
##############################################################
UninstPage InstFiles

LangString UninstallConfirmation ${LANG_ENGLISH} "Do you really want to uninstall $(^Name)?"
LangString UninstallConfirmation ${LANG_RUSSIAN} "Вы в самом  деле хотите удалить $(^Name)?"
LangString UninstallMessage ${LANG_ENGLISH} "Right, do not uninstall nothing & never..."
LangString UninstallMessage ${LANG_RUSSIAN} "Точно, никогда и ничего не надо удалять..."
Section "Uninstall"
  Call un.CheckAccessRights
  SetOutPath $TEMP
  SetShellVarContext all
  MessageBox MB_YESNO "$(UninstallConfirmation)" IDYES DoUninstall IDNO DoAbort
  DoAbort:
   Abort "$(UninstallMessage)"
  DoUninstall:
   SetShellVarContext all
   !insertmacro StopRunningProduct
   !insertmacro DeleteProductRegistry
   !insertmacro DeleteProductCommonFiles
   !insertmacro DeleteProductProgramFiles
SectionEnd

##############################################################
### Select installation language dialog.
##############################################################
Function SelectLanguageDialog
  IfSilent DoSilent DoSelection
  DoSilent:
   Push ${LANG_ENGLISH}  # English on silent
   Pop $LANGUAGE
   Goto DoExit
  DoSelection:
   Push ""               # for the auto count to work the first empty push (Push "") must remain
   Push ${LANG_RUSSIAN}  # Russian
   Push Russian
   Push ${LANG_ENGLISH}  # English
   Push English
   Push A                # A means auto count languages
   LangDLL::LangDialog "Installer Language" "Please select the language of the installer"
   Pop $LANGUAGE
   StrCmp $LANGUAGE "Cancel" 0 +2
    Abort
  DoExit:
FunctionEnd
##############################################################
Function un.SelectLanguageDialog
  IfSilent DoSilent DoSelection
  DoSilent:
   Push ${LANG_ENGLISH}  # English on silent
   Pop $LANGUAGE
   Goto DoExit
  DoSelection:
   Push ""               # for the auto count to work the first empty push (Push "") must remain
   Push ${LANG_RUSSIAN}  # Russian
   Push Russian
   Push ${LANG_ENGLISH}  # English
   Push English
   Push A                # A means auto count languages
   LangDLL::LangDialog "Uninstaller Language" "Please select the language of the uninstaller"
   Pop $LANGUAGE
   StrCmp $LANGUAGE "Cancel" 0 +2
    Abort
  DoExit:
FunctionEnd
##############################################################

##############################################################
### Check if LANGUAGE is valid to use.
##############################################################
Function CheckLanguage
  StrCmp $LANGUAGE ${LANG_ENGLISH} LANGUAGE_OK +1
  StrCmp $LANGUAGE ${LANG_RUSSIAN} LANGUAGE_OK +1
  MessageBox MB_OK "Invalid LANGUAGE selected ($LANGUAGE)."
  Abort "Invalid LANGUAGE selected ($LANGUAGE)."
  LANGUAGE_OK:
FunctionEnd
##############################################################
Function un.CheckLanguage
  StrCmp $LANGUAGE ${LANG_ENGLISH} LANGUAGE_OK +1
  StrCmp $LANGUAGE ${LANG_RUSSIAN} LANGUAGE_OK +1
  MessageBox MB_OK "Invalid LANGUAGE selected ($LANGUAGE)."
  Abort "Invalid LANGUAGE selected ($LANGUAGE)."
  LANGUAGE_OK:
FunctionEnd
##############################################################

##############################################################
### Check user account type.
### If it is not "Admin", ask user to continue or abort...
##############################################################
Function CheckAccessRights
  Call CheckLanguage
  StrCmp $LANGUAGE ${LANG_ENGLISH} 0 +2
   DetailPrint "Now checking user access rights..."
  StrCmp $LANGUAGE ${LANG_RUSSIAN} 0 +2
   DetailPrint "Проверка прав доступа..."
  ClearErrors
  Var /GLOBAL UserName
  UserInfo::GetName
  IfErrors AccessWin9x
  Pop $UserName
  Var /GLOBAL AccountType
  UserInfo::GetAccountType
  IfErrors AccessWin9x
  Pop $AccountType
  StrCmp $LANGUAGE ${LANG_ENGLISH} 0 +2
   DetailPrint 'Found user "$UserName" of type "$AccountType".'
  StrCmp $LANGUAGE ${LANG_RUSSIAN} 0 +2
   DetailPrint 'Найден пользователь "$UserName" типа "$AccountType".'
  StrCmp $AccountType "Admin" AccessGranted AccessConfirmation
  AccessConfirmation:
   StrCmp $LANGUAGE ${LANG_ENGLISH} 0 +2
    MessageBox MB_YESNO 'User "$UserName" of type "$AccountType" \
                         have no Administrator rights. \
                         Application may work incorrectly after such installation. \
                         Continue installation?' \
                         IDYES AccessGranted IDNO AccessDenied
   StrCmp $LANGUAGE ${LANG_RUSSIAN} 0 +2
    MessageBox MB_YESNO 'Пользователь "$UserName" типа "$AccountType" \
                         не имеет прав Администратора. \
                         Приложение может работать некорректно после такой инсталляции. \
                         Все равно продолжить инсталляцию?' \
                         IDYES AccessGranted IDNO AccessDenied
  AccessDenied:
   StrCmp $LANGUAGE ${LANG_ENGLISH} 0 +4
    DetailPrint 'Access denied to user "$UserName" of type "$AccountType".'
    MessageBox MB_OK 'Access denied to user "$UserName" of type "$AccountType".'
    Abort 'Access denied to user "$UserName" of type "$AccountType".'
   StrCmp $LANGUAGE ${LANG_RUSSIAN} 0 +4
    DetailPrint 'Доступ закрыт для пользователя "$UserName" типа "$AccountType".'
    MessageBox MB_OK 'Доступ закрыт для пользователя "$UserName" типа "$AccountType".'
    Abort 'Доступ закрыт для пользователя "$UserName" типа "$AccountType".'
  AccessWin9x:
   StrCmp $LANGUAGE ${LANG_ENGLISH} 0 +2
    DetailPrint "Don't care about rights in Windows 9x."
   StrCmp $LANGUAGE ${LANG_RUSSIAN} 0 +2
    DetailPrint "Права доступа не играют роли в Windows 9x."
  AccessGranted:
   StrCmp $LANGUAGE ${LANG_ENGLISH} 0 +3
    DetailPrint 'Access granted to user "$UserName" of type "$AccountType".'
    DetailPrint 'Now can continue installation...'
   StrCmp $LANGUAGE ${LANG_RUSSIAN} 0 +3
    DetailPrint 'Доступ открыт для пользователя  "$UserName" типа "$AccountType".'
    DetailPrint 'Можно продолжать инсталляцию...'
FunctionEnd
##############################################################
Function un.CheckAccessRights
  Call un.CheckLanguage
  StrCmp $LANGUAGE ${LANG_ENGLISH} 0 +2
   DetailPrint "Now checking user access rights..."
  StrCmp $LANGUAGE ${LANG_RUSSIAN} 0 +2
   DetailPrint "Проверка прав доступа..."
  ClearErrors
  #Var /GLOBAL UserName
  UserInfo::GetName
  IfErrors AccessWin9x
  Pop $UserName
  #Var /GLOBAL AccountType
  UserInfo::GetAccountType
  IfErrors AccessWin9x
  Pop $AccountType
  StrCmp $LANGUAGE ${LANG_ENGLISH} 0 +2
   DetailPrint 'Found user "$UserName" of type "$AccountType".'
  StrCmp $LANGUAGE ${LANG_RUSSIAN} 0 +2
   DetailPrint 'Найден пользователь "$UserName" типа "$AccountType".'
  StrCmp $AccountType "Admin" AccessGranted AccessConfirmation
  AccessConfirmation:
   StrCmp $LANGUAGE ${LANG_ENGLISH} 0 +2
    MessageBox MB_YESNO 'User "$UserName" of type "$AccountType" \
                         have no Administrator rights. \
                         Uninstallation may fails. \
                         Continue uninstallation?' \
                         IDYES AccessGranted IDNO AccessDenied
   StrCmp $LANGUAGE ${LANG_RUSSIAN} 0 +2
    MessageBox MB_YESNO 'Пользователь "$UserName" типа "$AccountType" \
                         не имеет прав Администратора. \
                         Деинсталляция может пройти некорректно. \
                         Все равно продолжить деинсталляцию?' \
                         IDYES AccessGranted IDNO AccessDenied
  AccessDenied:
   StrCmp $LANGUAGE ${LANG_ENGLISH} 0 +4
    DetailPrint 'Access denied to user "$UserName" of type "$AccountType".'
    MessageBox MB_OK 'Access denied to user "$UserName" of type "$AccountType".'
    Abort 'Access denied to user "$UserName" of type "$AccountType".'
   StrCmp $LANGUAGE ${LANG_RUSSIAN} 0 +4
    DetailPrint 'Доступ закрыт для пользователя "$UserName" типа "$AccountType".'
    MessageBox MB_OK 'Доступ закрыт для пользователя "$UserName" типа "$AccountType".'
    Abort 'Доступ закрыт для пользователя "$UserName" типа "$AccountType".'
  AccessWin9x:
   StrCmp $LANGUAGE ${LANG_ENGLISH} 0 +2
    DetailPrint "Don't care about rights in Windows 9x."
   StrCmp $LANGUAGE ${LANG_RUSSIAN} 0 +2
    DetailPrint "Права доступа не играют роли в Windows 9x."
  AccessGranted:
   StrCmp $LANGUAGE ${LANG_ENGLISH} 0 +3
    DetailPrint 'Access granted to user "$UserName" of type "$AccountType".'
    DetailPrint 'Now can continue uninstallation...'
   StrCmp $LANGUAGE ${LANG_RUSSIAN} 0 +3
    DetailPrint 'Доступ открыт для пользователя  "$UserName" типа "$AccountType".'
    DetailPrint 'Можно продолжать деинсталляцию...'
FunctionEnd
##############################################################

##############################################################
### .onInit - installer initialization function.
##############################################################
Function .onInit
  Call SelectLanguageDialog
  Call CheckLanguage
FunctionEnd
##############################################################

##############################################################
### un.onInit - uninstaller initialization function.
##############################################################
Function un.onInit
  Call un.SelectLanguageDialog
  Call un.CheckLanguage
FunctionEnd
##############################################################
