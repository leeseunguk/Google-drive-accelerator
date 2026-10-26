# 내 드라이브가 안 보일 때 원인을 확인합니다. 출력 내용을 그대로 알려 주세요.
. "$PSScriptRoot\config.ps1"
$RemoteName = ($Remote -split ":")[0]
Write-Host "rclone   : $RcloneExe"
Write-Host "설정 파일: $RcloneConf"
Write-Host "remote   : $Remote  ->  드라이브 $DriveLetter`n"
Show-RemoteInfo $RcloneExe $RcloneConf $RemoteName
Write-Host @"

확인 방법
 - '로그인 계정'이 내 드라이브가 있는 계정이 아니면: 재연결.cmd 실행 후 올바른 계정으로 로그인
 - '권한 범위'가 drive.file / drive.appfolder 등이면: 재연결.cmd (drive로 바로잡고 다시 로그인)
 - 공유 드라이브/시작 폴더/공유 문서함 값이 있으면: 재연결.cmd (자동으로 비움)
 - 위가 모두 정상인데 최상위 항목이 웹(drive.google.com)의 '내 드라이브'와 다르면 이 출력을 알려 주세요.
"@
