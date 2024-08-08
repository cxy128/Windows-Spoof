Import-Module ./Util.psm1

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

                $ProductCodeIDSeparator = Get-Separator "ProductCodeId"
                $OriginProductCodeID = ""
                $SpoofProductCodeID = ""
                10..11 | ForEach-Object {
                    $OriginProductCodeID += "0x{0:X2} " -f $($EDID[$_])
                    $XorByte = $(Get-Random) -band 255
                    $EDID[$_] = $XorByte -bxor $EDID[$_]
                    $SpoofProductCodeID += "0x{0:X2} " -f $($EDID[$_])
                }

                $SerialNumberIDSeparator = Get-Separator "SerialNumberId"
                $OriginSerialNumberID = ""
                $SpoofSerialNumberID = ""
                12..15 | ForEach-Object {
                    $OriginSerialNumberID += "0x{0:X2} " -f $($EDID[$_])
                    $XorByte = $(Get-Random) -band 255
                    $EDID[$_] = $XorByte -bxor $EDID[$_]
                    $SpoofSerialNumberID += "0x{0:X2} " -f $($EDID[$_])
                }

                $FileSystemInformation.Add("ProductCodeId", $OriginProductCodeID)
                $FileSystemInformation.Add("SerialNumberId", $OriginSerialNumberID)
                
                $ConsoleSystemInformation.Add("ProductCodeId", $SpoofProductCodeID)
                $ConsoleSystemInformation.Add("SerialNumberId", $SpoofSerialNumberID)

                Set-itemProperty -Path $DisplayItemPath -Name EDID -Value $EDID -Type Binary
            }
        }
    }

    $ErrorActionPreference = "Continue"
}