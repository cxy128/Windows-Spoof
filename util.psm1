Import-Module "$PSScriptRoot\Backup.psm1"

$script:Alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
$script:HexBytes = "ABCDEF1234567890"

$script:ConsoleSystemInformation = @{}
$script:FileSystemInformation = @{}

$script:HexRegex = [regex]"^[0-9a-fA-F]$"

function Get-RandomGuid {

    return [guid]::NewGuid().ToString()
}

function Get-RandomHex {

    return $script:HexBytes[(Get-Random -Minimum 0 -Maximum $script:HexBytes.Length)]
}

function Get-SerialNumber {

    param (
        [ValidateRange(1, 20)]
        [int]$SectionNumber = 5,

        [ValidateRange(1, 20)]
        [int]$ItemNumber = 5
    )

    $sections = foreach ($i in 1..$SectionNumber) {
        -join (1..$ItemNumber | ForEach-Object {
                Get-Random -Minimum 0 -Maximum 10
            })
    }

    return $sections -join "-"
}

function Get-RandomName {

    param (
        [ValidateRange(1, 100)]
        [int]$NameLength = 10       
    )

    $builder = New-Object System.Text.StringBuilder

    for ($i = 0; $i -lt $NameLength; $i++) {
        $index = Get-Random -Minimum 0 -Maximum $script:Alphabet.Length
        [void]$builder.Append($script:Alphabet[$index])
    }

    return $builder.ToString()
}

function Get-Separator {

    param (
        [Parameter(Mandatory)]
        [string]$Key
    )

    $width = 50 - $Key.Length
    if ($width -lt 1) { $width = 1 }

    return " " * $width
}

function Write-SystemInformation {

    param (
        [Parameter(Mandatory)]
        [hashtable]$Entries,

        [ValidateSet("Green", "Yellow", "Red", "Cyan", "White")]
        [string]$Color = "Green",

        [switch]$WriteBackup
    )
    
    if ($Entries.Count -eq 0) {
        return    
    }

    $buffer = New-Object System.Collections.Generic.List[string]

    foreach ($entry in $Entries.GetEnumerator()) {

        $separator = Get-Separator -Key $entry.Key
        $content = "{0}{1}{2}" -f $entry.Key, $separator, $entry.Value

        $buffer.Add($content)

        Write-Host $content -ForegroundColor $Color
    }

    if ($WriteBackup) {
        Initialize-BackupFile
        $path = Get-BackupFilePathName
        Add-Content -Path $path -Value $buffer
        Add-Content -Path $path -Value ""
    }
}

function Test-IsHexChar {

    param (
        [Parameter(Mandatory)]
        [char]$HexChar
    )

    return $script:HexRegex.IsMatch($HexChar)
}

function Reset-Type {

    param (
        [Parameter(Mandatory)]
        [string]$Type
    )

    switch ($Type) {
        "System.String" { return "String" }
        "System.Int32" { return "DWord" }
        "System.Byte[]" { return "Binary" }
        "System.String[]" { return "MultiString" }
        default { return "" }
    }
}

function Set-RegistryGuidValue {

    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name,

        [switch]$WrapWithBraces
    )

    if (-not (Test-Path $Path)) {
        return
    }

    try {

        $item = Get-ItemProperty -Path $Path -ErrorAction Stop

        $originValue = if ($item.$Name) {
            $item.$Name
        }
        else {
            'null'
        }

        $script:FileSystemInformation[$Name] = $originValue

        $newGuid = [guid]::NewGuid().Guid

        if ($WrapWithBraces) {
            $newGuid = "{$newGuid}"
        }

        Set-ItemProperty -Path $Path -Name $Name -Value $newGuid -Type String -Force -ErrorAction Stop

        $script:ConsoleSystemInformation[$Name] = $newGuid
    }

    catch {
        Write-Warning "Failed to update $Name at $Path : $_"
    }
}

function Update-RegistryValue {

    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$NewValueScript,

        [string]$Type = "String"
    )

    if (-not (Test-Path $Path)) {
        Write-Warning "Registry path not found: $Path"
        return
    }

    try {

        $item = Get-ItemProperty -Path $Path -ErrorAction Stop
        $origin = $item.$Name

        if (-not $origin) {
            $origin = "null"
        }

        $script:FileSystemInformation[$Name] = $origin

        $newValue = & $NewValueScript

        Set-ItemProperty `
            -Path $Path `
            -Name $Name `
            -Value $newValue `
            -Type $Type `
            -Force `
            -ErrorAction Stop

        $script:ConsoleSystemInformation[$Name] = $newValue
    }

    catch {
        Write-Warning "Failed updating $Name : $_"
    }
}

function Test-IsAdministrator {

    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)

    return $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Set-ComputerName {

    try {

        $origin = $(Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" | Select-Object -Property ComputerName).ComputerName
        $script:FileSystemInformation["ComputerName"] = $origin

        $newName = Get-RandomName 15

        Rename-Computer -NewName $newName -Force -ErrorAction Stop -WarningAction SilentlyContinue

        $script:ConsoleSystemInformation["ComputerName"] = $newName

    } catch {

        Write-Warning $_
    }
}

Export-ModuleMember -Variable ConsoleSystemInformation, FileSystemInformation

Export-ModuleMember -Function Get-RandomGuid, Get-RandomHex, Get-SerialNumber, Get-RandomName, Get-Separator

Export-ModuleMember -Function Write-SystemInformation

Export-ModuleMember -Function Test-IsHexChar, Test-IsAdministrator

Export-ModuleMember -Function Reset-Type

Export-ModuleMember -Function Set-RegistryGuidValue

Export-ModuleMember -Function Update-RegistryValue

Export-ModuleMember -Function Set-ComputerName

