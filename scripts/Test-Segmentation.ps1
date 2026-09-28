$ErrorActionPreference = 'Stop'
function Test-TcpPort([string]$Address, [int]$Port) {
    $client = [Net.Sockets.TcpClient]::new()
    try {
        $task = $client.ConnectAsync($Address, $Port)
        if (-not $task.Wait(5000)) { return $false }
        return $client.Connected
    } catch { return $false } finally { $client.Dispose() }
}
$page = Invoke-WebRequest 'http://10.10.20.10/index.html' -UseBasicParsing -TimeoutSec 20
$result = [ordered]@{
    privateHttp200 = ($page.StatusCode -eq 200)
    expectedPage = ($page.Content -match 'Contoso Brasil')
    lateralRdpBlocked = (-not (Test-TcpPort '10.10.20.10' 3389))
    lateralSmbBlocked = (-not (Test-TcpPort '10.10.20.10' 445))
}
$result | ConvertTo-Json -Compress
if ($result.Values -contains $false) { throw 'Falha na segmentação; revisar evidências.' }
