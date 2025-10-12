#Requires -Version 5.1

<#
.SYNOPSIS
    Post-installation summary and user guidance module
    Provides completion status, next steps, and troubleshooting information

.DESCRIPTION
    This module generates comprehensive post-installation summaries including:
    - Installation completion status
    - Successfully installed components
    - Failed installations with troubleshooting guidance
    - Next steps and recommendations
    - System restart requirements
    - Configuration file locations
    - Backup information

.NOTES
    Author: Damian Korver
#>

# Post-installation summary data structure
class PostInstallSummary {
    [string]$ProfileName
    [DateTime]$StartTime
    [DateTime]$EndTime
    [TimeSpan]$Duration
    [hashtable]$InstalledPackages = @{}
    [hashtable]$FailedPackages = @{}
    [hashtable]$ConfiguredComponents = @{}
    [hashtable]$FailedComponents = @{}
    [string[]]$Warnings = @()
    [string[]]$Recommendations = @()
    [bool]$RequiresRestart
    [string[]]$BackupLocations = @()
    [string]$LogFilePath
    [string]$StructuredLogPath
}

# Global summary instance
$script:InstallSummary = $null

# Initialize post-installation summary
function Initialize-PostInstallSummary {
    param([string]$ProfileName)

    $script:InstallSummary = [PostInstallSummary]::new()
    $script:InstallSummary.ProfileName = $ProfileName
    $script:InstallSummary.StartTime = Get-Date
    $script:InstallSummary.RequiresRestart = $false
}

# Record successful package installation
function Add-PackageInstallation {
    param(
        [string]$PackageName,
        [string]$PackageManager,
        [string]$Version = "",
        [string]$Category = "General"
    )

    if (-not $script:InstallSummary.InstalledPackages.ContainsKey($Category)) {
        $script:InstallSummary.InstalledPackages[$Category] = @()
    }

    $script:InstallSummary.InstalledPackages[$Category] += @{
        Name = $PackageName
        Manager = $PackageManager
        Version = $Version
        Timestamp = Get-Date
    }
}

# Record failed package installation
function Add-PackageFailure {
    param(
        [string]$PackageName,
        [string]$ErrorMessage,
        [string]$Troubleshooting = "",
        [string]$Category = "General"
    )

    if (-not $script:InstallSummary.FailedPackages.ContainsKey($Category)) {
        $script:InstallSummary.FailedPackages[$Category] = @()
    }

    $script:InstallSummary.FailedPackages[$Category] += @{
        Name = $PackageName
        Error = $ErrorMessage
        Troubleshooting = $Troubleshooting
        Timestamp = Get-Date
    }
}

# Record successful component configuration
function Add-ComponentConfiguration {
    param(
        [string]$ComponentName,
        [string]$Description = "",
        [string[]]$FilesModified = @(),
        [string]$Category = "General"
    )

    if (-not $script:InstallSummary.ConfiguredComponents.ContainsKey($Category)) {
        $script:InstallSummary.ConfiguredComponents[$Category] = @()
    }

    $script:InstallSummary.ConfiguredComponents[$Category] += @{
        Name = $ComponentName
        Description = $Description
        FilesModified = $FilesModified
        Timestamp = Get-Date
    }
}

# Record failed component configuration
function Add-ComponentFailure {
    param(
        [string]$ComponentName,
        [string]$ErrorMessage,
        [string]$Troubleshooting = "",
        [string]$Category = "General"
    )

    if (-not $script:InstallSummary.FailedComponents.ContainsKey($Category)) {
        $script:InstallSummary.FailedComponents[$Category] = @()
    }

    $script:InstallSummary.FailedComponents[$Category] += @{
        Name = $ComponentName
        Error = $ErrorMessage
        Troubleshooting = $Troubleshooting
        Timestamp = Get-Date
    }
}

# Add warning message
function Add-InstallationWarning {
    param([string]$Warning)
    $script:InstallSummary.Warnings += $Warning
}

# Add recommendation
function Add-InstallationRecommendation {
    param([string]$Recommendation)
    $script:InstallSummary.Recommendations += $Recommendation
}

