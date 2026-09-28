param([string] $ExpectedLocation = 'northcentralus', [string] $ExpectedTagsEffect = 'Deny')
$ErrorActionPreference = 'Stop'
function Get-AzureJson {
    param([string[]] $Arguments)
    $raw = & az @Arguments '-o' 'json' '--only-show-errors'
    if ($LASTEXITCODE -ne 0) { throw 'Consulta Azure falhou.' }
    return $raw | ConvertFrom-Json
}
function Assert-Condition {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

$tags = @{ Environment='Dev'; Owner='CloudTeam'; Project='AzureFoundation'; CostCenter='IT-Lab'; ManagedBy='Terraform' }
foreach ($kind in @('network','workload','operations')) {
    $group = Get-AzureJson -Arguments @('group','show','-n',"rg-$kind-dev-ncu-01")
    Assert-Condition ($group.location -eq $ExpectedLocation) "Região divergente no RG $kind"
    foreach ($key in $tags.Keys) {
        Assert-Condition ($group.tags.$key -eq $tags[$key]) "Tag $key divergente no RG $kind"
    }
    $assignments = @(Get-AzureJson -Arguments @('policy','assignment','list','--scope',$group.id))
    foreach ($policy in @('region','tags','vm-sku')) {
        $assignment = @($assignments | Where-Object { $_.name -eq "af-$policy" })
        Assert-Condition ($assignment.Count -eq 1) "Assignment $policy ausente ou duplicada em $kind"
        Assert-Condition ($assignment[0].enforcementMode -eq 'Default') "Assignment $policy sem enforcement"
    }
}

$vnet = Get-AzureJson -Arguments @('network','vnet','show','-g','rg-network-dev-ncu-01','-n','vnet-foundation-dev-ncu-01')
Assert-Condition ($vnet.location -eq $ExpectedLocation) 'Região da VNet divergente'
Assert-Condition ($vnet.addressSpace.addressPrefixes -contains '10.10.0.0/16') 'CIDR da VNet divergente'
Assert-Condition ($vnet.subnets.Count -eq 2) 'Quantidade de subnets divergente'
foreach ($subnet in $vnet.subnets) {
    Assert-Condition ($subnet.defaultOutboundAccess -eq $false) 'Saída implícita habilitada'
    Assert-Condition (-not [string]::IsNullOrEmpty($subnet.networkSecurityGroup.id)) 'Subnet sem NSG'
}
foreach ($kind in @('application','test')) {
    $nsg = Get-AzureJson -Arguments @('network','nsg','show','-g','rg-network-dev-ncu-01','-n',"nsg-$kind-dev-ncu-01")
    Assert-Condition ($nsg.location -eq $ExpectedLocation) 'Região do NSG divergente'
    Assert-Condition ($nsg.securityRules.Count -eq 6) 'Número inesperado de regras customizadas'
    Assert-Condition (@($nsg.securityRules | Where-Object { $_.name -eq 'deny-lateral-in' -and $_.access -eq 'Deny' -and $_.priority -eq 4000 }).Count -eq 1) 'Bloqueio lateral ausente'
    Assert-Condition (@($nsg.securityRules | Where-Object { $_.name -eq 'deny-other-out' -and $_.access -eq 'Deny' -and $_.priority -eq 4096 }).Count -eq 1) 'Bloqueio de saída ausente'
    Assert-Condition (@($nsg.securityRules | Where-Object { $_.direction -eq 'Inbound' -and $_.access -eq 'Allow' -and ($_.destinationPortRange -eq '3389' -or $_.destinationPortRanges -contains '3389') }).Count -eq 0) 'RDP aberto antes da Parte 4'
}
foreach ($item in @(@('region','Deny'),@('tags',$ExpectedTagsEffect),@('vm-sku','Deny'))) {
    $definition = Get-AzureJson -Arguments @('policy','definition','show','-n',"af-dev-$($item[0])")
    Assert-Condition ($definition.policyRule.then.effect -eq $item[1]) 'Efeito da policy divergente'
    if ($item[0] -eq 'region') {
        $regionRule = @($definition.policyRule.if.allOf | Where-Object { $_.field -eq 'location' })
        Assert-Condition ($regionRule.Count -eq 1 -and $regionRule[0].notIn -contains $ExpectedLocation) 'Policy não permite a região esperada'
    }
}
Write-Output 'PASS: RGs/tags, assignments, VNet/subnets privadas, NSGs e efeitos de Policy. Tráfego real depende das VMs das Partes 4/5.'
