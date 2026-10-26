# 로그인 정보가 없거나 만료됐을 때(empty token, invalid_grant) Google 로그인만 다시 합니다.
. "$PSScriptRoot\config.ps1"
$RemoteName = ($Remote -split ":")[0]
Write-Host @"
브라우저에서 Google 로그인 창이 열립니다. 마운트할 Drive 계정으로 로그인하고 [허용]을 누르세요.
'Google에서 확인하지 않은 앱' 경고가 나오면: [고급] -> [rclone(으)로 이동(안전하지 않음)] -> [계속]
영어 질문이 나오면 Enter(기본값)를 누르면 됩니다.
"@
& $RcloneExe --config $RcloneConf config reconnect "${RemoteName}:"
& $RcloneExe --config $RcloneConf about "${RemoteName}:" *> $null
if ($LASTEXITCODE -eq 0) { Write-Host "다시 연결됨. 마운트.cmd를 실행하세요." -ForegroundColor Green }
else { Write-Host "아직 접속되지 않습니다. 설치.cmd를 실행해 보세요." -ForegroundColor Red; exit 1 }
