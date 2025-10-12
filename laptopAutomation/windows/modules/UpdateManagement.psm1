# UpdateManagement.psm1
# Module for automated software update management and patch deployment

function Get-WindowsUpdateStatus {
    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $searchResult = $updateSearcher.Search("IsInstalled=0")

        $updates = @()
        foreach ($update in $searchResult.Updates) {
            $updates += @{
                Title = $update.Title
                Description = $update.Description
                KBArticleIDs = $update.KBArticleIDs
                IsDownloaded = $update.IsDownloaded
                IsInstalled = $update.IsInstalled
                IsMandatory = $update.IsMandatory
                RebootRequired = $update.RebootRequired
                Size = $update.MaxDownloadSize
            }
        }

        return @{
            TotalUpdates = $searchResult.Updates.Count
            Updates = $updates
            LastSearch = Get-Date
        }
    } catch {
        Write-Log "Error getting Windows update status: $($_.Exception.Message)" Red
        return $null
    }
}

function Install-WindowsUpdates {
    param([switch]$WhatIf, [switch]$IncludeOptional, [int]$MaxUpdates = 50)

    Write-Log "Checking for Windows updates..." Cyan

    if ($WhatIf) {
        Write-Log "DRY RUN: Would check for and install Windows updates" Yellow
        return $true
    }

    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $searchResult = $updateSearcher.Search("IsInstalled=0")

        if ($searchResult.Updates.Count -eq 0) {
            Write-Log "No updates available" Green
            return $true
        }

        Write-Log "Found $($searchResult.Updates.Count) updates" Yellow

        # Limit updates to prevent overwhelming the system
        $updatesToInstall = $searchResult.Updates | Select-Object -First $MaxUpdates

        if (-not $IncludeOptional) {
            $updatesToInstall = $updatesToInstall | Where-Object { $_.IsMandatory -or $_.AutoSelectOnWebSites }
        }

        if ($updatesToInstall.Count -eq 0) {
            Write-Log "No mandatory updates to install" Green
            return $true
        }

        Write-Log "Installing $($updatesToInstall.Count) update(s)..." Cyan

        $updatesCollection = New-Object -ComObject Microsoft.Update.UpdateColl
        foreach ($update in $updatesToInstall) {
            $updatesCollection.Add($update) | Out-Null
        }

        $downloader = $updateSession.CreateUpdateDownloader()
        $downloader.Updates = $updatesCollection
        $downloadResult = $downloader.Download()

        if ($downloadResult.ResultCode -ne 2) {
            Write-Log "Failed to download updates" Red
            return $false
        }

        Write-Log "Updates downloaded successfully" Green

        $installer = $updateSession.CreateUpdateInstaller()
        $installer.Updates = $updatesCollection
        $installResult = $installer.Install()

        $successCount = ($installResult.GetUpdateResult() | Where-Object { $_.ResultCode -eq 2 }).Count
        $failedCount = ($installResult.GetUpdateResult() | Where-Object { $_.ResultCode -ne 2 }).Count

        Write-Log "Update installation completed: $successCount successful, $failedCount failed" $(if ($failedCount -eq 0) { "Green" } else { "Yellow" })

        if ($installResult.RebootRequired) {
            Write-Log "System restart required to complete updates" Yellow
            return "RebootRequired"
        }

        return $true
    } catch {
        Write-Log "Error installing Windows updates: $($_.Exception.Message)" Red
        return $false
    }
}

function Update-ChocolateyPackages {
    param([switch]$WhatIf)

    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Log "Chocolatey not available for package updates" Yellow
        return $false
    }

    Write-Log "Updating Chocolatey packages..." Cyan

    if ($WhatIf) {
        Write-Log "DRY RUN: Would update all Chocolatey packages" Yellow
        return $true
    }

    try {
        choco upgrade all -y --no-progress | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Chocolatey packages updated successfully" Green
            return $true
        } else {
            Write-Log "Failed to update Chocolatey packages" Red
            return $false
        }
    } catch {
        Write-Log "Error updating Chocolatey packages: $($_.Exception.Message)" Red
        return $false
    }
}

function Update-WinGetPackages {
    param([switch]$WhatIf)

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Log "WinGet not available for package updates" Yellow
        return $false
    }

    Write-Log "Updating WinGet packages..." Cyan

    if ($WhatIf) {
        Write-Log "DRY RUN: Would update all WinGet packages" Yellow
        return $true
    }

    try {
        # WinGet doesn't have a direct "upgrade all" command in older versions
        # We'll use the upgrade command with --all flag if available
        winget upgrade --all --silent --accept-source-agreements | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "WinGet packages updated successfully" Green
            return $true
        } else {
            Write-Log "Failed to update WinGet packages" Red
            return $false
        }
    } catch {
        Write-Log "Error updating WinGet packages: $($_.Exception.Message)" Red
        return $false
    }
}

