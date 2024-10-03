Import-Module .\Util.psm1

function Set-TraceGuid {

    param (
        [String] $Path,
        [String] $Name
    )

    if(-not (Test-Path -Path $Path)) {
        return
    }
    
    $WppRecorder_TraceGuid = Get-ItemProperty -Path $Path -Name "WppRecorder_TraceGuid" -ErrorAction SilentlyContinue

    $OriginTraceGuid = if ($WppRecorder_TraceGuid -and $WppRecorder_TraceGuid.WppRecorder_TraceGuid) {
        
        $WppRecorder_TraceGuid.WppRecorder_TraceGuid -replace '{' -replace '}'

    } else {

        'null'
    }

    $FileSystemInformation.Add("Origin$Name", $OriginTraceGuid)

    $SpoofTraceGuid = [System.Guid]::NewGuid().Guid
    Set-ItemProperty -Path $Path -Value "{$SpoofTraceGuid}" -Type String -Force
    $ConsoleSystemInformation.Add("Spoof$Name",$SpoofTraceGuid) 
}

function Set-HidGuid {

    $KbdclassPath = 'HKLM:\SYSTEM\ControlSet001\Services\kbdclass\Parameters'
    Set-TraceGuid -Path $KbdclassPath -Name 'KbdclassTraceGuid'

    $KbdhidPath = 'HKLM:\SYSTEM\ControlSet001\Services\kbdhid\Parameters'
    Set-TraceGuid -Path $KbdhidPath -Name 'KbdhidTraceGuid'

    $MouclassPath = 'HKLM:\SYSTEM\ControlSet001\Services\mouclass\Parameters'
    Set-TraceGuid -Path $MouclassPath -Name 'MouclassTraceGuid'

    $MouhidPath = 'HKLM:\SYSTEM\ControlSet001\Services\mouhid\Parameters'
    Set-TraceGuid -Path $MouhidPath -Name 'MouhidTraceGuid'
}

function Set-IntelPMT {

    $IntelPMT = 'HKLM:\SYSTEM\ControlSet001\Services\IntelPMT\Parameters'
    Set-TraceGuid -Path $IntelPMT -Name 'Intel-PMT'
}
