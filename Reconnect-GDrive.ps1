# Google 로그인을 다시 하고(empty token, invalid_grant 등), 마운트를 자동으로 다시 겁니다.
. "$PSScriptRoot\config.ps1"
$RemoteName = ($Remote -split ":")[0]
Write-Host @"
브라우저에서 Google 로그인 창이 열립니다. 마운트할 Drive 계정으로 로그인하고 [허용]을 누르세요.
'Google에서 확인하지 않은 앱' 경고가 나오면: [고급] -> [rclone(으)로 이동(안전하지 않음)] -> [계속]
'Configure this as a Shared Drive (Team Drive)?' 질문이 나오면 n 을 누르세요(Enter도 n).
"@
& $RcloneExe --config $RcloneConf config reconnect "${RemoteName}:"

# 공유 드라이브/공유 문서함/특정 폴더 설정을 비워 '내 드라이브' 전체가 보이게 합니다.
& $RcloneExe --config $RcloneConf config update $RemoteName team_drive= root_folder_id= shared_with_me=false --non-interactive *> $null

& $RcloneExe --config $RcloneConf about "${RemoteName}:" *> $null
if ($LASTEXITCODE -ne 0) { Write-Host "아직 접속되지 않습니다. 설치.cmd를 실행해 보세요." -ForegroundColor Red; exit 1 }
Write-Host "다시 연결됨. 마운트를 다시 겁니다." -ForegroundColor Green

if (Test-Path "$DriveLetter\") { & "$PSScriptRoot\Unmount-GDrive.ps1"; if ($LASTEXITCODE -ne 0) { exit 1 } }
& "$PSScriptRoot\Mount-GDrive.ps1"
exit $LASTEXITCODE
