#!/usr/bin/env pwsh
# Package Installation Script
# Author : Damian Korver
# Description : Install packages listed in packageList.json using WinGet or Chocolatey as fallback

Set-StrictMode -Version Latest

function Write-Log {
    param([string]$Message, [ConsoleColor]$Color='White')
    $timestamp = Get-Date -Format "yyyy-MM-dd HH :mm :ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

function Test-Admin {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
}

function Restart-Elevated {
    $argsList = "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`""
    Write-Log "Restarting script with Administrator privileges..." Yellow
    Start-Process pwsh -ArgumentList $argsList -Verb RunAs
    exit
}

if (-not (Test-Admin)) { Restart-Elevated }

# Load package list
$packagesFile = Join-Path $PSScriptRoot "packageList.json"
if (-not (Test-Path $packagesFile)) {
    Write-Log "Packages file missing : $packagesFile" Red
    exit 1
}

try {
    $packagesJson = Get-Content -Raw -Path $packagesFile
    $packages = $packagesJson | ConvertFrom-Json
} catch {
    Write-Log "Failed to parse package list JSON : $($_.Exception.Message)" Red
    exit 1
}

if (-not $packages -or $packages.Count -eq 0) {
    Write-Log "No packages found in the package list." Yellow
    exit 0
}

# Detect availability of package managers
$WinGetAvailable = (Get-Command winget -ErrorAction SilentlyContinue) -ne $null
$ChocoAvailable = (Get-Command choco -ErrorAction SilentlyContinue) -ne $null

function Install-WinGetPackage {
    param([string]$packageId)
    try {
        Write-Log "Attempting winget install : $packageId" Cyan
        # Use -e for exact match, accept agreements, silent mode
        winget install --id=$packageId --accept-source-agreements --accept-package-agreements --silent -e
        Write-Log "Successfully installed $packageId via winget." Green
        return $true
    } catch {
        Write-Log "winget installation failed for $packageId : $($_.Exception.Message)" Red
        return $false
    }
}

function Install-ChocoPackage {
    param([string]$packageName)
    try {
        Write-Log "Attempting choco install : $packageName" Cyan
        choco install $packageName -y --no-progress --ignore-checksums
        Write-Log "Successfully installed $packageName via Chocolatey." Green
        return $true
    } catch {
        Write-Log "Chocolatey installation failed for $packageName : $($_.Exception.Message)" Red
        return $false
    }
}

foreach ($pkg in $packages) {
    $name = $pkg.Name
    $wingetId = $pkg.wingetId
    $chocoId = $pkg.chocoId

    Write-Log "Installing package : $name"

    $installed = $false

    if ($wingetId -and $WinGetAvailable) {
        $installed = Install-WinGetPackage -packageId $wingetId
        if (-not $installed -and $chocoId -and $ChocoAvailable) {
            Write-Log "winget install failed; falling back to Chocolatey for $name." Yellow
            $installed = Install-ChocoPackage -packageName $chocoId
        }
    } elseif ($chocoId -and $ChocoAvailable) {
        $installed = Install-ChocoPackage -packageName $chocoId
    } else {
        Write-Log "No valid package manager or IDs available for $name; skipping." Yellow
    }

    if (-not $installed) {
        Write-Log "Failed to install package $name." Red
    }
}

Write-Log "Package installation completed." Green
