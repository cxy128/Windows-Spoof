$script:BackupFilePath = Join-Path $PSScriptRoot "Backup"
$script:BackupFilePathName = $null

function Initialize-BackupFile {

    if (-not (Test-Path $script:BackupFilePath)) {

        New-Item -ItemType Directory -Path $script:BackupFilePath -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"

    $fileName = "SystemInformation_bak_$timestamp.txt"

    $script:BackupFilePathName = Join-Path $script:BackupFilePath $fileName

    New-Item -ItemType File -Path $script:BackupFilePathName -Force | Out-Null
}

function Get-BackupFilePathName {

    if (-not $script:BackupFilePathName) {
        Initialize-BackupFile
    }

    return $script:BackupFilePathName
}

Export-ModuleMember -Function Initialize-BackupFile, Get-BackupFilePathName