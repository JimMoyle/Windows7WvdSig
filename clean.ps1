$r = Get-AzResource | Where-Object { $_.ResourceGroupName -eq 'TestMandS' }

$r | Where-object { $_.ResourceType -eq 'Microsoft.Compute/virtualMachines' } | Remove-AzResource -Force -Confirm:$false

Get-AzResource | Where-Object { $_.ResourceGroupName -eq 'TestMandS' } | Remove-AzResource -Force -Confirm:$false

$hostPoolName = "Windows7"

Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"

Get-RdsAppGroup -TenantName JMoyle -HostPoolName $hostPoolName | Remove-RdsAppGroup

Get-RdsSessionHost -TenantName JMoyle -HostPoolName $hostPoolName | Where-Object { $_.SessionHostName -like "*.jimmoyle.net" } | Remove-RdsSessionHost

Get-RdsHostPool -TenantName JMoyle | Where-Object { $_.HostPoolName -eq $hostPoolName } | Remove-RdsHostPool