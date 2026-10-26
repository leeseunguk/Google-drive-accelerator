# rclone-gdrive-mount 설정 파일. 필요한 값만 바꿔서 쓰세요.

# rclone 실행 파일: Rclone UI 내장본 -> PATH -> winget 설치본 순서로 찾습니다(없으면 $null, 설치.cmd가 설치).
function Find-Rclone {
    $c = @("$env:LOCALAPPDATA\com.rclone.ui\bin\rclone.exe")
    $cmd = Get-Command rclone -ErrorAction SilentlyContinue
    if ($cmd) { $c += $cmd.Source }
    $c += "$env:LOCALAPPDATA\Microsoft\WinGet\Links\rclone.exe"
    $c += Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Rclone.Rclone*\*\rclone.exe" -ErrorAction SilentlyContinue | ForEach-Object FullName
    foreach ($p in $c) { if ($p -and (Test-Path $p)) { return $p } }
    return $null
}
$RcloneExe = Find-Rclone

# rclone 설정 파일: Rclone UI 설정이 있으면 그것을, 없으면 rclone 기본 위치를 씁니다.
$RcloneConf = "$env:LOCALAPPDATA\com.rclone.ui\configs\default\rclone.conf"
if (-not (Test-Path $RcloneConf)) { $RcloneConf = "$env:APPDATA\rclone\rclone.conf" }

$Remote       = "my_gdrive:"        # 마운트할 remote (하위 폴더 지정 가능: "my_gdrive:data")
$DriveLetter  = "R:"                # 사용할 드라이브 문자 (G:는 Drive for desktop이 사용 중)
$CacheDir     = "D:\rclone-cache\gdrive"
$CacheMaxSize = "100G"              # 로컬 캐시 최대 용량
$CacheMaxAge  = "168h"              # 캐시 보관 기간
$ChunkStreams = 8                   # 파일 하나를 동시에 읽는 스트림 수 (속도 핵심)
$ChunkSize    = "64M"
$NetworkDrive = $false             # $true면 탐색기에 '네트워크 위치(공유 폴더)'로, $false면 일반 디스크로 표시
$VolumeName   = "Google Drive (rclone)"   # 탐색기에 보일 드라이브 이름
$RcPort       = 5573                # 안전한 해제용 원격 제어 포트 (Rclone UI는 5572 사용)

# 지금 연결된 Google 계정과 remote 설정, 최상위 폴더를 보여 줍니다.
function Show-RemoteInfo($RcloneExe, $RcloneConf, $RemoteName) {
    & $RcloneExe --config $RcloneConf about "${RemoteName}:" *> $null   # 토큰 갱신
    $cfg = (& $RcloneExe --config $RcloneConf config dump 2>$null | Out-String | ConvertFrom-Json).$RemoteName
    if (-not $cfg) { Write-Host "   remote '$RemoteName' 이(가) 없습니다." -ForegroundColor Red; return }
    $email = "(확인 실패)"
    try {
        $tok = ($cfg.token | ConvertFrom-Json).access_token
        $u = Invoke-RestMethod -Headers @{ Authorization = "Bearer $tok" } "https://www.googleapis.com/drive/v3/about?fields=user(emailAddress)"
        $email = $u.user.emailAddress
    } catch {}
    $scope = if ($cfg.scope) { $cfg.scope } else { "drive (기본값)" }
    Write-Host "   로그인 계정   : $email"
    Write-Host "   권한 범위     : $scope"
    Write-Host "   공유 드라이브 : $(if ($cfg.team_drive) { $cfg.team_drive } else { '없음 (내 드라이브)' })"
    Write-Host "   시작 폴더 ID  : $(if ($cfg.root_folder_id) { $cfg.root_folder_id } else { '없음 (최상위)' })"
    Write-Host "   공유 문서함만 : $(if ($cfg.shared_with_me -eq 'true') { '예' } else { '아니요' })"
    $top = & $RcloneExe --config $RcloneConf lsf "${RemoteName}:" --max-depth 1 2>$null
    Write-Host "   최상위 항목   : $(@($top).Count)개  (예: $((@($top) | Select-Object -First 5) -join ', '))"
}