# Set restart requirement
function Set-RestartRequired {
    param([string]$Reason = "")
    $script:InstallSummary.RequiresRestart = $true
    if ($Reason) {
        Add-InstallationRecommendation("System restart required: $Reason")
    }
}

# Add backup location
function Add-BackupLocation {
    param([string]$BackupPath, [string]$Description = "")
    $backupInfo = if ($Description) { "$BackupPath ($Description)" } else { $BackupPath }
    $script:InstallSummary.BackupLocations += $backupInfo
}

# Set log file paths
function Set-LogFilePaths {
    param([string]$LogPath, [string]$StructuredLogPath)
    $script:InstallSummary.LogFilePath = $LogPath
    $script:InstallSummary.StructuredLogPath = $StructuredLogPath
}

# Finalize the summary
function Complete-PostInstallSummary {
    $script:InstallSummary.EndTime = Get-Date
    $script:InstallSummary.Duration = $script:InstallSummary.EndTime - $script:InstallSummary.StartTime
}

# Generate and display post-installation summary
function Show-PostInstallSummary {
    if (-not $script:InstallSummary) {
        Write-WarnLog "No installation summary available" -Category "Summary"
        return
    }

    Write-InfoLog "=== WINDOWS LAPTOP AUTOMATION - POST-INSTALLATION SUMMARY ===" -Category "Summary"
    Write-InfoLog "Profile: $($script:InstallSummary.ProfileName)" -Category "Summary"
    Write-InfoLog "Completed: $($script:InstallSummary.EndTime.ToString('yyyy-MM-dd HH:mm:ss'))" -Category "Summary"
    Write-InfoLog "Duration: $($script:InstallSummary.Duration.ToString('mm\:ss'))" -Category "Summary"
    Write-Host ""

    # Successfully installed packages
    if ($script:InstallSummary.InstalledPackages.Count -gt 0) {
        Write-InfoLog "✓ SUCCESSFULLY INSTALLED PACKAGES:" -Category "Summary"
        foreach ($category in $script:InstallSummary.InstalledPackages.Keys) {
            Write-InfoLog "  $category Packages:" -Category "Summary"
            foreach ($package in $script:InstallSummary.InstalledPackages[$category]) {
                $versionInfo = if ($package.Version) { " (v$($package.Version))" } else { "" }
                Write-InfoLog "    • $($package.Name)$versionInfo via $($package.Manager)" -Category "Summary"
            }
        }
        Write-Host ""
    }

    # Successfully configured components
    if ($script:InstallSummary.ConfiguredComponents.Count -gt 0) {
        Write-InfoLog "✓ SUCCESSFULLY CONFIGURED COMPONENTS:" -Category "Summary"
        foreach ($category in $script:InstallSummary.ConfiguredComponents.Keys) {
            Write-InfoLog "  $category Components:" -Category "Summary"
            foreach ($component in $script:InstallSummary.ConfiguredComponents[$category]) {
                Write-InfoLog "    • $($component.Name)" -Category "Summary"
                if ($component.Description) {
                    Write-DebugLog "      $($component.Description)" -Category "Summary"
                }
                if ($component.FilesModified.Count -gt 0) {
                    Write-DebugLog "      Modified files: $($component.FilesModified -join ', ')" -Category "Summary"
                }
            }
        }
        Write-Host ""
    }

    # Failed installations
    $totalFailed = ($script:InstallSummary.FailedPackages.Values | Measure-Object -Sum { $_.Count }).Sum +
                   ($script:InstallSummary.FailedComponents.Values | Measure-Object -Sum { $_.Count }).Sum

    if ($totalFailed -gt 0) {
        Write-WarnLog "⚠ ISSUES ENCOUNTERED:" -Category "Summary"

        if ($script:InstallSummary.FailedPackages.Count -gt 0) {
            Write-WarnLog "  Failed Package Installations:" -Category "Summary"
            foreach ($category in $script:InstallSummary.FailedPackages.Keys) {
                foreach ($failure in $script:InstallSummary.FailedPackages[$category]) {
                    Write-ErrorLog "    • $($failure.Name): $($failure.Error)" -Category "Summary"
                    if ($failure.Troubleshooting) {
                        Write-WarnLog "      Troubleshooting: $($failure.Troubleshooting)" -Category "Summary"
                    }
                }
            }
        }

        if ($script:InstallSummary.FailedComponents.Count -gt 0) {
            Write-WarnLog "  Failed Component Configurations:" -Category "Summary"
            foreach ($category in $script:InstallSummary.FailedComponents.Keys) {
                foreach ($failure in $script:InstallSummary.FailedComponents[$category]) {
                    Write-ErrorLog "    • $($failure.Name): $($failure.Error)" -Category "Summary"
                    if ($failure.Troubleshooting) {
                        Write-WarnLog "      Troubleshooting: $($failure.Troubleshooting)" -Category "Summary"
                    }
                }
            }
        }
        Write-Host ""
    }

    # Warnings
    if ($script:InstallSummary.Warnings.Count -gt 0) {
        Write-WarnLog "⚠ WARNINGS:" -Category "Summary"
        foreach ($warning in $script:InstallSummary.Warnings) {
            Write-WarnLog "  • $warning" -Category "Summary"
        }
        Write-Host ""
    }

    # Next steps and recommendations
    if ($script:InstallSummary.Recommendations.Count -gt 0) {
        Write-InfoLog "📋 NEXT STEPS AND RECOMMENDATIONS:" -Category "Summary"
        foreach ($recommendation in $script:InstallSummary.Recommendations) {
            Write-InfoLog "  • $recommendation" -Category "Summary"
        }
        Write-Host ""
    }

    # System restart requirement
    if ($script:InstallSummary.RequiresRestart) {
        Write-WarnLog "🔄 SYSTEM RESTART REQUIRED" -Category "Summary"
        Write-WarnLog "  Some changes require a system restart to take effect." -Category "Summary"
        Write-WarnLog "  Please restart your computer when convenient." -Category "Summary"
        Write-Host ""
    }

    # Backup information
    if ($script:InstallSummary.BackupLocations.Count -gt 0) {
        Write-InfoLog "💾 BACKUP INFORMATION:" -Category "Summary"
        Write-InfoLog "  Backups were created at:" -Category "Summary"
        foreach ($backup in $script:InstallSummary.BackupLocations) {
            Write-InfoLog "    • $backup" -Category "Summary"
        }
        Write-Host ""
    }

    # Log file locations
    if ($script:InstallSummary.LogFilePath -or $script:InstallSummary.StructuredLogPath) {
        Write-InfoLog "📄 LOG FILES:" -Category "Summary"
        if ($script:InstallSummary.LogFilePath) {
            Write-InfoLog "  Text log: $($script:InstallSummary.LogFilePath)" -Category "Summary"
        }
        if ($script:InstallSummary.StructuredLogPath) {
            Write-InfoLog "  Structured log: $($script:InstallSummary.StructuredLogPath)" -Category "Summary"
        }
        Write-InfoLog "  Use these files for troubleshooting or support requests." -Category "Summary"
        Write-Host ""
    }

    # Final message
    if ($totalFailed -eq 0) {
        Write-InfoLog "🎉 SETUP COMPLETED SUCCESSFULLY!" -Category "Summary"
        Write-InfoLog "  Your Windows laptop automation setup is complete." -Category "Summary"
        Write-InfoLog "  Enjoy your optimized development environment!" -Category "Summary"
    } else {
        Write-WarnLog "⚠️ SETUP COMPLETED WITH ISSUES" -Category "Summary"
        Write-WarnLog "  Review the issues above and consider re-running the setup." -Category "Summary"
        Write-WarnLog "  Check the log files for detailed error information." -Category "Summary"
    }
}

# Export functions
Export-ModuleMember -Function Initialize-PostInstallSummary, Add-PackageInstallation, Add-PackageFailure, Add-ComponentConfiguration, Add-ComponentFailure, Add-InstallationWarning, Add-InstallationRecommendation, Set-RestartRequired, Add-BackupLocation, Set-LogFilePaths, Complete-PostInstallSummary, Show-PostInstallSummary