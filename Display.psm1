Import-Module .\util.psm1

function Set-UserModeDriverGUID {

    $path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000'

    Set-RegistryGuidValue -Path $path -Name "UserModeDriverGUID" -WrapWithBraces
}

function Set-VideoId {

    $path = 'HKLM:\SYSTEM\CurrentControlSet\Services\BasicDisplay\Video'

    Set-RegistryGuidValue -Path $path -Name "VideoID" -WrapWithBraces
}

function Set-DisplayEDID {

    $displayRoot = "HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY"

    if (-not (Test-Path $displayRoot)) {
        return
    }

    foreach ($display in Get-ChildItem $displayRoot) {

        foreach ($uid in Get-ChildItem $display.PSPath) {

            $devicePath = Join-Path $uid.PSPath "Device Parameters"

            if (-not (Test-Path $devicePath)) { 
                continue
            }

            $edid = (Get-ItemProperty -Path $devicePath -Name EDID -ErrorAction SilentlyContinue).EDID
            if (-not $edid -or $edid.Length -lt 16) { 
                continue
            }

            $displayName = Split-Path $display.PSChildName -Leaf
            $uidName = Split-Path $uid.PSChildName -Leaf

            $originProduct = ($edid[10..11] | ForEach-Object { "0x{0:X2}" -f $_ }) -join " "
            $originSerial = ($edid[12..15] | ForEach-Object { "0x{0:X2}" -f $_ }) -join " "

            10..15 | ForEach-Object {
                $edid[$_] = (Get-Random -Maximum 256) -bxor $edid[$_]
            }

            for ($block = 0; $block -lt $edid.Length; $block += 128) {

                $sum = 0

                for ($i = $block; $i -lt ($block + 127); $i++) {
                    $sum += $edid[$i]
                }

                $edid[$block + 127] = (256 - ($sum % 256)) % 256
            }

            $spoofProduct = ($edid[10..11] | ForEach-Object { "0x{0:X2}" -f $_ }) -join " "
            $spoofSerial = ($edid[12..15] | ForEach-Object { "0x{0:X2}" -f $_ }) -join " "

            $keyPrefix = "$displayName-$uidName"

            $script:FileSystemInformation["$keyPrefix-ProductCodeId"] = $originProduct
            $script:FileSystemInformation["$keyPrefix-SerialNumberId"] = $originSerial

            $script:ConsoleSystemInformation["$keyPrefix-ProductCodeId"] = $spoofProduct
            $script:ConsoleSystemInformation["$keyPrefix-SerialNumberId"] = $spoofSerial

            Set-ItemProperty -Path $devicePath -Name EDID -Value $edid -Type Binary
        }
    }
}

function Set-DisplayInformation {   

    Set-UserModeDriverGUID

    Set-VideoId

    Set-DisplayEDID
}

Export-ModuleMember -Function Set-DisplayInformation