<#
Detection for: "Beta: Use Unicode UTF-8 for worldwide language support"
Exit 0 = compliant (enabled)
Exit 1 = not compliant
#>

$RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage"

try {
    $acp  = (Get-ItemProperty -Path $RegPath -Name "ACP"   -ErrorAction Stop)."ACP"
    $oem  = (Get-ItemProperty -Path $RegPath -Name "OEMCP" -ErrorAction Stop)."OEMCP"

    if ($acp -eq "65001" -and $oem -eq "65001") {
        Write-Host "Compliant: ACP and OEMCP are 65001 (UTF-8 enabled)."
        exit 0
    } else {
        Write-Host "Not compliant: ACP=$acp OEMCP=$oem (expected 65001/65001)."
        exit 1
    }
}
catch {
    Write-Host "Not compliant: Unable to read code page values. $($_.Exception.Message)"
    exit 1
}
