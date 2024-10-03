Import-Module ./Util.psm1

function Set-DevQeuryId {

    $DevQueryPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\DevQuery\6'

    if (-not (Test-Path -Path $DevQueryPath)) {
        return
    }
    
    $DevQuery = Get-ItemProperty -Path $DevQueryPath

    $OriginDevQueryId = if ($DevQuery -and $DevQuery.UUID) {

        $DevQuery.UUID

    } else {

        'null'
    }

    $FileSystemInformation.Add("DevQueryId", $OriginDevQueryId)

    $SpoofDevQueryId = [System.Guid]::NewGuid().Guid

    Set-ItemProperty -Path $DevQueryPath -Name 'UUID' -Value $SpoofDevQueryId -Type String -Force

    $ConsoleSystemInformation.Add("DevQueryId", $SpoofDevQueryId)
}

function Set-IDConfigDB {

    $Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\IDConfigDB\Hardware Profiles\0001'

    if (-not (Test-Path -Path $Path)) {
        return
    }
    
    $HwProfileGuid = Get-ItemProperty -Path $Path

    $OriginHwProfileGuid = if ($HwProfileGuid -and $HwProfileGuid.HwProfileGuid) {

        $OriginHwProfileGuid.HwProfileGuid -replace '{' -replace '}'

    } else {

        'null'
    }

    $FileSystemInformation.Add("HwProfileGuid", $OriginHwProfileGuid)

    $SpoofHwProfileGuid = [System.Guid]::NewGuid().Guid

    Set-ItemProperty -Path $Path -Name 'HwProfileGuid' -Value "{$SpoofHwProfileGuid}" -Type String -Force

    $ConsoleSystemInformation.Add("HwProfileGuid", $SpoofHwProfileGuid)
}

function Set-CryptographyId {

    $Path = 'HKLM:\SOFTWARE\Microsoft\Cryptography'

    if (-not (Test-Path -Path $Path)) {
        return
    }
    
    $MachineGuid = Get-ItemProperty -Path $Path

    $OriginMachineGuid = if ($MachineGuid -and $MachineGuid.MachineGuid) {

        $MachineGuid.MachineGuid

    } else {

        'null'
    }

    $FileSystemInformation.Add("MachineGuid", $OriginMachineGuid)

    $SpoofMachineGuid = [System.Guid]::NewGuid().Guid

    Set-ItemProperty -Path $Path -Name 'MachineGuid' -Value $SpoofMachineGuid -Type String -Force

    $ConsoleSystemInformation.Add("MachineGuid", $SpoofMachineGuid)
}

function Set-WindowUpdateId {

    $Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate'

    if (-not (Test-Path -Path $Path)) {
        return
    }
    
    $SusClientId = Get-ItemProperty -Path $Path

    $OriginSusClientId = if ($SusClientId -and $SusClientId.SusClientId) {

        $SusClientId.SusClientId

    } else {

        'null'
    }

    $FileSystemInformation.Add("SusClientId", $OriginSusClientId)

    $SpoofSusClientId = [System.Guid]::NewGuid().Guid

    Set-ItemProperty -Path $Path -Name 'SusClientId' -Value $SpoofSusClientId -Type String -Force

    $ConsoleSystemInformation.Add("SusClientId", $SpoofSusClientId)
}

function Set-SystemInformation {

    #   设备ID
    $OriginMachineId = $(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\SQMClient" | Select-Object -Property "MachineId").MachineId
    $FileSystemInformation.Add("MachineId", $OriginMachineId)

    $SpoofMachineId = "{$($(Get-RandomGuid).ToUpper())}"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\SQMClient" -Name "MachineId" -Type "string" -Value $SpoofMachineId -Force
    $ConsoleSystemInformation.Add("MachineId", $SpoofMachineId)
    
    #   产品ID
    $OriginProductId = $(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" | Select-Object -Property "ProductId").ProductId
    $FileSystemInformation.Add("ProductId", $OriginProductId)
    
    $SpoofProductId = $(Get-SerialNumber 4 5).ToUpper()
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "ProductId" -Type "string" -Value $SpoofProductId -Force
    $ConsoleSystemInformation.Add("ProductId", $SpoofProductId)
    
    #   设备名称    DESKTOP-XXX
    $OriginComputerName = $(Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" | Select-Object -Property ComputerName).ComputerName
    $FileSystemInformation.Add("ComputerName", $OriginComputerName)
    
    $SpoofComputerName = Get-RandomName 15
    Rename-Computer -NewName $SpoofComputerName -Force *>$null
    $ConsoleSystemInformation.Add("ComputerName", $SpoofComputerName)

    #   安装日期
    $OriginInstallDate = $(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' | Select-Object -Property InstallDate).InstallDate
    $FileSystemInformation.Add("InstallDate", $OriginInstallDate)
    
    $OriginInstallTime = $(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' | Select-Object -Property InstallTime).InstallTime
    $FileSystemInformation.Add("InstallTime", $OriginInstallTime)
    
    $DateTime = [math]::Floor($(Get-Date).ToFileTimeUtc())
    
    $SpoofInstallDate = [int]$(($DateTime - 116444736000000000) / 10000000)
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'InstallDate' -Value $SpoofInstallDate -Type DWord -Force
    $ConsoleSystemInformation.Add("InstallDate", $SpoofInstallDate)
    
    $SpoofInstallTime = [long]$($DateTime / 100000000 * 100000000)
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'InstallTime' -Value $SpoofInstallTime -Type QWord -Force
    $ConsoleSystemInformation.Add("InstallTime", $SpoofInstallTime)

    #  更新服务客户端标识符
    $OriginSusClientId = $(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate' | Select-Object -Property SusClientId).SusClientId
    $FileSystemInformation.Add("SusClientId", $OriginSusClientId)

    $SpoofSusClientId = ([System.Guid]::NewGuid()).Guid
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate' -Name 'SusClientId' -Value $SpoofSusClientId -Type String -Force
    $ConsoleSystemInformation.Add("SusClientId", $SpoofSusClientId)

    # 
    Set-IDConfigDB
    Set-CryptographyId
    Set-WindowUpdateId

}

