Import-Module .\util.psm1

function Set-MacAddress {

    $classGuid = "{4d36e972-e325-11ce-bfc1-08002be10318}"
    $classPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\$classGuid"

    $adapter = Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -and $_.NetEnabled -and $_.Name -notmatch 'VMware|Virtual|Hyper-V' } |  Select-Object -First 1

    if (-not $adapter) {
        throw "No active physical adapter found."
    }

    if ($adapter.Name -match "Kernel Debug") {
        $ConsoleSystemInformation["MacAddress"] = "kernel debug mode nothing changed"
        return
    }

    $originMac = $adapter.MacAddress
    $adapterName = $adapter.NetConnectionID
    $adapterGuid = $adapter.GUID

    $bytes = New-Object byte[] 6
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
    $bytes[0] = ($bytes[0] -band 0xFE) -bor 0x02

    $spoofMacDash = ($bytes | ForEach-Object { $_.ToString("X2") }) -join '-'
    $spoofMacRaw = ($bytes | ForEach-Object { $_.ToString("X2") }) -join ''

    $success = $false

    try {

        Set-NetAdapter -Name $adapterName -MacAddress $spoofMacDash -Confirm:$false  -ErrorAction Stop

        $success = $true
        
    } catch {

        Write-Host "Set-NetAdapter failed. Trying registry method..."
    }

    if (-not $success) {

        $targetKey = Get-ChildItem $classPath | Where-Object {

            (Get-ItemProperty $_.PSPath -Name NetCfgInstanceId -ErrorAction SilentlyContinue).NetCfgInstanceId -eq $adapterGuid
        }

        if (-not $targetKey) {

            throw "Adapter registry key not found."
        }

        Set-ItemProperty -Path $targetKey.PSPath -Name "NetworkAddress" -Value $spoofMacRaw -Type String

        Disable-NetAdapter -Name $adapterName -Confirm:$false
        Start-Sleep -Seconds 2
        Enable-NetAdapter -Name $adapterName -Confirm:$false
    }

    $FileSystemInformation["MacAddress"] = $originMac

    $ConsoleSystemInformation["MacAddress"] = $spoofMacDash
}

Export-ModuleMember -Function Set-MacAddress