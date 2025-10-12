# BackupRestore.psm1
# Module for backup and restore capabilities

function New-SystemRestorePoint {
    param([string]$Description = "Windows Laptop Automation Setup")

    try {
        Write-Log "Creating system restore point..." Cyan

        # Check if System Restore is enabled
        $systemDrive = $env:SystemDrive
        $restorePointEnabled = (Get-ComputerRestorePoint | Where-Object { $_.SequenceNumber }).Count -gt 0

        if (-not $restorePointEnabled) {
            Write-Log "System Restore is not enabled on $systemDrive" Yellow
            return $false
        }

        # Create restore point
        Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS"

        Write-Log "System restore point created successfully" Green
        return $true
    } catch {
        Write-Log "Failed to create system restore point: $($_.Exception.Message)" Red
        return $false
    }
}

function Backup-UserConfigurations {
    param([string]$BackupPath = (Join-Path $env:USERPROFILE "Documents\WindowsAutomationBackup"))

    try {
        Write-Log "Backing up user configurations..." Cyan

        # Create backup directory
        if (-not (Test-Path $BackupPath)) {
            New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
        }

        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupDir = Join-Path $BackupPath $timestamp
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

        # Backup PowerShell profile
        $profilePath = $PROFILE
        if (Test-Path $profilePath) {
            Copy-Item -Path $profilePath -Destination (Join-Path $backupDir "PowerShell_profile.ps1") -Force
            Write-Log "PowerShell profile backed up" Gray
        }

        # Backup environment variables
        $envBackup = @{
            Path = $env:PATH
            Temp = $env:TEMP
            Tmp = $env:TMP
        }
        $envBackup | ConvertTo-Json | Set-Content -Path (Join-Path $backupDir "environment_variables.json")

        # Backup installed programs list
        try {
            $installedPrograms = Get-WmiObject -Class Win32_Product | Select-Object Name, Version, Vendor
            $installedPrograms | Export-Csv -Path (Join-Path $backupDir "installed_programs.csv") -NoTypeInformation
            Write-Log "Installed programs list backed up" Gray
        } catch {
            Write-Log "Failed to backup installed programs: $($_.Exception.Message)" Yellow
        }

        Write-Log "User configurations backed up to: $backupDir" Green
        return $backupDir
    } catch {
        Write-Log "Failed to backup user configurations: $($_.Exception.Message)" Red
        return $null
    }
}

function Export-UserPreferences {
    param([string]$ExportPath = (Join-Path $env:USERPROFILE "Documents\WindowsAutomationPreferences.json"))

    try {
        Write-Log "Exporting user preferences..." Cyan

        $preferences = @{
            Theme = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue).AppsUseLightTheme
            TaskbarAlignment = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -ErrorAction SilentlyContinue).TaskbarAl
            StartMenuLayout = Get-StartApps
            FileExplorerSettings = @{
                ShowHiddenFiles = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -ErrorAction SilentlyContinue).Hidden
                ShowFileExtensions = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -ErrorAction SilentlyContinue).HideFileExt
            }
        }

        $preferences | ConvertTo-Json -Depth 3 | Set-Content -Path $ExportPath -Encoding UTF8
        Write-Log "User preferences exported to: $ExportPath" Green
        return $ExportPath
    } catch {
        Write-Log "Failed to export user preferences: $($_.Exception.Message)" Red
        return $null
    }
}

function Import-UserPreferences {
    param([string]$ImportPath)

    if (-not (Test-Path $ImportPath)) {
        Write-Log "Preferences file not found: $ImportPath" Red
        return $false
    }

    try {
        Write-Log "Importing user preferences..." Cyan

        $preferences = Get-Content $ImportPath | ConvertFrom-Json

        # Apply theme
        if ($preferences.Theme -ne $null) {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value $preferences.Theme
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value $preferences.Theme
        }

        # Apply taskbar alignment
        if ($preferences.TaskbarAlignment -ne $null) {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value $preferences.TaskbarAlignment
        }

        # Apply File Explorer settings
        if ($preferences.FileExplorerSettings) {
            if ($preferences.FileExplorerSettings.ShowHiddenFiles -ne $null) {
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value ([int](-not $preferences.FileExplorerSettings.ShowHiddenFiles))
            }
            if ($preferences.FileExplorerSettings.ShowFileExtensions -ne $null) {
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value ([int]$preferences.FileExplorerSettings.ShowFileExtensions)
            }
        }

        Write-Log "User preferences imported successfully" Green
        return $true
    } catch {
        Write-Log "Failed to import user preferences: $($_.Exception.Message)" Red
        return $false
    }
}

function Start-RecoveryMode {
    param([string]$BackupPath)

    Write-Log "Starting recovery mode..." Yellow

    if (-not $BackupPath -or -not (Test-Path $BackupPath)) {
        Write-Log "No valid backup path provided for recovery" Red
        return $false
    }

    try {
        # Restore PowerShell profile
        $profileBackup = Join-Path $BackupPath "PowerShell_profile.ps1"
        if (Test-Path $profileBackup) {
            Copy-Item -Path $profileBackup -Destination $PROFILE -Force
            Write-Log "PowerShell profile restored" Green
        }

        # Restore environment variables
        $envBackup = Join-Path $BackupPath "environment_variables.json"
        if (Test-Path $envBackup) {
            $envVars = Get-Content $envBackup | ConvertFrom-Json
            # Note: Environment variables are typically restored by restarting the shell
            Write-Log "Environment variables backup found (restart shell to apply)" Yellow
        }

        Write-Log "Recovery mode completed" Green
        return $true
    } catch {
        Write-Log "Recovery mode failed: $($_.Exception.Message)" Red
        return $false
    }
}

# Export functions
Export-ModuleMember -Function New-SystemRestorePoint, Backup-UserConfigurations, Export-UserPreferences, Import-UserPreferences, Start-RecoveryMode