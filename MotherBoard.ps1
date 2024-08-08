Import-Module ./Util.psm1

function Set-MotherBoard {

    $OriginLastConfig = $(Get-ItemProperty -Path "HKLM:\SYSTEM\HardwareConfig" | Select-Object -Property LastConfig).LastConfig
    
    $SpoofLastConfig = $OriginLastConfig.ToCharArray();
    for($i = 0; $i -lt $SpoofLastConfig.Length; $i++) {
        if(-not (Test-IsHexChar $SpoofLastConfig[$i])) {
            continue
        }
        $RandomHex = Get-RandomHex
        $SpoofLastConfig[$i] = $RandomHex
    }

    $SpoofLastConfig = -join $SpoofLastConfig
    New-Item -Path "HKLM:\SYSTEM\HardwareConfig\" -Name $SpoofLastConfig -Force *>$null

    $LastConfigEntries = $(Get-ChildItem -Path "HKLM:\SYSTEM\HardwareConfig\$OriginLastConfig" | Select-Object -Property Name).Name
    $LastConfigEntries | Foreach-Object {
        $Entry = $_.Replace("HKEY_LOCAL_MACHINE","HKLM:")
        Copy-Item -Path $Entry -Destination "HKLM:\SYSTEM\HardwareConfig\$SpoofLastConfig" -Recurse
    }
    
    $LastConfigItemProperty = Get-ItemProperty -Path "HKLM:\SYSTEM\HardwareConfig\$OriginLastConfig" | Select-Object -ExcludeProperty PS*
    $LastConfigItemProperty = $LastConfigItemProperty | Get-Member -MemberType NoteProperty
    $LastConfigItemProperty | Foreach-Object {
        $Value = $(Get-ItemProperty -Path "HKLM:\SYSTEM\HardwareConfig\$OriginLastConfig" -Name $_.Name).$($_.Name)
        $Type = Reset-Type $Value.GetType().ToString()
        Set-ItemProperty -Path "HKLM:\SYSTEM\HardwareConfig\$SpoofLastConfig" -Name $_.Name -Type $Type -Value $Value
    }
    
    Set-ItemProperty -Path "HKLM:\SYSTEM\HardwareConfig" -Name LastConfig -Type String -Value $SpoofLastConfig
    
    Remove-Item -Path "HKLM:\SYSTEM\HardwareConfig\$OriginLastConfig" -Recurse -Force
    
    $FileSystemInformation.Add("LastConfig", $OriginLastConfig)
    $ConsoleSystemInformation.Add("LastConfig", $SpoofLastConfig) 
}