function Update-StoreApps {
    param([switch]$WhatIf)

    Write-Log "Checking for Microsoft Store app updates..." Cyan

    if ($WhatIf) {
        Write-Log "DRY RUN: Would update Microsoft Store apps" Yellow
        return $true
    }

    try {
        # Use the Windows Store API to check for updates
        $namespaceName = "root\cimv2\mdm\dmmap"
        $className = "MDM_EnterpriseModernAppManagement_AppManagement01"

        $appManager = Get-CimInstance -Namespace $namespaceName -ClassName $className -ErrorAction SilentlyContinue

        if ($appManager) {
            $appManager.UpdateScanMethod() | Out-Null
            Write-Log "Microsoft Store apps update check completed" Green
            return $true
        } else {
            Write-Log "Unable to access Microsoft Store update API" Yellow
            return $false
        }
    } catch {
        Write-Log "Error updating Microsoft Store apps: $($_.Exception.Message)" Red
        return $false
    }
}

function Invoke-SystemUpdate {
    param(
        [switch]$WhatIf,
        [switch]$SkipWindowsUpdates,
        [switch]$SkipPackageUpdates,
        [switch]$SkipStoreUpdates,
        [switch]$RebootIfRequired
    )

    Write-Log "Starting comprehensive system update..." Cyan

    $updateResults = @{
        WindowsUpdates = $null
        ChocolateyUpdates = $null
        WinGetUpdates = $null
        StoreUpdates = $null
        RebootRequired = $false
    }

    # Windows Updates
    if (-not $SkipWindowsUpdates) {
        $windowsResult = Install-WindowsUpdates -WhatIf:$WhatIf
        $updateResults.WindowsUpdates = $windowsResult
        if ($windowsResult -eq "RebootRequired") {
            $updateResults.RebootRequired = $true
        }
    }

    # Package Updates
    if (-not $SkipPackageUpdates) {
        $updateResults.ChocolateyUpdates = Update-ChocolateyPackages -WhatIf:$WhatIf
        $updateResults.WinGetUpdates = Update-WinGetPackages -WhatIf:$WhatIf
    }

    # Store Updates
    if (-not $SkipStoreUpdates) {
        $updateResults.StoreUpdates = Update-StoreApps -WhatIf:$WhatIf
    }

    # Handle reboot if required
    if ($updateResults.RebootRequired -and $RebootIfRequired -and -not $WhatIf) {
        Write-Log "System restart required. Restarting in 60 seconds..." Yellow
        Write-Log "Press Ctrl+C to cancel restart" Yellow
        Start-Sleep -Seconds 60
        Restart-Computer -Force
    }

    return $updateResults
}

function Get-UpdateSchedule {
    param([string]$TaskName = "WindowsAutomationUpdates")

    try {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        return $task
    } catch {
        return $null
    }
}

function Set-UpdateSchedule {
    param(
        [string]$TaskName = "WindowsAutomationUpdates",
        [string]$ScriptPath,
        [string]$Schedule = "Weekly",
        [int]$DayOfWeek = 1,  # Monday
        [int]$Hour = 2        # 2 AM
    )

    if (-not (Test-Path $ScriptPath)) {
        Write-Log "Script path not found: $ScriptPath" Red
        return $false
    }

    try {
        # Remove existing task if it exists
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        }

        # Create new scheduled task
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" -EnableUpdateManagement"
        $trigger = switch ($Schedule) {
            "Daily" { New-ScheduledTaskTrigger -Daily -At (Get-Date -Hour $Hour -Minute 0 -Second 0) }
            "Weekly" { New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DayOfWeek -At (Get-Date -Hour $Hour -Minute 0 -Second 0) }
            default { New-ScheduledTaskTrigger -Weekly -DaysOfWeek 1 -At (Get-Date -Hour $Hour -Minute 0 -Second 0) }
        }

        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType InteractiveToken

        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Automated system updates via Windows Automation"

        Write-Log "Update schedule created: $TaskName ($Schedule at $($Hour):00)" Green
        return $true
    } catch {
        Write-Log "Error creating update schedule: $($_.Exception.Message)" Red
        return $false
    }
}

# Export functions
Export-ModuleMember -Function * -Alias *