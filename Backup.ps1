$BackupFileName = "SystemInformation_bak.txt"
$BackupFilePath = $PSScriptRoot
$BackupFilePathName = $BackupFilePath + "\" + $BackupFileName  

if (-not (Test-Path -Path $BackupFilePathName -PathType leaf)){
    New-Item -Type File -Path $BackupFilePath -Name $BackupFileName -Force    
}

# $DesktopPath = [System.Environment]::GetFolderPath('Desktop')
