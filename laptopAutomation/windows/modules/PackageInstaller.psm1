# PackageInstaller.psm1
# Module for handling package installation via Chocolatey and WinGet

function Install-Chocolatey {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Log "Chocolatey is already installed" Green
        return $true
    }

    $success = Invoke-WithRetry -ScriptBlock {
        Write-Log "Installing Chocolatey..." Cyan
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        # Refresh environment variables
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")

        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            throw "Chocolatey installation completed but choco command not found in PATH"
        }
    } -OperationName "Chocolatey installation"

    if ($success) {
        Write-Log "Chocolatey installed successfully" Green
        return $true
    } else {
        Write-Log "Chocolatey installation failed after retries" Red
        return $false
    }
}function Test-WinGet {
    try {
        $null = Get-Command winget -ErrorAction Stop
        return $true
    } catch {
        Write-Log "WinGet not available" Yellow
        return $false
    }
}

function Install-ChocoPackage {
    param([string]$PackageId, [string]$PackageName)

    $success = Invoke-WithRetry -ScriptBlock {
        Write-Log "Installing $PackageName via Chocolatey..." Cyan
        choco install $PackageId -y --no-progress
        if ($LASTEXITCODE -ne 0) {
            throw "Chocolatey installation failed with exit code $LASTEXITCODE"
        }
    } -OperationName "Chocolatey installation of $PackageName"

    if ($success) {
        Write-Log "$PackageName installed successfully via Chocolatey" Green
        return $true
    } else {
        Write-Log "Failed to install $PackageName via Chocolatey after retries" Red
        return $false
    }
}

function Install-WinGetPackage {
    param([string]$PackageId, [string]$PackageName)

    $success = Invoke-WithRetry -ScriptBlock {
        Write-Log "Installing $PackageName via WinGet..." Cyan
        winget install --id $PackageId --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            throw "WinGet installation failed with exit code $LASTEXITCODE"
        }
    } -OperationName "WinGet installation of $PackageName"

    if ($success) {
        Write-Log "$PackageName installed successfully via WinGet" Green
        return $true
    } else {
        Write-Log "Failed to install $PackageName via WinGet after retries" Red
        return $false
    }
}

function Install-Packages {
    param([string]$PackageListPath)

    if (-not (Test-Path $PackageListPath)) {
        Write-Log "Package list not found: $PackageListPath" Red
        return
    }

    $packages = Get-Content $PackageListPath | ConvertFrom-Json
    $chocoAvailable = Get-Command choco -ErrorAction SilentlyContinue
    $wingetAvailable = Test-WinGet

    Write-Log "Found $($packages.Count) packages to install" Cyan
    Write-Log "Chocolatey available: $($null -ne $chocoAvailable)" Gray
    Write-Log "WinGet available: $wingetAvailable" Gray

    # Separate packages that can be installed in parallel vs sequentially
    $sequentialPackages = @()
    $parallelPackages = @()

    foreach ($package in $packages) {
        # Some packages need to be installed sequentially (e.g., those that modify PATH extensively)
        $sequentialIds = @("vscode", "git", "nodejs") # Add more as needed
        if ($package.chocoId -in $sequentialIds -or $package.wingetId -in $sequentialIds) {
            $sequentialPackages += $package
        } else {
            $parallelPackages += $package
        }
    }

    Write-Log "Installing $($parallelPackages.Count) packages in parallel" Cyan
    Write-Log "Installing $($sequentialPackages.Count) packages sequentially" Cyan

    # Install parallel packages
    if ($parallelPackages.Count -gt 0) {
        Install-PackagesParallel -Packages $parallelPackages -ChocoAvailable $chocoAvailable -WinGetAvailable $wingetAvailable
    }

    # Install sequential packages
    foreach ($package in $sequentialPackages) {
        Write-Log "Processing package: $($package.Name)" White

        $installed = $false

        # Try Chocolatey first (primary package manager)
        if ($chocoAvailable -and $package.chocoId) {
            $installed = Install-ChocoPackage -PackageId $package.chocoId -PackageName $package.Name
        }

        # Fallback to WinGet if Chocolatey failed or is not available
        if (-not $installed -and $wingetAvailable -and $package.wingetId) {
            Write-Log "Falling back to WinGet for $($package.Name)" Yellow
            $installed = Install-WinGetPackage -PackageId $package.wingetId -PackageName $package.Name
        }

        if (-not $installed) {
            Write-Log "Failed to install $($package.Name) with any package manager" Red
        }

        Write-Host "" # Empty line for readability
    }
}

