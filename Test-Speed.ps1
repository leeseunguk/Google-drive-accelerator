# 파일 하나를 읽어 속도를 잽니다. 예: .\Test-Speed.ps1 "R:\data\big.bin"  "G:\내 드라이브\data\big.bin"
param([Parameter(Mandatory)][string[]]$Path)
foreach ($p in $Path) {
    $buf = New-Object byte[] (8MB); $total = 0
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $fs = [IO.File]::OpenRead($p)
    try { while (($n = $fs.Read($buf, 0, $buf.Length)) -gt 0) { $total += $n } } finally { $fs.Close() }
    $sw.Stop()
    $mbps = ($total / 1MB) / $sw.Elapsed.TotalSeconds
    "{0}`n  {1:N1} MB, {2:N1} 초, {3:N1} MB/s" -f $p, ($total / 1MB), $sw.Elapsed.TotalSeconds, $mbps
}
