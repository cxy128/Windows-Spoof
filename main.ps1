Import-Module .\util.psm1
Import-Module .\System.psm1
Import-Module .\Display.psm1
Import-Module .\Mac.psm1
Import-Module .\Clear.psm1

function Show-Result {

    Write-Output ""
    Write-Output "========== 修改前 =========="
    Write-SystemInformation -Entries:$FileSystemInformation -WriteBackup:$true

    Write-Output ""
    Write-Output "========== 修改后 =========="
    Write-SystemInformation -Entries:$ConsoleSystemInformation
}

function Get-YesNo {
    param (
        [string]$Message
    )

    while ($true) {
        $in = Read-Host "$Message (Y/N)"
        switch ($in.ToUpper()) {
            "Y" { return $true }
            "N" { return $false }
            default { Write-Host "请输入 Y 或 N" -ForegroundColor Yellow }
        }
    }
}

function Invoke-Main {

    if (-not (Test-IsAdministrator)) {
        throw "Please run PowerShell as Administrator."
    }

    $clearACE = Get-YesNo "是否执行 AntiCheatExpert 清理?"

    try {

        Set-SystemInformation
        Set-DisplayInformation
        Set-MacAddress

        if ($clearACE) {
            Clear-AntiCheatExpert
            Clear-Traces
        }

        Show-Result
        
    } catch {

        Write-Host "发生错误: $($_.Exception.Message)" -ForegroundColor Red

    } finally {

        Get-Module System, Display, Mac, Clear, util, backup -ErrorAction SilentlyContinue | Remove-Module -Force -Confirm:$false
    }
}

Invoke-Main