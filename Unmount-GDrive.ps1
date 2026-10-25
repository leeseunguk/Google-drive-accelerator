# 업로드 대기열을 확인한 뒤 마운트를 안전하게 해제합니다.
param([switch]$Force)
. "$PSScriptRoot\config.ps1"
$rc = "127.0.0.1:$RcPort"

function Get-Pending {
    $s = & $RcloneExe rc --url "http://$rc/" vfs/stats 2>$null | ConvertFrom-Json
    if (-not $s) { return $null }
    return [int]$s.diskCache.uploadsInProgress + [int]$s.diskCache.uploadsQueued
}

$pending = Get-Pending
if ($null -eq $pending) {
    Write-Host "원격 제어 응답이 없습니다. 실행 중인 마운트를 찾아 종료합니다." -ForegroundColor Yellow
} else {
    $waited = 0
    while ($pending -gt 0 -and -not $Force) {
        Write-Host "업로드 대기 중인 파일 $pending 개 - 끝날 때까지 기다립니다 (강제 해제: -Force)"
        Start-Sleep -Seconds 5; $waited += 5
        $pending = Get-Pending
    }
    & $RcloneExe rc --url "http://$rc/" core/quit 2>$null | Out-Null
    for ($i = 0; $i -lt 15 -and (Test-Path "$DriveLetter\"); $i++) { Start-Sleep -Seconds 1 }
}

if (Test-Path "$DriveLetter\") {
    Get-CimInstance Win32_Process -Filter "name='rclone.exe'" |
        Where-Object { $_.CommandLine -match " mount " -and $_.CommandLine -match [regex]::Escape($DriveLetter) } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
    Start-Sleep -Seconds 2
}
if (Test-Path "$DriveLetter\") { Write-Host "해제 실패: $DriveLetter" -ForegroundColor Red; exit 1 }
Write-Host "해제 완료: $DriveLetter" -ForegroundColor Green
