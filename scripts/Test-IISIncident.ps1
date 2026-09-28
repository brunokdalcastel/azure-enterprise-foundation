$ErrorActionPreference = 'Stop'
function Get-LocalHttpStatus {
    try { return [int](Invoke-WebRequest 'http://localhost/index.html' -UseBasicParsing -TimeoutSec 10).StatusCode }
    catch { return 0 }
}
$before = Get-LocalHttpStatus
$during = -1
$after = -1
try {
    Stop-Service W3SVC -Force
    $during = Get-LocalHttpStatus
} finally {
    Start-Service W3SVC
    for ($i=0; $i -lt 6; $i++) {
        $after = Get-LocalHttpStatus
        if ($after -eq 200) { break }
        Start-Sleep 2
    }
}
$result = [ordered]@{httpBefore=$before;httpDuring=$during;httpAfter=$after;serviceRestored=((Get-Service W3SVC).Status -eq 'Running')}
$result | ConvertTo-Json -Compress
if ($before -ne 200 -or $during -eq 200 -or $after -ne 200 -or -not $result.serviceRestored) { throw 'Incidente IIS não validado' }
