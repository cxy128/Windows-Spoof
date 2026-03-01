Import-Module .\util.psm1

function Remove-AntiCheatExpert {

    param (
        [string]$Keyword = "AntiCheatExpert"
    )

    $services = Get-CimInstance Win32_Service |
    Where-Object { $_.Name -like "*$Keyword*" -or $_.DisplayName -like "*$Keyword*" }

    foreach ($svc in $services) {

        Write-Host "发现服务: $($svc.Name)"

        if ($svc.State -ne "Stopped") {

            Write-Host "停止服务: $($svc.Name)"

            try {

                Stop-Service -Name $svc.Name -Force -ErrorAction Stop

            } catch {

                Write-Host "停止失败: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }

        Write-Host "删除服务: $($svc.Name)"
        sc.exe delete $svc.Name | Out-Null
    }

    $driverPath = "C:\Windows\System32\drivers"

    if (Test-Path $driverPath) {
        Get-ChildItem $driverPath -Filter "*$Keyword*.sys" -ErrorAction SilentlyContinue |
        ForEach-Object {
            Write-Host "删除驱动文件: $($_.FullName)"
            try {
                Remove-Item $_.FullName -Force -ErrorAction Stop
            }
            catch {
                Write-Host "删除失败(可能正在使用): $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
}

function Clear-AntiCheatExpert {

    Write-Host "清理 AntiCheatExpert..."

    Remove-AntiCheatExpert

    $basePaths = @(
        "C:\Program Files",
        "C:\Program Files (x86)",
        "C:\ProgramData"
    )

    foreach ($base in $basePaths) {
        if (Test-Path $base) {
            Get-ChildItem $base -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "*AntiCheatExpert*" } |
            ForEach-Object {
                Write-Host "删除 $($_.FullName)"
                Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {

        $localPath = Join-Path $_.FullName "AppData\Local"
        $roamingPath = Join-Path $_.FullName "AppData\Roaming"

        foreach ($userPath in @($localPath, $roamingPath)) {
            if (Test-Path $userPath) {
                Get-ChildItem $userPath -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like "*AntiCheatExpert*" } |
                ForEach-Object {
                    Write-Host "删除 $($_.FullName)"
                    Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}

function Clear-Traces {

    Write-Host "清理用户 Temp..."
    $UserTemp = $env:TEMP
    Get-ChildItem $UserTemp -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "清理系统 Temp..."
    $SystemTemp = "$env:SystemRoot\Temp"
    Get-ChildItem $SystemTemp -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "清理 Windows Update 缓存..."
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:SystemRoot\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv

    Write-Host "清理事件日志..."
    wevtutil el | ForEach-Object {
        wevtutil cl $_ 2>$null
    }

    Write-Host "重置网络栈..."
    netsh int ip reset *> $null
    netsh winsock reset *> $null
}

Export-ModuleMember -Function Clear-AntiCheatExpert, Clear-Traces