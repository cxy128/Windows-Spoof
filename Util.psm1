Import-Module ./Backup.ps1

$Alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
$HexBytes = "ABCDEF1234567890"

$ConsoleSystemInformation = @{}
$FileSystemInformation = @{}

function Get-RandomGuid {
    return [guid]::NewGuid().ToString();
}

function Get-RandomHex {
    $Random = Get-Random
    return $HexBytes[$Random % $HexBytes.Length]
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
    
    $SeparatorWidth = 50 - $KeyLength.ToCharArray().Length
    
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

    $TotalItems = $Entries.Count
    $CurrentIndex = 1
    $R = $true

    $Entries.GetEnumerator() | ForEach-Object {

        $Separator = Get-Separator $_.Key
        $Content = "$($_.Key)${Separator}$($_.Value)"

        if($IsWriteBackupFile) {

            $Content | Out-File -FilePath $BackupFilePathName -Append -Encoding utf8

            if ($($TotalItems -eq $CurrentIndex) -and $($R)) {
                "`n" | Out-File -FilePath $BackupFilePathName -Append -Encoding utf8
                $R = $false
            }

            $CurrentIndex++
        }

        $Content | Write-Host -ForegroundColor $Color     
    }
}

function Test-IsHexChar {

    param (
        [char]$HexChar
    )

    $Regex = "^[0-9a-fA-F]$"

    return $HexChar -match $Regex
}

function Reset-Type {

    param (
        [string] $Type
    )

    if ($Type -eq "System.String") {
        return "String"
    }

    if ($Type -eq "System.Int32") {
        return "DWord"
    }

    if ($Type -eq "System.Byte[]") {
        return "Binary"
    }

    if ($Type -eq "System.String[]"){
        return "MultiString"
    }

    return ""
}

Export-ModuleMember -Variable ConsoleSystemInformation, FileSystemInformation

Export-ModuleMember -Function Get-RandomGuid, Get-RandomHex, Get-SerialNumber, Get-RandomName, Get-Separator, Write-SystemInformation, Test-IsHexChar, Reset-Type












