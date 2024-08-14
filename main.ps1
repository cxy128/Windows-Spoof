Import-Module ./Util.psm1
Import-Module ./System.ps1
Import-Module ./Display.ps1
Import-Module ./MotherBoard.ps1
Import-Module ./Mac.ps1
Import-Module ./Disk.ps1

function Test {

    Set-SystemInformation
    Set-DisplayEDID
    Set-MotherBoard
    Set-MacAddress
    Set-DiskSerialNumber
    Set-DiskId
    Remove-VolumeGUID
    
    "`n`n" | Write-Host

    "修改前: `n" | Write-Host
    Write-SystemInformation $FileSystemInformation Green $true
    
    "`n`n" | Write-Host
    
    "修改后: `n" | Write-Host
    Write-SystemInformation $ConsoleSystemInformation Red $false

    Remove-Module Disk, Mac, MotherBoard, Display, System, Util, Backup -Force -Confirm:$false
}

Test












