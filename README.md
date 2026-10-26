# rclone-gdrive-mount

Google Drive를 rclone으로 드라이브 문자(기본 `R:`)에 마운트합니다.
Google Drive for desktop(G:)보다 빠르게 읽을 수 있도록 병렬 청크 읽기와 로컬 캐시를 켜 둔 구성입니다.

## 설치 (처음 한 번)
`설치.cmd`를 더블클릭하면 다음을 차례로 처리합니다. 이미 된 단계는 건너뛰므로 여러 번 실행해도 됩니다.
1. rclone이 없으면 winget으로 설치합니다(Rclone UI 내장본이나 PATH의 rclone이 있으면 그대로 씁니다).
2. WinFsp가 없으면 winget으로 설치합니다(관리자 확인 창에서 "예").
3. Google Drive remote(기본 `my_gdrive:`)가 없으면 만듭니다. 브라우저로 Google Cloud Console을 열어 주고, 화면 안내대로 만든 client ID와 보안 비밀을 붙여 넣으면 Google 로그인 창이 열립니다.
4. 로그인할 때 자동 마운트할지 묻습니다.

winget(Windows 10/11 기본 포함 "앱 설치 관리자")이 필요합니다.

### client ID를 직접 만들어야 하는 이유
- rclone의 공용 Google Drive client ID는 2026년 중 사용이 중단될 예정이라고 rclone 1.75가 경고합니다. 그래서 이 패키지는 내 client ID만 지원합니다.
- Google은 OAuth client를 프로그램으로 만드는 API를 제공하지 않습니다(유일했던 IAP OAuth Admin API는 2026-03-19에 종료). 그래서 Console에서 직접 만드는 단계만은 자동화할 수 없습니다.
- 동의 화면을 "테스트" 상태로 두면 로그인이 7일마다 만료됩니다. 반드시 "앱 게시"로 프로덕션 상태로 바꾸세요. 검증받지 않은 앱이라 로그인할 때 경고 화면이 나오는데, "고급 -> 이동"을 누르면 됩니다.

## 사용법
| 파일 | 하는 일 |
|---|---|
| `설치.cmd` | 의존성 설치와 Google Drive 연결(처음 한 번) |
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
