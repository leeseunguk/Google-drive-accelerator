# Google 로그인을 다시 하고(empty token, invalid_grant 등), 마운트를 자동으로 다시 겁니다.
. "$PSScriptRoot\config.ps1"
$RemoteName = ($Remote -split ":")[0]

# 로그인 전에 '내 드라이브 전체'가 보이도록 설정을 바로잡습니다.
# (공유 드라이브/공유 문서함/특정 폴더 지정, 좁은 권한 범위 drive.file 등을 해제)
& $RcloneExe --config $RcloneConf config update $RemoteName scope=drive team_drive= root_folder_id= shared_with_me=false --non-interactive *> $null

Write-Host @"
브라우저에서 Google 로그인 창이 열립니다. 마운트할 Drive 계정으로 로그인하고 [허용]을 누르세요.
 - 계정 선택 화면에서 다른 계정을 고르지 않도록 주의하세요.
 - 'Google에서 확인하지 않은 앱' 경고: [고급] -> [rclone(으)로 이동(안전하지 않음)] -> [계속]
 - 권한 화면에 체크 상자가 있으면 'Google Drive의 모든 파일 보기, 수정...'에 꼭 체크하세요.
 - 'Configure this as a Shared Drive (Team Drive)?' 질문에는 n (Enter도 n)
"@
& $RcloneExe --config $RcloneConf config reconnect "${RemoteName}:"
& $RcloneExe --config $RcloneConf config update $RemoteName team_drive= root_folder_id= --non-interactive *> $null

& $RcloneExe --config $RcloneConf about "${RemoteName}:" *> $null
if ($LASTEXITCODE -ne 0) { Write-Host "아직 접속되지 않습니다. 설치.cmd를 실행해 보세요." -ForegroundColor Red; exit 1 }
Write-Host "`n다시 연결됨. 연결 정보:" -ForegroundColor Green
Show-RemoteInfo $RcloneExe $RcloneConf $RemoteName

Write-Host "`n마운트를 다시 겁니다."
if (Test-Path "$DriveLetter\") { & "$PSScriptRoot\Unmount-GDrive.ps1"; if ($LASTEXITCODE -ne 0) { exit 1 } }
& "$PSScriptRoot\Mount-GDrive.ps1"
exit $LASTEXITCODE
