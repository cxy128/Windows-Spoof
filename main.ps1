Import-Module ./Util.psm1
Import-Module ./System.ps1
Import-Module ./Display.ps1
Import-Module ./MotherBoard.ps1
Import-Module ./Mac.ps1

function Test {

    Set-SystemInformation
    Set-DisplayEDID
    Set-MotherBoard
    Set-MacAddress
    
    "`n`n" | Write-Host

    "修改前: `n" | Write-Host
    Write-SystemInformation $FileSystemInformation Green $true
    
    "`n`n" | Write-Host
    
    "修改后: `n" | Write-Host
    Write-SystemInformation $ConsoleSystemInformation Red $false
}

Test












