# Google Drive를 rclone으로 드라이브 문자에 마운트합니다.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\config.ps1"

if (-not $RcloneExe -or -not (Test-Path "${env:ProgramFiles(x86)}\WinFsp\bin\winfsp-x64.dll")) {
    Write-Host "rclone 또는 WinFsp가 없습니다. 먼저 설치.cmd를 실행하세요." -ForegroundColor Red
    exit 1
}
if (Test-Path "$DriveLetter\") {
    Write-Host "$DriveLetter 는 이미 사용 중입니다(이미 마운트됐거나 다른 드라이브)." -ForegroundColor Yellow
    exit 0
}
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($admin) {
    Write-Host "관리자 권한으로 실행 중입니다. 관리자로 마운트한 드라이브는 일반 탐색기에서 안 보일 수 있으니, 그냥 더블클릭으로 실행하세요." -ForegroundColor Yellow
}
New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null
$log = Join-Path $CacheDir "mount.log"

$rcArgs = @(
    "mount", $Remote, $DriveLetter,
    "--config", "`"$RcloneConf`"",
    "--vfs-cache-mode", "full",
    "--cache-dir", "`"$CacheDir`"",
    "--vfs-cache-max-size", $CacheMaxSize,
    "--vfs-cache-max-age", $CacheMaxAge,
    "--vfs-read-chunk-size", $ChunkSize,
    "--vfs-read-chunk-streams", $ChunkStreams,
    "--buffer-size", "64M",
    "--dir-cache-time", "1h",
    "--poll-interval", "1m",
    "--volname", "`"$VolumeName`"",
    "--rc", "--rc-addr", "127.0.0.1:$RcPort", "--rc-no-auth",
    "--log-file", "`"$log`"", "--log-level", "INFO"
)
if ($NetworkDrive) { $rcArgs += "--network-mode" }

# 내 드라이브 전체가 보이도록, 공유 드라이브/공유 문서함/특정 폴더 설정이 들어 있으면 경고합니다.
$RemoteName = ($Remote -split ":")[0]
$cfgJson = & $RcloneExe --config $RcloneConf config dump 2>$null | Out-String | ConvertFrom-Json
$rc = $cfgJson.$RemoteName
if ($rc -and ($rc.team_drive -or $rc.root_folder_id -or $rc.shared_with_me -eq "true")) {
    Write-Host "주의: remote가 내 드라이브 전체가 아니라 공유 드라이브/공유 문서함/특정 폴더로 설정돼 있습니다. 재연결.cmd를 실행하면 내 드라이브로 되돌립니다." -ForegroundColor Yellow
}

$logStart = if (Test-Path $log) { (Get-Item $log).Length } else { 0 }
$p = Start-Process -FilePath $RcloneExe -ArgumentList $rcArgs -WindowStyle Hidden -PassThru

for ($i = 0; $i -lt 30; $i++) {
    if (Test-Path "$DriveLetter\") { Write-Host "마운트 완료: $DriveLetter  ($Remote)" -ForegroundColor Green; exit 0 }
    if ($p.HasExited) { break }   # rclone이 바로 끝났으면 더 기다리지 않습니다
    Start-Sleep -Seconds 1
}
# 이번 실행에서 새로 쓰인 로그만 봅니다
$fs = [IO.File]::Open($log, 'Open', 'Read', 'ReadWrite'); $fs.Seek($logStart, 'Begin') | Out-Null
$newLog = (New-Object IO.StreamReader($fs)).ReadToEnd(); $fs.Close()
if ($newLog -match "empty token|invalid_grant|token expired|couldn't fetch token|reconnect") {
    Write-Host "Google 로그인 정보가 없거나 만료됐습니다. 재연결.cmd를 실행해 다시 로그인한 뒤 마운트.cmd를 실행하세요." -ForegroundColor Red
} else {
    Write-Host "마운트되지 않았습니다. 로그 확인: $log" -ForegroundColor Red
}
($newLog -split "`r?`n" | Where-Object { $_ } | Select-Object -Last 5) | ForEach-Object { Write-Host "   $_" }
exit 1
