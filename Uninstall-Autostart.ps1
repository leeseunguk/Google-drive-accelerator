$lnk = Join-Path ([Environment]::GetFolderPath("Startup")) "rclone-gdrive-mount.lnk"
if (Test-Path $lnk) { Remove-Item $lnk; Write-Host "자동 시작 해제 완료" -ForegroundColor Green } else { Write-Host "등록된 자동 시작이 없습니다." }
