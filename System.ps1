Import-Module ./Util.psm1

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
}

