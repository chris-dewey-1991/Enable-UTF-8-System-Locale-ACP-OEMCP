<#
Enable/Disable: "Beta: Use Unicode UTF-8 for worldwide language support"
- Install: saves current ACP/OEMCP, then sets both to 65001
- Remove : restores ACP/OEMCP from saved values

Change $Action to "Install" or "Remove"
Run as ADMIN (SYSTEM is fine in Intune)
Reboot required for effect
#>

$Action = "Install"   # <-- CHANGE THIS: "Install" or "Remove"

$CodePagePath = "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage"
$BackupPath   = "HKLM:\SOFTWARE\NetPrimates\UTF8LocaleBackup"
$Utf8         = "65001"

$AcpName = "ACP"
$OemName = "OEMCP"

function Get-CP([string]$Name) {
    (Get-ItemProperty -Path $CodePagePath -Name $Name -ErrorAction Stop).$Name
}

function Set-CP([string]$Name, [string]$Value) {
    Set-ItemProperty -Path $CodePagePath -Name $Name -Value $Value -Type String -ErrorAction Stop
}

function Ensure-Key([string]$Path) {
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
}

try {
    if (-not (Test-Path $CodePagePath)) { throw "Registry path not found: $CodePagePath" }

    switch ($Action) {
        "Install" {
            # Read current values
            $origACP  = Get-CP $AcpName
            $origOEM  = Get-CP $OemName

            # Save only if not already saved (prevents overwriting original backup on re-runs)
            Ensure-Key $BackupPath
            if (-not (Get-ItemProperty -Path $BackupPath -Name "OriginalACP" -ErrorAction SilentlyContinue)) {
                New-ItemProperty -Path $BackupPath -Name "OriginalACP" -Value $origACP -PropertyType String -Force | Out-Null
                New-ItemProperty -Path $BackupPath -Name "OriginalOEMCP" -Value $origOEM -PropertyType String -Force | Out-Null
                New-ItemProperty -Path $BackupPath -Name "BackupTimestampUtc" -Value ([DateTime]::UtcNow.ToString("o")) -PropertyType String -Force | Out-Null
            }

            # Set UTF-8
            Set-CP $AcpName $Utf8
            Set-CP $OemName $Utf8

            Write-Host "Enabled UTF-8 system locale (ACP/OEMCP=65001). Reboot required."
            exit 0
        }

        "Remove" {
            if (-not (Test-Path $BackupPath)) {
                throw "No backup found at $BackupPath. Refusing to guess defaults."
            }

            $backup = Get-ItemProperty -Path $BackupPath -ErrorAction Stop
            $origACP = $backup.OriginalACP
            $origOEM = $backup.OriginalOEMCP

            if ([string]::IsNullOrWhiteSpace($origACP) -or [string]::IsNullOrWhiteSpace($origOEM)) {
                throw "Backup values missing or invalid in $BackupPath. Refusing to guess defaults."
            }

            # Restore originals
            Set-CP $AcpName $origACP
            Set-CP $OemName $origOEM

            Write-Host "Restored original system locale (ACP=$origACP, OEMCP=$origOEM). Reboot required."
            exit 0
        }

        default {
            throw "Invalid Action '$Action'. Use 'Install' or 'Remove'."
        }
    }
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    exit 1
}
