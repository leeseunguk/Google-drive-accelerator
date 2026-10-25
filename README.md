# rclone-gdrive-mount

Google Drive를 rclone으로 드라이브 문자(기본 `R:`)에 마운트합니다.
Google Drive for desktop(G:)보다 빠르게 읽을 수 있도록 병렬 청크 읽기와 로컬 캐시를 켜 둔 구성입니다.

## 준비물
- rclone (Rclone UI가 설치한 `%LOCALAPPDATA%\com.rclone.ui\bin\rclone.exe`를 우선 사용하고, 없으면 PATH의 rclone을 씁니다)
- WinFsp: `winget install WinFsp.WinFsp` (설치에 관리자 권한 필요, 한 번만 설치)
- rclone에 Google Drive remote가 설정되어 있어야 합니다(기본 이름 `my_gdrive:`)

## 사용법
| 파일 | 하는 일 |
|---|---|
| `마운트.cmd` | 드라이브 문자로 마운트 |
| `해제.cmd` | 업로드 대기열이 비면 안전하게 해제 |
| `자동시작-등록.cmd` | 로그인할 때 자동 마운트(시작프로그램 바로가기, 관리자 권한 불필요) |
| `자동시작-해제.cmd` | 자동 시작 제거 |
| `Test-Speed.ps1` | 파일 읽기 속도 측정: `.\Test-Speed.ps1 R:\경로\파일 "G:\내 드라이브\경로\파일"` |

설정은 `config.ps1`에서 바꿉니다(remote 이름, 드라이브 문자, 캐시 위치·용량, 병렬 스트림 수).

## 동작 방식
- `--vfs-read-chunk-streams 8`: 파일 하나를 8개 스트림으로 동시에 읽습니다. 속도 향상의 핵심입니다.
- `--vfs-cache-mode full`: 읽은 데이터를 `D:\rclone-cache\gdrive`에 캐시합니다(기본 최대 100G, 7일).
- `--rc` (127.0.0.1:5573): `해제.cmd`가 업로드 대기열을 확인한 뒤 정상 종료할 때 씁니다.
- 로그: `D:\rclone-cache\gdrive\mount.log`

## 측정 결과 (2026-10-25, 처음 읽기 기준)
| 경로 | 파일 | 속도 |
|---|---|---|
| R: (이 패키지) | 760 MB zip | 47.6 MB/s |
| G: (Drive for desktop) | 679 MB zip | 16.1 MB/s |

100 MB 안팎의 작은 파일은 처음 연결하는 데 2~4초가 걸려 체감 차이가 작습니다. 한 번 읽은 파일은 캐시에서 바로 열립니다.

## 주의
- "symlinks not supported without the --links flag" 로그는 마운트할 때마다 나오는 정상 메시지입니다.
- 마운트 드라이브에 쓴 파일은 캐시에 먼저 저장된 뒤 백그라운드로 업로드됩니다. 업로드가 끝나기 전에 프로세스를 강제로 종료하면 반영이 늦어지거나 빠질 수 있으니 해제는 `해제.cmd`로 하세요.
- Google Docs/Sheets 문서는 docx/xlsx 같은 내보내기 형식으로 보입니다.
- WSL에서 쓰려면: `sudo mkdir -p /mnt/r && sudo mount -t drvfs R: /mnt/r`
