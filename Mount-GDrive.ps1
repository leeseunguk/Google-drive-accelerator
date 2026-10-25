# Google Drive를 rclone으로 드라이브 문자에 마운트합니다.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\config.ps1"

if (-not (Test-Path "${env:ProgramFiles(x86)}\WinFsp\bin\winfsp-x64.dll")) {
    Write-Host "WinFsp가 없습니다. 먼저 설치하세요: winget install WinFsp.WinFsp" -ForegroundColor Red
    exit 1
}
if (Test-Path "$DriveLetter\") {
    Write-Host "$DriveLetter 는 이미 사용 중입니다(이미 마운트됐거나 다른 드라이브)." -ForegroundColor Yellow
    exit 0
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
    "--network-mode",
    "--rc", "--rc-addr", "127.0.0.1:$RcPort", "--rc-no-auth",
    "--log-file", "`"$log`"", "--log-level", "INFO"
)
Start-Process -FilePath $RcloneExe -ArgumentList $rcArgs -WindowStyle Hidden

for ($i = 0; $i -lt 30; $i++) {
    if (Test-Path "$DriveLetter\") { Write-Host "마운트 완료: $DriveLetter  ($Remote)" -ForegroundColor Green; exit 0 }
    Start-Sleep -Seconds 1
}
Write-Host "30초 안에 마운트되지 않았습니다. 로그 확인: $log" -ForegroundColor Red
Get-Content $log -Tail 20 -ErrorAction SilentlyContinue
exit 1
