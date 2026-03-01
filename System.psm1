Import-Module .\util.psm1

function Set-HardwareConfig {

    $basePath = "HKLM:\SYSTEM\HardwareConfig"

    $originLastConfig = (Get-ItemProperty -Path $basePath -Name LastConfig).LastConfig

    if (-not $originLastConfig) {
        throw "LastConfig not found."
    }

    $spoofLastConfig = [regex]::Replace(
        $originLastConfig,
        '[0-9A-Fa-f]',
        { param($m) Get-RandomHex }
    )

    $originPath = Join-Path $basePath $originLastConfig
    $spoofPath = Join-Path $basePath $spoofLastConfig

    Copy-Item -Path $originPath -Destination $spoofPath -Recurse -Force

    Set-ItemProperty -Path $basePath -Name LastConfig -Value $spoofLastConfig -Type String

    Remove-Item -Path $originPath -Recurse -Force

    $FileSystemInformation["HardwareConfig"] = $originLastConfig
    $ConsoleSystemInformation["HardwareConfig"] = $spoofLastConfig

    Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\mssmbios\Data" -Name "SMBiosData" -Force -ErrorAction SilentlyContinue
}

function Set-SystemInformation {

    Set-RegistryGuidValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\IDConfigDB\Hardware Profiles\0001' -Name 'HwProfileGuid' -WrapWithBraces:$true

    Set-RegistryGuidValue -Path 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name 'MachineGuid' -WrapWithBraces:$false

    Set-RegistryGuidValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate' -Name 'SusClientId' -WrapWithBraces:$false

    Set-RegistryGuidValue -Path 'HKLM:\SOFTWARE\Microsoft\SQMClient' -Name 'MachineId' -WrapWithBraces:$true
    
    Update-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'ProductId' -NewValueScript { (Get-SerialNumber 4 5).ToUpper() }

    Update-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'InstallDate' -NewValueScript { [int](Get-Date -UFormat %s) } -Type DWord

    Update-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'InstallTime' -NewValueScript { [long](Get-Date).ToFileTimeUtc() } -Type QWord

    Set-RegistryGuidValue -Path 'HKLM:\SYSTEM\ControlSet001\Services\IntelPMT\Parameters' -Name 'Intel-PMT' -WrapWithBraces:$true

    Set-ComputerName

    Set-HardwareConfig
}

Export-ModuleMember -Function Set-SystemInformation