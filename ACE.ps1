Import-Module .\Util.psm1

function Remove-AceItem {

    param (
        [string] $Path,
        [boolean] $IsPrint = $true,
        [string] $Color = "Green"
    )

    if(Test-Path -Path $Path) {

        Remove-Item -Path $Path -Force -Recurse

        if($IsPrint) {

            "Remove Directory $Path" | Write-Host -ForegroundColor $Color
        }
    }
}

function Clear-ACE {

    Remove-AceItem -Path "$ENV:SystemDrive\Windows\SysWOW64\config\systemprofile\AppData\Roaming\Tencent"

    Remove-AceItem -Path "$ENV:SystemDrive\Windows\SysWOW64\config\systemprofile\AppData\Roaming\AntiCheatExpert"

    Remove-AceItem -Path "$ENV:SystemDrive\ProgramData\AntiCheatExpert"

    
}