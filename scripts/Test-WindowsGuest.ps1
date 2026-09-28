$ErrorActionPreference = 'Stop'
$web = Invoke-WebRequest -Uri 'http://localhost/index.html' -UseBasicParsing
$rdpRule = Get-NetFirewallRule -Name 'Lab-Admin-RDP'
$httpRule = Get-NetFirewallRule -Name 'Lab-IIS-HTTP'
$httpFilter = $httpRule | Get-NetFirewallAddressFilter
$nla = (Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp').UserAuthentication
$https = Test-NetConnection -ComputerName 'login.microsoftonline.com' -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue
$license = @(Get-CimInstance SoftwareLicensingProduct | Where-Object { $_.PartialProductKey -and $_.Name -like 'Windows*' } | Select-Object -ExpandProperty LicenseStatus)
$result = [ordered]@{
  iisRunning = ((Get-Service W3SVC).Status -eq 'Running')
  localHttp200 = ($web.StatusCode -eq 200)
  expectedPage = ($web.Content -match 'Contoso Brasil')
  httpRestrictedToTestVm = (@($httpFilter.RemoteAddress).Count -eq 1 -and $httpFilter.RemoteAddress -contains '10.10.40.10')
  rdpRuleEnabled = ($rdpRule.Enabled -eq 'True')
  nlaEnabled = ($nla -eq 1)
  httpsOutbound = [bool]$https
  windowsLicenseStatus = $license
}
$result | ConvertTo-Json -Compress
if (-not ($result.iisRunning -and $result.localHttp200 -and $result.expectedPage -and $result.httpRestrictedToTestVm -and $result.rdpRuleEnabled -and $result.nlaEnabled -and $result.httpsOutbound)) {
  throw 'Uma ou mais verificações de guest falharam.'
}
