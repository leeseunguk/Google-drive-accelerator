# 로그인할 때 자동으로 마운트되도록 시작프로그램 바로가기를 만듭니다(관리자 권한 불필요).
$lnk = Join-Path ([Environment]::GetFolderPath("Startup")) "rclone-gdrive-mount.lnk"
$sh = New-Object -ComObject WScript.Shell
$s = $sh.CreateShortcut($lnk)
$s.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$s.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSScriptRoot\Mount-GDrive.ps1`""
$s.WorkingDirectory = $PSScriptRoot
$s.WindowStyle = 7
$s.Save()
Write-Host "자동 시작 등록: $lnk" -ForegroundColor Green
