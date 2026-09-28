$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot
try {
    $raw = terraform '-chdir=bootstrap' output '-json' backend_config
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao obter configuração do bootstrap.' }
    $config = $raw | ConvertFrom-Json
    $lines = foreach ($property in $config.PSObject.Properties) {
        # JSON strings/bools são literais válidos neste arquivo HCL simples.
        '{0} = {1}' -f $property.Name, (ConvertTo-Json -InputObject $property.Value -Compress)
    }
    $lines | Set-Content -LiteralPath 'foundation/backend.local.hcl' -Encoding utf8
    terraform '-chdir=foundation' init '-input=false' '-backend-config=backend.local.hcl'
    if ($LASTEXITCODE -ne 0) { throw 'Backend não inicializado. Verifique RBAC, IP permitido e sessão Azure CLI.' }
} finally {
    Pop-Location
}
