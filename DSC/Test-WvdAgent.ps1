function Test-WvdAgent {

    $Win7Bootloader = Test-Path
    $Win7Agent = Test-Path

    $Bootloader = Test-Path "HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader"
    $Agent = Test-Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent"

    if ($Win7Bootloader -and $Win7Agent -or
        $Bootloader -and $Agent) {
        Write-Output $true
        return
    }
    else {
        Write-Output $false
        return
    }
}  #function Test-WvdAgent