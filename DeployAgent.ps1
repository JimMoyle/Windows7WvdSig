<#
.SYNOPSIS
Deploys RD Infra agent into target VM

.DESCRIPTION
This script will get the registration token for the target pool name, copy the installer into target VM and execute the installer with the registration token and broker URI

If the pool name is not specified it will retreive first one (treat this as random) from the deployment.

.PARAMETER ComputerName
Required the FQDN or IP of target VM

.PARAMETER AgentInstallerFolder
Required path to MSI installer file

.PARAMETER AgentBootServiceInstallerFolder
Required path to MSI installer file

.PARAMETER Session
Optional Powershell session into target VM

.PARAMETER StartAgent
Start the agent service (RdInfraAgent) immediately

.EXAMPLE

.\DeployAgent.ps1 -AgentInstallerFolder '.\RDInfraAgentInstall\' -AgentBootServiceInstallerFolder '.\RDAgentBootLoaderInstall\'"
#>
#Requires -Version 4.0

Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AgentInstallerFolder,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AgentBootServiceInstallerFolder,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$RegistrationToken,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [bool]$StartAgent
)

function Test-IsAdmin {
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Convert relative paths to absolute paths if needed
Write-Log -Message "Boot loader folder is $AgentBootServiceInstallerFolder"
$AgentBootServiceInstaller = (Get-ChildItem $AgentBootServiceInstallerFolder\ -Filter *.msi | Select-Object).FullName
if ((-not $AgentBootServiceInstaller) -or (-not (Test-Path $AgentBootServiceInstaller))) {
    throw "RD Infra Agent Installer package is not found '$AgentBootServiceInstaller'"
}

# Convert relative paths to absolute paths if needed
Write-Log -Message "Agent folder is $AgentInstallerFolder"
$AgentInstaller = (Get-ChildItem $AgentInstallerFolder\ -Filter *.msi | Select-Object).FullName
if ((-not $AgentInstaller) -or (-not (Test-Path $AgentInstaller))) {
    throw "RD Infra Agent Installer package is not found '$AgentInstaller'"
}

if (!$RegistrationToken) {
    throw "No registration token specified"
}

#install the package
Write-Log -Message "Installing RDAgent BootLoader on VM $AgentBootServiceInstaller"

$bootloader_deploy_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $AgentBootServiceInstaller", "/quiet", "/qn", "/norestart", "/passive", "/l* C:\Windows\Temp\AgentBootLoaderInstall.log" -Wait -Passthru
$sts = $bootloader_deploy_status.ExitCode
Write-Log -Message "Installing RDAgentBootLoader on VM Complete. Exit code = $sts"

#install the package
Write-Log -Message "Installing RD Infra Agent on VM $AgentInstaller"

$agent_deploy_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $AgentInstaller", "/quiet", "/qn", "/norestart", "/passive", "REGISTRATIONTOKEN=$RegistrationToken", "/l* C:\Windows\Temp\AgentInstall.log" -Wait -Passthru
$sts = $agent_deploy_status.ExitCode
Write-Log -Message "Installing RD Infra Agent on VM Complete. Exit code = $sts"

if ($StartAgent) {
    $svcName = 'RDAgent'
    Write-Log -Message "Starting service $svcName"
    Start-Service $svcName
}
