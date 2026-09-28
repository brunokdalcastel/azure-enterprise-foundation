# Um worker por até seis minutos, duty cycle de aproximadamente 50% de um core.
# VM tem dois vCPUs: carga pretendida ~25% do total, sem escrever no disco.
$ErrorActionPreference = 'Stop'
$deadline = [DateTime]::UtcNow.AddMinutes(6)
while ([DateTime]::UtcNow -lt $deadline) {
    $cycle = [Diagnostics.Stopwatch]::StartNew()
    while ($cycle.ElapsedMilliseconds -lt 500) { $null = [Math]::Sqrt(1234567.89) }
    Start-Sleep -Milliseconds 500
}
Write-Output 'PASS: carga limitada concluída; nenhum processo persistente criado.'
