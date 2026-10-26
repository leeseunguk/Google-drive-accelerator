# 의존성(rclone, WinFsp)을 설치하고 Google Drive remote가 없으면 만들어 줍니다. 여러 번 실행해도 안전합니다.
. "$PSScriptRoot\config.ps1"
$RemoteName = ($Remote -split ":")[0]

function Step($m) { Write-Host "`n== $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "   $m" -ForegroundColor Green }

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget이 없습니다. Microsoft Store에서 '앱 설치 관리자'를 설치한 뒤 다시 실행하세요." -ForegroundColor Red
    exit 1
}

Step "1/4 rclone"
if ($RcloneExe) { Ok "이미 있음: $RcloneExe" }
else {
    winget install --id Rclone.Rclone -e --accept-source-agreements --accept-package-agreements
    $RcloneExe = Find-Rclone
    if (-not $RcloneExe) { Write-Host "rclone 설치를 확인하지 못했습니다." -ForegroundColor Red; exit 1 }
    Ok "설치됨: $RcloneExe"
}

Step "2/4 WinFsp (관리자 확인 창이 뜨면 '예'를 누르세요)"
$winfsp = "${env:ProgramFiles(x86)}\WinFsp\bin\winfsp-x64.dll"
if (Test-Path $winfsp) { Ok "이미 설치됨" }
else {
    winget install --id WinFsp.WinFsp -e --accept-source-agreements --accept-package-agreements
    if (-not (Test-Path $winfsp)) { Write-Host "WinFsp 설치를 확인하지 못했습니다." -ForegroundColor Red; exit 1 }
    Ok "설치됨"
}

Step "3/4 Google Drive 연결 ($RemoteName)"
$remotes = & $RcloneExe --config $RcloneConf listremotes 2>$null
if ($remotes -contains "${RemoteName}:") { Ok "이미 설정됨 ($RcloneConf)" }
else {
    # rclone 공용 client ID는 2026년 중 사용 중단 예정이라 내 client ID만 지원합니다.
    Write-Host @"
   내 Google client ID가 필요합니다(처음 한 번, 5분 정도).
   브라우저에서 Google Cloud Console을 엽니다. 아래 순서대로 진행하세요.
   1) 프로젝트를 하나 만들거나 고릅니다.
   2) 'Google Drive API'에서 [사용] 을 누릅니다.
   3) 'Google 인증 플랫폼'에서 시작하기 -> 앱 이름/이메일 입력 -> 대상: 외부 로 만듭니다.
   4) 대상(Audience) 화면에서 [앱 게시] 를 눌러 '프로덕션'으로 바꿉니다.
      (테스트 상태로 두면 로그인이 7일마다 만료됩니다)
   5) 클라이언트 -> [클라이언트 만들기] -> 유형 '데스크톱 앱' -> 만들기
   6) 표시되는 클라이언트 ID와 보안 비밀을 아래에 붙여 넣습니다.
"@
    Start-Process "https://console.cloud.google.com/apis/library/drive.googleapis.com"
    Start-Process "https://console.cloud.google.com/auth/overview"
    $id  = Read-Host "   클라이언트 ID"
    $sec = Read-Host "   클라이언트 보안 비밀"
    if (-not $id.Trim() -or -not $sec.Trim()) { Write-Host "값이 비어 있습니다. 다시 실행하세요." -ForegroundColor Red; exit 1 }
    $kv = @("scope=drive", "client_id=$($id.Trim())", "client_secret=$($sec.Trim())")
    Write-Host "`n   브라우저에서 Google 로그인 창이 열립니다. 로그인 후 [허용]을 누르세요."
    New-Item -ItemType Directory -Force (Split-Path $RcloneConf) | Out-Null
    & $RcloneExe --config $RcloneConf config create $RemoteName drive @kv
    $remotes = & $RcloneExe --config $RcloneConf listremotes 2>$null
    if ($remotes -notcontains "${RemoteName}:") { Write-Host "remote 생성에 실패했습니다." -ForegroundColor Red; exit 1 }
    & $RcloneExe --config $RcloneConf lsd "${RemoteName}:" --max-depth 1 | Select-Object -First 3
    if ($LASTEXITCODE -ne 0) { Write-Host "Drive 접속 확인에 실패했습니다. 로그인/허용 단계를 확인하고 다시 실행하세요." -ForegroundColor Red; exit 1 }
    Ok "연결됨: $RcloneConf"
}

Step "4/4 자동 시작"
$ans = Read-Host "   로그인할 때 자동으로 마운트할까요? (y/N)"
if ($ans -match "^[yY]") { & "$PSScriptRoot\Install-Autostart.ps1" } else { Ok "건너뜀 (나중에 자동시작-등록.cmd로 설정 가능)" }

Write-Host "`n설치 완료. 마운트.cmd를 실행하면 $DriveLetter 로 연결됩니다." -ForegroundColor Green
