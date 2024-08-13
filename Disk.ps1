Import-Module ./Util.psm1

function Set-DiskSerialNumber {
    
    $SerialNumberPath = @()
    
    foreach($ScsiPortNumber in 0..30) {
    
        $PortPath = "HKLM:\HARDWARE\DEVICEMAP\Scsi\Scsi Port $ScsiPortNumber"
        if(-not $(Test-Path -Path $PortPath)) {
            continue
        }
       
       foreach($ScsiBusNumber in 0..30) {
            $BusPath = $PortPath + "\Scsi Bus $ScsiBusNumber"
            if(-not $(Test-Path -Path $BusPath)) {
                 continue
            }
           
            foreach($TragetIdNumber in 0..30) {
                $TragetIdPath = $BusPath + "\Target Id $TragetIdNumber"
                if(-not $(Test-Path -Path $TragetIdPath)) {
                    continue
                }
                
                foreach($LogicalUnitIdNumber in 0..30) {
                    $LogicalUnitIdPath = $TragetIdPath + "\Logical Unit Id $LogicalUnitIdNumber"
                    if(-not $(Test-Path -Path $LogicalUnitIdPath)) {
                        continue
                    }
                    
                    $SerialNumberPath += $LogicalUnitIdPath
                }
            }
        }
    }
    
    foreach($Path in $SerialNumberPath) {
    
        $SpoofSerialNumber = ""
        $DiskInformation = Get-ItemProperty -Path $Path | Select-Object -Property Identifier, SerialNumber
        $Identifier = $DiskInformation.Identifier
        $OriginSerialNumber = $DiskInformation.SerialNumber
        
        if ($OriginSerialNumber.Length -lt 10) {
        
            0..10 | ForEach-Object {
                
                if ($_ -and ($_ % 5) -eq 0) {
                    
                    $SpoofSerialNumber += "_"
                }
            
                $Char = RandomHex
                $SpoofSerialNumber += $Char
            }
            
            $SpoofSerialNumber += "."
        
        } else {
        
            for($i = 0; $i -lt $OriginSerialNumber.Length; $i++) {
        
                $Char = $OriginSerialNumber[$i]
                if(Test-IsHexChar $Char) {
                    $Char = RandomHex
                }
                $SpoofSerialNumber += $Char
            }
        }

        Set-ItemProperty -Path $Path -Name "SerialNumber" -Type String -Value $SpoofSerialNumber -Force

        $FileSystemInformation.Add("$Identifier SerialNumber", $OriginSerialNumber)
        $ConsoleSystemInformation.Add("$Identifier SerialNumber",$SpoofSerialNumber) 
    }
}

function Set-DiskId {

    $DiskPeripheralPath = "HKLM:\HARDWARE\DESCRIPTION\System\MultifunctionAdapter\0\DiskController\0\DiskPeripheral"
    
    if(-not (Test-Path $DiskPeripheralPath)) {
        $ConsoleSystemInformation.Add("DiskId","path not exist")
        return
    }
    
    foreach($Path in $(Get-ChildItem -Path "HKLM:\HARDWARE\DESCRIPTION\System\MultifunctionAdapter\0\DiskController\0\DiskPeripheral").Name) {
    
        $Path = $Path.Replace("HKEY_LOCAL_MACHINE","HKLM:")
        
        $OriginIdentifier = $(Get-ItemProperty -Path $Path).Identifier
        $SpoofIdentifier = ""
        for($i = 0; $i -lt $OriginIdentifier.Length; $i++) {
                
            $Char = $OriginIdentifier[$i]
            if(($i -ne ($OriginIdentifier.Length - 1)) -and (Test-IsHexChar $Char)) {
                $Char = Get-RandomHex
            }
            
            $SpoofIdentifier += $Char    
        }
        
        Set-ItemProperty -Path $Path -Name "Identifier" -Type String -Value $SpoofIdentifier -Force
        
        $FileSystemInformation.Add("DiskId-$($Path[$Path.Length - 1])", $OriginIdentifier)
        $ConsoleSystemInformation.Add("DiskId-$($Path[$Path.Length - 1])",$SpoofIdentifier)
    }
}










































