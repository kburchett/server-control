# Windows-side RDP tunnel: bore.pub:58631 -> this machine's RDP (3389). Runs at every boot as SYSTEM.
[Net.ServicePointManager]::SecurityProtocol = 'Tls12'
$d = 'C:\bore'; New-Item -ItemType Directory -Force $d | Out-Null
$wc = New-Object Net.WebClient
# Newer builds need Windows 10+; try older releases first until one runs on 2012 R2.
foreach ($v in '0.5.0','0.5.1','0.5.2','0.6.0') {
  try {
    $zip = "$d\bore.zip"; Remove-Item "$d\bore.exe" -ErrorAction SilentlyContinue
    $wc.DownloadFile("https://github.com/ekzhang/bore/releases/download/v$v/bore-v$v-x86_64-pc-windows-msvc.zip", $zip)
    $sh = New-Object -ComObject Shell.Application; $sh.NameSpace($d).CopyHere($sh.NameSpace($zip).Items(), 16); Start-Sleep 2
    $out = & "$d\bore.exe" --version 2>&1
    if ($LASTEXITCODE -eq 0) { Write-Host "bore $v works: $out"; break }
  } catch { Write-Host "bore $v failed: $_" }
}
Set-Content "$d\run.cmd" "@echo off`r`n:a`r`n$d\bore.exe local 3389 --to bore.pub --port 58631 >> $d\bore.log 2>&1`r`ntimeout /t 5 /nobreak >nul`r`ngoto a" -Encoding Ascii
Set-Content "$d\hide.vbs" "CreateObject(""WScript.Shell"").Run ""$d\run.cmd"", 0, False" -Encoding Ascii
# Runs at logon of this user (Windows here auto-logs on at boot); no admin rights needed.
schtasks /create /tn bore-rdp /tr "wscript.exe $d\hide.vbs" /sc onlogon /it /f | Out-Null
Start-Process wscript.exe "$d\hide.vbs"
Start-Sleep 5; Get-Content "$d\bore.log" -Tail 3
Write-Host "DONE - RDP tunnel: bore.pub:58631"