function Install-PackagesParallel {
    param(
        [array]$Packages,
        [bool]$ChocoAvailable,
        [bool]$WinGetAvailable
    )

    $jobs = @()

    foreach ($package in $Packages) {
        $job = Start-Job -ScriptBlock {
            param($pkg, $chocoAvail, $wingetAvail)

            function Write-Log {
                param([string]$Message, [ConsoleColor]$Color='White')
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Host "[$timestamp] $Message" -ForegroundColor $Color
            }

            function Invoke-WithRetry {
                param(
                    [ScriptBlock]$ScriptBlock,
                    [int]$MaxRetries = 3,
                    [int]$DelaySeconds = 5,
                    [string]$OperationName = "operation"
                )

                $attempt = 0
                do {
                    $attempt++
                    try {
                        Write-Log "Attempting $OperationName (attempt $attempt/$($MaxRetries + 1))" Gray
                        & $ScriptBlock
                        return $true
                    } catch {
                        Write-Log "Attempt $attempt failed for $OperationName`: $($_.Exception.Message)" Yellow
                        if ($attempt -le $MaxRetries) {
                            Write-Log "Retrying in $DelaySeconds seconds..." Yellow
                            Start-Sleep -Seconds $DelaySeconds
                            $DelaySeconds *= 2  # Exponential backoff
                        }
                    }
                } while ($attempt -le $MaxRetries)

                Write-Log "All retry attempts failed for $OperationName" Red
                return $false
            }

            function Install-ChocoPackage {
                param([string]$PackageId, [string]$PackageName)

                $success = Invoke-WithRetry -ScriptBlock {
                    Write-Log "Installing $PackageName via Chocolatey..." Cyan
                    choco install $PackageId -y --no-progress
                    if ($LASTEXITCODE -ne 0) {
                        throw "Chocolatey installation failed with exit code $LASTEXITCODE"
                    }
                } -OperationName "Chocolatey installation of $PackageName"

                if ($success) {
                    Write-Log "$PackageName installed successfully via Chocolatey" Green
                    return $true
                } else {
                    Write-Log "Failed to install $PackageName via Chocolatey after retries" Red
                    return $false
                }
            }

            function Install-WinGetPackage {
                param([string]$PackageId, [string]$PackageName)

                $success = Invoke-WithRetry -ScriptBlock {
                    Write-Log "Installing $PackageName via WinGet..." Cyan
                    winget install --id $PackageId --silent --accept-package-agreements --accept-source-agreements
                    if ($LASTEXITCODE -ne 0) {
                        throw "WinGet installation failed with exit code $LASTEXITCODE"
                    }
                } -OperationName "WinGet installation of $PackageName"

                if ($success) {
                    Write-Log "$PackageName installed successfully via WinGet" Green
                    return $true
                } else {
                    Write-Log "Failed to install $PackageName via WinGet after retries" Red
                    return $false
                }
            }

            $installed = $false

            # Try Chocolatey first (primary package manager)
            if ($chocoAvail -and $pkg.chocoId) {
                $installed = Install-ChocoPackage -PackageId $pkg.chocoId -PackageName $pkg.Name
            }

            # Fallback to WinGet if Chocolatey failed or is not available
            if (-not $installed -and $wingetAvail -and $pkg.wingetId) {
                Write-Log "Falling back to WinGet for $($pkg.Name)" Yellow
                $installed = Install-WinGetPackage -PackageId $pkg.wingetId -PackageName $pkg.Name
            }

            if (-not $installed) {
                Write-Log "Failed to install $($pkg.Name) with any package manager" Red
            }

            return @{
                PackageName = $pkg.Name
                Success = $installed
            }
        } -ArgumentList $package, $ChocoAvailable, $WinGetAvailable

        $jobs += $job
    }

    # Wait for all jobs to complete and collect results
    $results = $jobs | Wait-Job | Receive-Job

    # Clean up jobs
    $jobs | Remove-Job

    # Log results
    foreach ($result in $results) {
        if ($result.Success) {
            Write-Log "Parallel installation completed: $($result.PackageName)" Green
        } else {
            Write-Log "Parallel installation failed: $($result.PackageName)" Red
        }
    }
}

# Retry function for operations that might fail
function Invoke-WithRetry {
    param(
        [ScriptBlock]$ScriptBlock,
        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 5,
        [string]$OperationName = "operation"
    )

    $attempt = 0
    do {
        $attempt++
        try {
            Write-Log "Attempting $OperationName (attempt $attempt/$($MaxRetries + 1))" Gray
            & $ScriptBlock
            return $true
        } catch {
            Write-Log "Attempt $attempt failed for $OperationName`: $($_.Exception.Message)" Yellow
            if ($attempt -le $MaxRetries) {
                Write-Log "Retrying in $DelaySeconds seconds..." Yellow
                Start-Sleep -Seconds $DelaySeconds
                $DelaySeconds *= 2  # Exponential backoff
            }
        }
    } while ($attempt -le $MaxRetries)

    Write-Log "All retry attempts failed for $OperationName" Red
    return $false
}

# Export functions
Export-ModuleMember -Function Install-Chocolatey, Test-WinGet, Install-ChocoPackage, Install-WinGetPackage, Install-Packages