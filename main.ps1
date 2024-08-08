Import-Module ./Util.psm1
Import-Module ./System.ps1
Import-Module ./Display.ps1
Import-Module ./MotherBoard.ps1

function Test {

    Set-SystemInformation
    Set-DisplayEDID
    Set-MotherBoard
    
    "`n`n" | Write-Host

    "修改前: `n" | Write-Host
    Write-SystemInformation $FileSystemInformation Green $true
    
    "`n`n" | Write-Host
    
    "修改后: `n" | Write-Host
    Write-SystemInformation $ConsoleSystemInformation Red $false
}

Test

Remove-Module -Name "Backups" *>$null
Remove-Module -Name "Util" *>$null
Remove-Module -Name "System" *>$null
Remove-Module -Name "Display" *>$null
Remove-Module -Name "MotherBoard" *>$null













