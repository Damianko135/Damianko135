# InteractiveMode.psm1
# Module for interactive package and configuration selection

function Show-InteractiveMenu {
    param([array]$AvailablePackages, [hashtable]$CurrentConfig)

    Write-Log "Starting interactive configuration mode..." Cyan
    Write-Log "Use the menus below to customize your installation" Gray
    Write-Host ""

    # Package selection
    $selectedPackages = Show-PackageSelectionMenu -AvailablePackages $AvailablePackages -CurrentPackages $CurrentConfig.packages

    # Configuration options
    $configOptions = Show-ConfigurationMenu -CurrentConfig $CurrentConfig

    # Combine selections
    $finalConfig = @{
        packages = $selectedPackages
        includeOffice = $configOptions.includeOffice
        includeWSL = $configOptions.includeWSL
        skipHeavyPackages = $configOptions.skipHeavyPackages
    }

    Write-Log "Configuration complete!" Green
    return $finalConfig
}

function Show-PackageSelectionMenu {
    param([array]$AvailablePackages, [array]$CurrentPackages = @())

    $selectedPackages = $CurrentPackages.Clone()

    do {
        Write-Host "`n=== Package Selection ===" -ForegroundColor Yellow
        Write-Host "Select packages to install (use numbers, comma-separated for multiple):" -ForegroundColor Gray
        Write-Host ""

        for ($i = 0; $i -lt $AvailablePackages.Count; $i++) {
            $package = $AvailablePackages[$i]
            $marker = if ($selectedPackages -contains $package.Name) { "[X]" } else { "[ ]" }
            Write-Host "$($i + 1). $marker $($package.Name)" -ForegroundColor $(if ($selectedPackages -contains $package.Name) { "Green" } else { "White" })
            Write-Host "   $($package.Description)" -ForegroundColor Gray
        }

        Write-Host ""
        Write-Host "Options:" -ForegroundColor Cyan
        Write-Host "  'all' - Select all packages" -ForegroundColor Gray
        Write-Host "  'none' - Clear all selections" -ForegroundColor Gray
        Write-Host "  'done' - Finish package selection" -ForegroundColor Gray
        Write-Host ""

        $userInput = Read-Host "Enter your choice"

        switch ($userInput.ToLower()) {
            "all" {
                $selectedPackages = $AvailablePackages | ForEach-Object { $_.Name }
                Write-Log "Selected all packages" Green
            }
            "none" {
                $selectedPackages = @()
                Write-Log "Cleared all selections" Yellow
            }
            "done" {
                break
            }
            default {
                try {
                    $selections = $input -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' } | ForEach-Object {
                        $index = [int]$_ - 1
                        if ($index -ge 0 -and $index -lt $AvailablePackages.Count) {
                            $AvailablePackages[$index].Name
                        }
                    }

                    foreach ($package in $selections) {
                        if ($selectedPackages -contains $package) {
                            $selectedPackages = $selectedPackages | Where-Object { $_ -ne $package }
                            Write-Log "Deselected: $package" Yellow
                        } else {
                            $selectedPackages += $package
                            Write-Log "Selected: $package" Green
                        }
                    }
                } catch {
                    Write-Log "Invalid input. Please enter numbers separated by commas." Red
                }
            }
        }
    } while ($true)

    return $selectedPackages
}

function Show-ConfigurationMenu {
    param([hashtable]$CurrentConfig)

    $config = @{
        includeOffice = $CurrentConfig.includeOffice
        includeWSL = $CurrentConfig.includeWSL
        skipHeavyPackages = $CurrentConfig.skipHeavyPackages
    }

    do {
        Write-Host "`n=== Configuration Options ===" -ForegroundColor Yellow
        Write-Host ""

        Write-Host "1. $(if ($config.includeOffice) { '[X]' } else { '[ ]' }) Include Microsoft Office" -ForegroundColor $(if ($config.includeOffice) { "Green" } else { "White" })
        Write-Host "2. $(if ($config.includeWSL) { '[X]' } else { '[ ]' }) Include Windows Subsystem for Linux (WSL2)" -ForegroundColor $(if ($config.includeWSL) { "Green" } else { "White" })
        Write-Host "3. $(if ($config.skipHeavyPackages) { '[X]' } else { '[ ]' }) Skip resource-intensive packages" -ForegroundColor $(if ($config.skipHeavyPackages) { "Green" } else { "White" })

        Write-Host ""
        Write-Host "Enter option number to toggle, or 'done' to finish:" -ForegroundColor Cyan

        $userInput = Read-Host "Enter your choice"

        switch ($userInput.ToLower()) {
            "1" {
                $config.includeOffice = -not $config.includeOffice
                Write-Log "Office inclusion: $($config.includeOffice)" $(if ($config.includeOffice) { "Green" } else { "Yellow" })
            }
            "2" {
                $config.includeWSL = -not $config.includeWSL
                Write-Log "WSL inclusion: $($config.includeWSL)" $(if ($config.includeWSL) { "Green" } else { "Yellow" })
            }
            "3" {
                $config.skipHeavyPackages = -not $config.skipHeavyPackages
                Write-Log "Skip heavy packages: $($config.skipHeavyPackages)" $(if ($config.skipHeavyPackages) { "Green" } else { "Yellow" })
            }
            "done" {
                break
            }
            default {
                Write-Log "Invalid option. Please enter 1-3 or 'done'." Red
            }
        }
    } while ($true)

    return $config
}

function Get-AvailablePackages {
    param([string]$PackageListPath)

    if (-not (Test-Path $PackageListPath)) {
        Write-Log "Package list not found: $PackageListPath" Red
        return @()
    }

    $packages = Get-Content $PackageListPath | ConvertFrom-Json

    # Add descriptions for interactive display
    $packagesWithDescriptions = $packages | ForEach-Object {
        $description = switch ($_.Name) {
            "git" { "Version control system" }
            "vscode" { "Popular code editor" }
            "powershell-core" { "Cross-platform PowerShell" }
            "nodejs" { "JavaScript runtime" }
            "docker-desktop" { "Container platform" }
            "visualstudio2022community" { "Full IDE for development" }
            "steam" { "Gaming platform" }
            "discord" { "Voice and text chat" }
            "geforce-experience" { "NVIDIA graphics optimization" }
            default { "Software package" }
        }

        [PSCustomObject]@{
            Name = $_.Name
            Description = $description
            chocoId = $_.chocoId
            wingetId = $_.wingetId
        }
    }

    return $packagesWithDescriptions
}

# Export functions
Export-ModuleMember -Function Show-InteractiveMenu, Get-AvailablePackages