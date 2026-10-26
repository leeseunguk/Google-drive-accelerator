# 의존성(rclone, WinFsp)을 설치하고 Google Drive remote가 없으면 만들어 줍니다. 여러 번 실행해도 안전합니다.
. "$PSScriptRoot\config.ps1"
$RemoteName = ($Remote -split ":")[0]

function Step($m) { Write-Host "`n== $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "   $m" -ForegroundColor Green }

function Wait-Step($n, $title, $url, [string[]]$lines) {
    Write-Host "`n   [$n/6] $title" -ForegroundColor Yellow
    foreach ($l in $lines) { Write-Host "         $l" }
    if ($url) { Start-Process $url; Write-Host "         (브라우저에 해당 페이지를 열었습니다)" -ForegroundColor DarkGray }
    Read-Host "         다 했으면 Enter" | Out-Null
}

function New-ClientIdWizard {
    Write-Host @"
   내 Google client ID를 만듭니다(처음 한 번, 5분 정도).
   - 만드는 곳: Google Cloud Console  https://console.cloud.google.com/
     처음이면 로그인 후 약관에 동의하세요. 비용·결제 정보는 필요 없습니다.
   - 아무 Google 계정으로 만들어도 됩니다. 마운트할 Drive 계정과 달라도 됩니다.
   - 단계마다 필요한 페이지를 열어 드립니다. 화면에서 [굵은 버튼] 만 누르면 됩니다.
"@
    $started = Get-Date
    Wait-Step 1 "프로젝트 만들기" "https://console.cloud.google.com/projectcreate" @(
        "메뉴 위치: 화면 위쪽 프로젝트 선택 칸 -> [새 프로젝트]",
        "프로젝트 이름: rclone (아무거나) -> [만들기]",
        "만든 뒤 화면 위쪽 프로젝트 선택 칸에 그 프로젝트가 선택됐는지 확인")
    Wait-Step 2 "Google Drive API 켜기" "https://console.cloud.google.com/apis/library/drive.googleapis.com" @(
        "메뉴 위치: 왼쪽 위 메뉴 -> API 및 서비스 -> 라이브러리 -> 'Google Drive API' 검색",
        "[사용] 을 누릅니다 (이미 '관리' 버튼이 보이면 켜진 상태)")
    Wait-Step 3 "동의 화면 만들기" "https://console.cloud.google.com/auth/overview/create" @(
        "메뉴 위치: 왼쪽 위 메뉴 -> Google 인증 플랫폼 -> 개요 -> [시작하기]",
        "앱 이름: rclone, 사용자 지원 이메일: 내 이메일 -> [다음]",
        "대상: [외부] -> [다음] -> 연락처 이메일: 내 이메일 -> [다음]",
        "약관 동의 체크 -> [만들기]  (이미 만들어져 있으면 건너뛰기)")
    $scopes = "https://www.googleapis.com/auth/docs,https://www.googleapis.com/auth/drive,https://www.googleapis.com/auth/drive.metadata.readonly"
    Set-Clipboard -Value $scopes
    Wait-Step 4 "권한 범위 추가 (클립보드에 미리 복사해 두었습니다)" "https://console.cloud.google.com/auth/scopes" @(
        "메뉴 위치: 왼쪽 위 메뉴 -> Google 인증 플랫폼 -> 데이터 액세스",
        "[범위 추가 또는 삭제] -> 패널 아래쪽 '수동으로 범위 추가' 칸에 Ctrl+V",
        "[표에 추가] -> [업데이트] -> 페이지 맨 아래 [저장]")
    Wait-Step 5 "내 계정 추가하고 앱 게시" "https://console.cloud.google.com/auth/audience" @(
        "메뉴 위치: 왼쪽 위 메뉴 -> Google 인증 플랫폼 -> 대상",
        "테스트 사용자 [+ Add users] -> 내 이메일 -> [저장]",
        "[앱 게시] -> [확인]  ->  게시 상태가 '프로덕션 단계'로 바뀌면 성공",
        "(게시하지 않으면 로그인이 7일마다 만료됩니다)",
        "([앱 게시]가 회색이면 README의 '앱 게시 버튼이 회색일 때'를 보세요)")
    Wait-Step 6 "클라이언트 만들기" "https://console.cloud.google.com/auth/clients/create" @(
        "메뉴 위치: 왼쪽 위 메뉴 -> Google 인증 플랫폼 -> 클라이언트 -> [클라이언트 만들기]",
        "애플리케이션 유형: [데스크톱 앱] -> 이름은 그대로 -> [만들기]",
        "나오는 창에서 [JSON 다운로드] 를 누르면 자동으로 읽습니다")

    $j = Find-ClientJson $started
    if ($j) { return $j }
    Write-Host "`n   JSON 파일을 찾지 못했습니다. 창에 보이는 값을 복사해 붙여 넣으세요."
    return Read-ClientManual
}

# client_secret_*.json에서 ID/비밀을 읽습니다. 경로가 없으면 다운로드 폴더에서 가장 최근 파일을 찾습니다.
function Read-ClientJson($path) {
    try { $o = Get-Content $path -Raw -ErrorAction Stop | ConvertFrom-Json } catch { return $null }
    $j = if ($o.installed) { $o.installed } elseif ($o.web) { $o.web } else { $o }
    if ($j.client_id -and $j.client_secret) { return [pscustomobject]@{ client_id = $j.client_id; client_secret = $j.client_secret } }
    return $null
}
function Find-ClientJson($since) {
    $dl = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
    $files = Get-ChildItem $dl -Filter "client_secret_*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($since) { $files = $files | Where-Object { $_.LastWriteTime -ge $since.AddMinutes(-5) } }
    foreach ($f in $files) {
        $j = Read-ClientJson $f.FullName
        if ($j) { Write-Host "`n   다운로드 폴더의 파일에서 읽었습니다: $($f.Name)" -ForegroundColor Green; return $j }
    }
    return $null
}
function Read-ClientManual {
    $id  = (Read-Host "   클라이언트 ID").Trim()
    $sec = (Read-Host "   클라이언트 보안 비밀").Trim()
    if (-not $id -or -not $sec) { Write-Host "값이 비어 있습니다. 다시 실행하세요." -ForegroundColor Red; exit 1 }
    return [pscustomobject]@{ client_id = $id; client_secret = $sec }
}

# 이미 client ID가 있으면 그것을 쓰고, 없으면 마법사로 만듭니다.
function Get-ClientCredential {
    Write-Host @"
   Google client ID가 필요합니다. 이미 있나요?
   [1] 없음 - 지금 새로 만들기 (안내 마법사, 5분 정도)
   [2] 있음 - client_secret_....json 파일이 있음
   [3] 있음 - 클라이언트 ID와 보안 비밀을 직접 입력
   (다른 PC에서 이미 만들었다면 그 ID를 그대로 써도 됩니다)
"@
    switch ((Read-Host "   번호").Trim()) {
        "2" {
            $p = (Read-Host "   JSON 파일 경로 (창에 끌어다 놓아도 됨, 비우면 다운로드 폴더에서 찾기)").Trim().Trim('"')
            $j = if ($p) { Read-ClientJson $p } else { Find-ClientJson $null }
            if (-not $j) { Write-Host "   JSON에서 ID/비밀을 읽지 못했습니다. 직접 입력하세요." -ForegroundColor Yellow; $j = Read-ClientManual }
            return $j
        }
        "3" { return Read-ClientManual }
        default { return New-ClientIdWizard }
    }
}

# remote가 실제로 Drive에 접속되는지 확인합니다(토큰 없음/만료 감지).
function Test-Remote { & $RcloneExe --config $RcloneConf about "${RemoteName}:" *> $null; return ($LASTEXITCODE -eq 0) }
function Show-LoginHint {
    Write-Host @"

   브라우저에서 Google 로그인 창이 열립니다. 마운트할 Drive 계정으로 로그인하세요.
   'Google에서 확인하지 않은 앱' 경고가 나오면: [고급] -> [rclone(으)로 이동(안전하지 않음)] -> [계속]
   (내가 만든 앱이라 검증을 받지 않았을 뿐입니다. 개인용이면 검증이 필요 없습니다)
   브라우저에 'Success!'가 보일 때까지 이 창을 닫지 마세요.
   'Configure this as a Shared Drive (Team Drive)?' 질문이 나오면 n 을 누르세요(Enter도 n).
"@
}

# PATH가 깨진 PC 대비: 시스템 폴더와 winget 위치를 이번 실행의 PATH에 보탭니다.
$env:Path = (@("$env:SystemRoot\System32", "$env:SystemRoot", "$env:SystemRoot\System32\WindowsPowerShell\v1.0",
              "$env:LOCALAPPDATA\Microsoft\WindowsApps") + ($env:Path -split ";") | Where-Object { $_ } | Select-Object -Unique) -join ";"
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
if ($remotes -contains "${RemoteName}:") {
    if (Test-Remote) { Ok "이미 연결됨 ($RcloneConf)" }
    else {
        # remote는 있는데 로그인 토큰이 없거나 만료된 경우(로그인 중 창을 닫았거나, 테스트 상태 앱의 7일 만료 등)
        Write-Host "   remote는 있지만 Drive에 접속되지 않습니다(로그인 정보 없음 또는 만료). 다시 로그인합니다." -ForegroundColor Yellow
        Show-LoginHint
        & $RcloneExe --config $RcloneConf config reconnect "${RemoteName}:"
        & $RcloneExe --config $RcloneConf config update $RemoteName team_drive= root_folder_id= shared_with_me=false --non-interactive *> $null
        if (-not (Test-Remote)) { Write-Host "다시 로그인했지만 접속되지 않습니다. 설치.cmd를 다시 실행하세요." -ForegroundColor Red; exit 1 }
        Ok "다시 연결됨"
    }
}
else {
    # rclone 공용 client ID는 2026년 중 사용 중단 예정이라 내 client ID를 씁니다.
    # 만드는 절차는 rclone 공식 문서(https://rclone.org/drive/#making-your-own-client-id)를 따릅니다.
    $cred = Get-ClientCredential
    $kv = @("scope=drive", "client_id=$($cred.client_id)", "client_secret=$($cred.client_secret)", "team_drive=")
    Show-LoginHint
    New-Item -ItemType Directory -Force (Split-Path $RcloneConf) | Out-Null
    & $RcloneExe --config $RcloneConf config create $RemoteName drive @kv
    $remotes = & $RcloneExe --config $RcloneConf listremotes 2>$null
    if ($remotes -notcontains "${RemoteName}:") { Write-Host "remote 생성에 실패했습니다." -ForegroundColor Red; exit 1 }
    if (-not (Test-Remote)) { Write-Host "Drive 접속 확인에 실패했습니다. 설치.cmd를 다시 실행하면 로그인만 다시 합니다." -ForegroundColor Red; exit 1 }
    Ok "연결됨: $RcloneConf"
}

Step "4/4 자동 시작"
$ans = Read-Host "   로그인할 때 자동으로 마운트할까요? (y/N)"
if ($ans -match "^[yY]") { & "$PSScriptRoot\Install-Autostart.ps1" } else { Ok "건너뜀 (나중에 자동시작-등록.cmd로 설정 가능)" }

Write-Host "`n설치 완료. 마운트.cmd를 실행하면 $DriveLetter 로 연결됩니다." -ForegroundColor Green
