$Desktop = [System.Environment]::GetFolderPath('Desktop')
$BakFileName  = "SystemInformation_bak.txt"

New-Item -Type File -Path $Desktop -Name $BakFileName -Force

Write-Output "`n"

$Alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

function Get-RandomGuid(){
    return [guid]::NewGuid().ToString();
}

function Get-SerialNumber {

    param (
        [int]$SectionNumber = 5
    )

   $Value = ""
   1..$SectionNumber | ForEach-Object {
   
        $RandomNumber = [string]::Concat($(Get-Random))
        if($RandomNumber.Length -lt 5) {
            $RandomNumber = '00000'
        }
        
        $RandomNumber = $RandomNumber.SubString(0,5)
        if($_ -ne $SectionNumber) {
           $RandomNumber = -join($RandomNumber,'-')
        }
        
        $Value += $RandomNumber
   }
   
   return $Value
}

function Get-RandomName {

    param (
        [int]$NameLength        
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
    
    $SeparatorWidth = 20 - $KeyLength.ToString().Length
    
    return " " * $SeparatorWidth
}

function Get-SystemInformation {

    param (
        [string]$Key,
        [string]$Entry
    )
    
    if([string]::IsNullOrEmpty($Key) -or [string]::IsNullOrEmpty($Entry)){
        return
    }
    
    $ItemProperty = Get-ItemProperty -Path $Key | Select-Object -Property $Entry
    $Value = $ItemProperty.$Entry.Replace('{','').Replace('}','')
    
    $EntrySeparator = Get-Separator $Entry
    -join($Entry, ${EntrySeparator} ,$Value) | Out-File -FilePath $BakFileName -Append
    
    return $Value
}

function Set-SystemInformation {

    param (
        [string]$Key,
        [string]$Entry,
        [string]$Type,
        [string]$Value
    )
    
    if([string]::IsNullOrEmpty($Key) -or [string]::IsNullOrEmpty($Entry) -or [string]::IsNullOrEmpty($Type) -or [string]::IsNullOrEmpty($Value)){
        return
    }
    
    $OriginValue = Get-SystemInformation $Key $Entry
    
    Set-ItemProperty -Path $Key -Name $Entry -Type $Type -Value $Value -Force
    
    Write-Output "Before $Entry`: $OriginValue After $Entry`: $($Value.Replace('{','').Replace('}',''))"
}

function Set-DisplayEDID {

    $ErrorActionPreference = "SilentlyContinue"

    $DisplayRegistry = "HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY\"

    $DisplayArray = $(Get-ChildItem -Path $DisplayRegistry | Select-Object -Property PSChildName).PsChildName
    if($($DisplayArray -is [Array]) -eq $false) {
        $DisplayArray = @($DisplayArray)
    }

    0..$($DisplayArray.Length - 1) | ForEach-Object {

        $DisplayName = $DisplayArray[$_]
        if([string]::IsNullOrEmpty($DisplayName)) {
            continue
        }

        $DisplayPath = $DisplayRegistry + $DisplayName + "\"

        $DisplayUidArray = $(Get-ChildItem -Path $DisplayPath | Select-Object -Property PSChildName).PsChildName
        if($($DisplayUidArray -is [Array]) -eq $false) {
            $DisplayUidArray = @($DisplayUidArray)
        }

        0..$($DisplayUidArray.Length - 1) | ForEach-Object {

            $DisplayUidName = $DisplayUidArray[$_]
            if([string]::IsNullOrEmpty($DisplayUidName)) {
                continue
            }

            $DisplayUidPath = $DisplayPath + $DisplayUidName + "\"

            $DisplayItemArray = $(Get-ChildItem -Path $DisplayUidPath | Select-Object -Property PSChildName).PsChildName
            if($($DisplayItemArray -is [Array]) -eq $false) {
                $DisplayItemArray = @($DisplayItemArray)
            }

            0..$($DisplayItemArray.Length - 1) | ForEach-Object {

                $DisplayItemName = $DisplayItemArray[$_]
                if([string]::Compare($DisplayItemName,"Device Parameters") -ne 0) {
                    continue
                }

                $DisplayItemPath = $DisplayUidPath + $DisplayItemName

                $EDID = $(Get-ItemProperty -Path $DisplayItemPath | Select-Object -Property EDID).EDID

                $ProductCodeIDSeparator = Get-Separator "ProductCodeID"
                $OriginProductCodeID = ""
                $SpoofProductCodeID = ""
                10..11 | ForEach-Object {
                    $OriginProductCodeID += "0x{0:X2} " -f $($EDID[$_])
                    $XorByte = $(Get-Random) -band 255
                    $EDID[$_] = $XorByte -bxor $EDID[$_]
                    $SpoofProductCodeID += "0x{0:X2} " -f $($EDID[$_])
                }

                $SerialNumberIDSeparator = Get-Separator "SerialNumberID"
                $OriginSerialNumberID = ""
                $SpoofSerialNumberID = ""
                12..15 | ForEach-Object {
                    $OriginSerialNumberID += "0x{0:X2} " -f $($EDID[$_])
                    $XorByte = $(Get-Random) -band 255
                    $EDID[$_] = $XorByte -bxor $EDID[$_]
                    $SpoofSerialNumberID += "0x{0:X2} " -f $($EDID[$_])
                }

                $DisplaySeparator = Get-Separator
                $DisplayInformation = "SerialNumberID${SerialNumberIDSeparator}$OriginSerialNumberID${DisplaySeparator}ProductCodeID${ProductCodeIDSeparator}$OriginProductCodeID"
                $DisplayInformation | Out-File -FilePath $BakFileName -Append -Encoding unicode

                Write-Output "Before ProductCodeID`: $OriginProductCodeID After ProductCodeID`: $SpoofProductCodeID"
                Write-Output "Before SerialNumberID`: $OriginSerialNumberID After SerialNumberID`: $SpoofSerialNumberID"

                Set-itemProperty -Path $DisplayItemPath -Name EDID -Value $EDID -Type Binary
            }
        }
    }

    $ErrorActionPreference = "Continue"
}

function Test {

#   设备ID
    $MachineId = "{$($(Get-RandomGuid).ToUpper())}" 
    Set-SystemInformation "HKLM:\SOFTWARE\Microsoft\SQMClient" "MachineId" "string" $MachineId
    
#   产品ID
    $ProductId = $(Get-SerialNumber 4).ToUpper()
    Set-SystemInformation "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" "ProductId" "string" $ProductId
    
#   设备名称
    $DeviceName = Get-RandomName 30

    $ComputerName = $(Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" | Select-Object -Property ComputerName).ComputerName
    $DeviceNameSeparator = Get-Separator "DeviceName"
    "DeviceName${DeviceNameSeparator}$ComputerName" | Out-File -FilePath $BakFileName -Append -Encoding unicode
    
#     Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName' -Type string -Name "ComputerName" -Value $DeviceName -Force
#     Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName' -Type string -Name "ComputerName" -Value $DeviceName -Force
    
    Rename-Computer -NewName $DeviceName -Force *>$null
    
    Write-Output "Before DeviceName`: $ComputerName After DeviceName`: $DeviceName"
    
#   安装日期
    $DateTime = [math]::Floor($(Get-Date).ToFileTimeUtc())

    $OriginInstallDate = $(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' | Select-Object -Property InstallDate).InstallDate
    $OriginInstallTime = $(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' | Select-Object -Property InstallTime).InstallTime
    
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'InstallDate' -Value $([int]$(($DateTime - 116444736000000000) / 10000000)) -Type DWord -Force
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'InstallTime' -Value $([long]$($($DateTime) / 100000000 * 100000000)) -Type QWord -Force

    $InstallDateSeparator = Get-Separator "InstallDate"
    $InstallTimeSeparator = Get-Separator "InstallTime"
    "InstallDate${InstallDateSeparator}$OriginInstallDate`nInstallTime${InstallTimeSeparator}$OriginInstallTime" | Out-File -FilePath $BakFileName -Append -Encoding unicode
    
    Write-Output "Before InstallDate`: $([datetime]::FromFileTime($OriginInstallTime)) After InstallDate`: $([datetime]::FromFileTime($DateTime))"

#   显示器
    Set-DisplayEDID
}

Test













