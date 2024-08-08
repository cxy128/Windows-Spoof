Import-Module ./Backup.ps1

$Alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

$ConsoleSystemInformation = @{}
$FileSystemInformation = @{}

function Get-RandomGuid(){
    return [guid]::NewGuid().ToString();
}

function Get-SerialNumber {

    param (
        [int]$SectionNumber = 5,
        [int]$ItemNumber = 5
    )

   $Value = ""
   1..$SectionNumber | ForEach-Object {
   
        $RandomNumber = [string]::Concat($(Get-Random))
        if($RandomNumber.Length -lt 5) {
            $RandomNumber = '00000'
        }
        
        $RandomNumber = $RandomNumber.SubString(0,$ItemNumber)
        if($_ -ne $SectionNumber) {
           $RandomNumber = -join($RandomNumber,'-')
        }
        
        $Value += $RandomNumber
   }
   
   return $Value
}

function Get-RandomName {

    param (
        [int]$NameLength = 10       
    )

    $DeviceName = ""
    1..$NameLength | ForEach-Object {
        $DeviceName += $Alphabet[$(0..$Alphabet.Length | Get-Random)]
    }
    
    return $DeviceName
}

function Get-Separator {

    param (
        [string]$KeyLength = ""
    )
    
    $SeparatorWidth = 30 - $KeyLength.ToString().Length
    
    return " " * $SeparatorWidth
}

function Write-SystemInformation {

    param (
        [System.Collections.Hashtable] $Entries,
        [string] $Color = "Green",
        [boolean] $IsWriteBackupFile = $false
    )
    
    if ($Entries.Count -eq 0) {
        return    
    }

    $Entries.GetEnumerator() | ForEach-Object {
        $Separator = Get-Separator $_.Key
        $Content = "$($_.Key)${Separator}$($_.Value)"
        if($IsWriteBackupFile) {
            $Content | Out-File -FilePath $BackupFilePathName -Append -Encoding unicode
        }
        $Content | Write-Host -ForegroundColor $Color     
    }
}

Export-ModuleMember -Variable ConsoleSystemInformation, FileSystemInformation -Function Get-RandomGuid, Get-SerialNumber, Get-RandomName, Get-Separator, Write-SystemInformation














