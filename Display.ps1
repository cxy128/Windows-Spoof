Import-Module ./Util.psm1

function Set-DisplayEDID {

    $DisplayRegistry = "HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY\"
    $DisplayNameArray = $(Get-ChildItem -Path $DisplayRegistry | Select-Object -Property Name).Name

    if($DisplayNameArray -isnot [array]) {
        $DisplayNameArray = @($DisplayNameArray)
    }

    for ($i = 0; $i -lt $DisplayNameArray.Length; $i++) {

        $DisplayNamePath = $DisplayNameArray[$i]

        $DisplayNameStr = $DisplayNamePath.SubString($DisplayNamePath.LastIndexOf("\") + 1)

        $DisplayNamePath = $DisplayNamePath.Replace("HKEY_LOCAL_MACHINE","HKLM:")

        $DisplayUidArray = $(Get-ChildItem -Path $DisplayNamePath | Select-Object -Property Name).Name

        if($DisplayUidArray -isnot [array]) {
            $DisplayUidArray = @($DisplayUidArray)
        }

        for ($n = 0; $n -lt $DisplayUidArray.Length; $n++) {

            $DisplayUidPath = $DisplayUidArray[$n]

            $DisplayUidStr = $DisplayUidPath.SubString($DisplayUidPath.LastIndexOf("\") + 1)
            $DisplayUidStr = $DisplayUidStr.SubString($DisplayUidStr.LastIndexOf("UID"));

            $DisplayUidPath = $DisplayUidPath.Replace("HKEY_LOCAL_MACHINE","HKLM:")
            $DisplayUidPath = $DisplayUidPath + "\Device Parameters"

            if(-not $(Test-Path -Path $DisplayUidPath)) {
                continue
            }

            $EDID = $(Get-ItemProperty -Path $DisplayUidPath | Select-Object -Property EDID).EDID
            if( $EDID.Length -lt 16) {
                continue
            }

            $OriginProductCodeID = ""
            $SpoofProductCodeID = ""
            10..11 | ForEach-Object {
                $OriginProductCodeID += "0x{0:X2} " -f $($EDID[$_])
                $XorByte = $(Get-Random) -band 255
                $EDID[$_] = $XorByte -bxor $EDID[$_]
                $SpoofProductCodeID += "0x{0:X2} " -f $($EDID[$_])
            }

            $OriginSerialNumberID = ""
            $SpoofSerialNumberID = ""
            12..15 | ForEach-Object {
                $OriginSerialNumberID += "0x{0:X2} " -f $($EDID[$_])
                $XorByte = $(Get-Random) -band 255
                $EDID[$_] = $XorByte -bxor $EDID[$_]
                $SpoofSerialNumberID += "0x{0:X2} " -f $($EDID[$_])
            }

            $FileSystemInformation.Add("$DisplayNameStr-$DisplayUidStr-$n-ProductCodeId", $OriginProductCodeID)
            $FileSystemInformation.Add("$DisplayNameStr-$DisplayUidStr-$n-SerialNumberId", $OriginSerialNumberID)

            $ConsoleSystemInformation.Add("$DisplayNameStr-$DisplayUidStr-$n-ProductCodeId", $SpoofProductCodeID)
            $ConsoleSystemInformation.Add("$DisplayNameStr-$DisplayUidStr-$n-SerialNumberId", $SpoofSerialNumberID)

            Set-itemProperty -Path $DisplayUidPath -Name EDID -Value $EDID -Type Binary
        }
    }
}

