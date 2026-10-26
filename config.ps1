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
$RcPort       = 5573                # 안전한 해제용 원격 제어 포트 (Rclone UI는 5572 사용)
