Import-Module ./Util.psm1

function Set-MacAddress {

    $NetworkAdapter = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object {
        $_.PhysicalAdapter -eq $true -and $_.Name -notmatch "VMware" -and $_.NetEnabled -eq $true
    }
    
    $NetworkAdapter = $NetworkAdapter | Select-Object -Property Name,NetConnectionID,MacAddress

    if ($NetworkAdapter -is [array]) {
        $NetworkAdapter = $NetworkAdapter[0]
    }
    
    if ($NetworkAdapter.Name -match "Kernel Debug") {
        return        
    }

    $NetConnectionID = $NetworkAdapter.NetConnectionID
    $OriginMacAddress = $NetworkAdapter.MacAddress
    
    $SpoofMacAddress = ""
    foreach($Char in $OriginMacAddress.ToCharArray()) {
    
        if (Test-IsHexChar $Char) {
            $Char = Get-RandomHex
        }
    
        if($Char -eq ':') {
            $Char = '-'
        }
        
        $SpoofMacAddress += $Char    
    }

    Set-NetAdapter -Name $NetConnectionID -MacAddress $SpoofMacAddress -Confirm:$false

    $FileSystemInformation.Add("MacAddress", $OriginMacAddress)
    $ConsoleSystemInformation.Add("MacAddress",$SpoofMacAddress) 
}

