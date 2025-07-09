#!/usr/bin/env pwsh
# Windows Laptop Automation Setup Script
# Author: Damian Korver
# Description: Minimal setup script that installs packages and configures PowerShell profile

#Requires -Version 5.1

param (
    [switch] $SkipPackages,
    [switch] $SkipProfile,
    [switch] $Force,
    [switch] $SkipOffice
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Logging function
function Write-Log {
    param([string]$Message, [ConsoleColor]$Color='White')
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

# Check if running as administrator
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Install Chocolatey if not present
function Install-Chocolatey {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Log "Chocolatey is already installed" Green
        return $true
    }
    
    try {
        Write-Log "Installing Chocolatey..." Cyan
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Refresh environment variables
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
        
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Log "Chocolatey installed successfully" Green
            return $true
        } else {
            Write-Log "Chocolatey installation failed" Red
            return $false
        }
    } catch {
        Write-Log "Failed to install Chocolatey: $($_.Exception.Message)" Red
        return $false
    }
}

# Check if WinGet is available
function Test-WinGet {
    try {
        $null = Get-Command winget -ErrorAction Stop
        return $true
    } catch {
        Write-Log "WinGet not available" Yellow
        return $false
    }
}

# Install package using Chocolatey
function Install-ChocoPackage {
    param([string]$PackageId, [string]$PackageName)
    
    try {
        Write-Log "Installing $PackageName via Chocolatey..." Cyan
        choco install $PackageId -y --no-progress
        Write-Log "$PackageName installed successfully via Chocolatey" Green
        return $true
    } catch {
        Write-Log "Failed to install $PackageName via Chocolatey: $($_.Exception.Message)" Red
        return $false
    }
}

# Install package using WinGet
function Install-WinGetPackage {
    param([string]$PackageId, [string]$PackageName)
    
    try {
        Write-Log "Installing $PackageName via WinGet..." Cyan
        winget install --id $PackageId --silent --accept-package-agreements --accept-source-agreements
        Write-Log "$PackageName installed successfully via WinGet" Green
        return $true
    } catch {
        Write-Log "Failed to install $PackageName via WinGet: $($_.Exception.Message)" Red
        return $false
    }
}

# Install packages from JSON file
function Install-Packages {
    $packageListPath = Join-Path $PSScriptRoot "packageList.json"
    
    if (-not (Test-Path $packageListPath)) {
        Write-Log "Package list not found: $packageListPath" Red
        return
    }
    
    $packages = Get-Content $packageListPath | ConvertFrom-Json
    $chocoAvailable = Get-Command choco -ErrorAction SilentlyContinue
    $wingetAvailable = Test-WinGet
    
    Write-Log "Found $($packages.Count) packages to install" Cyan
    Write-Log "Chocolatey available: $($chocoAvailable -ne $null)" Gray
    Write-Log "WinGet available: $wingetAvailable" Gray
    
    foreach ($package in $packages) {
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

# Setup PowerShell profile
function Setup-PowerShellProfile {
    $profilePath = $PROFILE
    $profileContentPath = Join-Path $PSScriptRoot "profile-content.ps1"
    
    if (-not (Test-Path $profileContentPath)) {
        Write-Log "Profile content file not found: $profileContentPath" Red
        return
    }
    
    # Create profile directory if it doesn't exist
    $profileDir = Split-Path $profilePath
    if (-not (Test-Path $profileDir)) {
        Write-Log "Creating profile directory: $profileDir" Cyan
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    
    try {
        $profileContent = Get-Content $profileContentPath -Raw
        
        if ($Force -or -not (Test-Path $profilePath)) {
            Write-Log "Creating PowerShell profile: $profilePath" Cyan
            $profileContent | Set-Content -Path $profilePath -Encoding UTF8
            Write-Log "PowerShell profile created successfully" Green
        } else {
            Write-Log "Profile already exists. Use -Force to overwrite" Yellow
        }
    } catch {
        Write-Log "Failed to setup PowerShell profile: $($_.Exception.Message)" Red
    }
}

# Main execution
Write-Log "Starting Windows Laptop Automation Setup" Cyan
Write-Log "Script location: $PSScriptRoot" Gray

# Install packages
if (-not $SkipPackages) {
    # Check admin privileges only when installing packages
    if (-not (Test-IsAdmin)) {
        Write-Log "Package installation requires administrator privileges. Please run as administrator or use -SkipPackages." Red
        exit 1
    }
    
    Write-Log "Installing package managers and packages..." Cyan
    
    # Ensure Chocolatey is installed
    $chocoInstalled = Install-Chocolatey
    
    if ($chocoInstalled) {
        Install-Packages
    } else {
        Write-Log "Cannot proceed without a package manager" Red
        exit 1
    }
} else {
    Write-Log "Skipping package installation" Yellow 
}

# Run office.ps1 if it exists
$officeScriptPath = Join-Path $PSScriptRoot "office.ps1"    
if (Test-Path $officeScriptPath ) {
    # Test if not wanted with the -SkipOffice switch
    if ($SkipOffice) {
        Write-Log "Skipping Office setup script as requested" Yellow
        return
    }
    Write-Log "Running Office setup script: $officeScriptPath" Cyan
    try {
        . $officeScriptPath
    } catch {
        Write-Log "Failed to run Office setup script: $($_.Exception.Message)" Red
    }
} else {
    Write-Log "Office setup script not found: $officeScriptPath" Yellow
}

# Setup PowerShell profile
if (-not $SkipProfile) {
    Write-Log "Setting up PowerShell profile..." Cyan
    Setup-PowerShellProfile
} else {
    Write-Log "Skipping PowerShell profile setup" Yellow
}

Write-Log "Setup completed successfully!" Green
Write-Log "Please restart your PowerShell session to apply profile changes." Cyan
