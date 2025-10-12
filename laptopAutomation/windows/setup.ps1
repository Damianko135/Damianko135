#!/usr/bin/env pwsh
# Windows Laptop Automation Setup Script
# Author: Damian Korver
# Description: Modular setup script that installs packages and configures PowerShell profile

#Requires -Version 5.1

param (
    [switch] $SkipPackages,
    [switch] $SkipProfile,
    [switch] $Force,
    [switch] $SkipOffice,
    [string] $ConfigProfile = "developer",
    [switch] $RestrictedExecution
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Import modules
$modulesPath = Join-Path $PSScriptRoot "modules"
Import-Module (Join-Path $modulesPath "PackageInstaller.psm1")
Import-Module (Join-Path $modulesPath "HardwareDetector.psm1")
Import-Module (Join-Path $modulesPath "SecurityValidator.psm1")
Import-Module (Join-Path $modulesPath "ProgressTracker.psm1")
Import-Module (Join-Path $modulesPath "Windows11Optimizer.psm1")
Import-Module (Join-Path $modulesPath "BackupRestore.psm1")

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

# Setup PowerShell profile
function Set-PowerShellProfile {
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

# Install packages from JSON file
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

# Load configuration profile
function Get-ConfigurationProfile {
    param([string]$ProfileName)

    $configPath = Join-Path $PSScriptRoot "configs\$ProfileName.json"

    if (-not (Test-Path $configPath)) {
        Write-Log "Configuration profile not found: $configPath" Red
        Write-Log "Falling back to minimal profile" Yellow
        $configPath = Join-Path $PSScriptRoot "configs\minimal.json"
    }

    try {
        $config = Get-Content $configPath | ConvertFrom-Json
        Write-Log "Loaded configuration profile: $($config.name)" Green
        return $config
    } catch {
        Write-Log "Failed to load configuration profile: $($_.Exception.Message)" Red
        return $null
    }
}

# Secure credential handling for licensed software
function Get-SecureCredential {
    param([string]$CredentialName, [string]$PromptMessage = "Enter credentials")

    $credFile = Join-Path $env:APPDATA "WindowsAutomation\$CredentialName.xml"

    if (Test-Path $credFile) {
        try {
            $credential = Import-Clixml -Path $credFile
            Write-Log "Loaded stored credentials for $CredentialName" Green
            return $credential
        } catch {
            Write-Log "Failed to load stored credentials: $($_.Exception.Message)" Red
        }
    }

    Write-Log "Prompting for credentials: $PromptMessage" Yellow
    $credential = Get-Credential -Message $PromptMessage

    if ($credential) {
        # Create directory if it doesn't exist
        $credDir = Split-Path $credFile
        if (-not (Test-Path $credDir)) {
            New-Item -ItemType Directory -Path $credDir -Force | Out-Null
        }

        try {
            $credential | Export-Clixml -Path $credFile
            Write-Log "Credentials stored securely for $CredentialName" Green
        } catch {
            Write-Log "Failed to store credentials: $($_.Exception.Message)" Red
        }
    }

    return $credential
}

# Main execution
Write-Log "Starting Windows Laptop Automation Setup" Cyan
Write-Log "Script location: $PSScriptRoot" Gray
Write-Log "Configuration profile: $ConfigProfile" Gray

# Handle restricted execution policy
if ($RestrictedExecution) {
    Write-Log "Running in restricted execution policy mode" Yellow
    try {
        Set-ExecutionPolicy -ExecutionPolicy Restricted -Scope Process -Force
        Write-Log "Execution policy temporarily set to Restricted" Yellow
    } catch {
        Write-Log "Failed to set restricted execution policy: $($_.Exception.Message)" Red
    }
}

# Load configuration
$config = Get-ConfigurationProfile -ProfileName $ConfigProfile
if (-not $config) {
    Write-Log "Failed to load configuration. Exiting." Red
    exit 1
}

# Create backups before making changes
$progressTracker.StartOperation("Creating system backups")
New-SystemRestorePoint -Description "Before Windows Laptop Automation Setup"
$backupPath = Backup-UserConfigurations
$preferencesPath = Export-UserPreferences
Write-Log "Backup created at: $backupPath" Gray
Write-Log "Preferences exported to: $preferencesPath" Gray
$progressTracker.CompleteOperation()

# Initialize progress tracker
$progressTracker = New-ProgressTracker -TotalSteps 6

# Detect hardware
$progressTracker.StartOperation("Detecting hardware specifications")
$systemSpecs = Get-SystemSpecs
$windowsVersion = Get-WindowsVersion
Write-Log "System: $($systemSpecs.Manufacturer) $($systemSpecs.Model)" Gray
Write-Log "Memory: $($systemSpecs.TotalMemoryGB) GB" Gray
Write-Log "Processor: $($systemSpecs.ProcessorName)" Gray
Write-Log "OS: $($windowsVersion.Caption) (Build $($windowsVersion.BuildNumber))" Gray
$progressTracker.CompleteOperation()

# Apply Windows 11 optimizations if applicable
if ($windowsVersion.IsWindows11) {
    $progressTracker.StartOperation("Applying Windows 11 optimizations")
    Enable-Windows11Features
    Set-Windows11Settings
    Optimize-WindowsPackageManager

    # Setup WSL2 if configured in profile
    if ($config.includeWSL) {
        Install-WSL2Integration
    }
    $progressTracker.CompleteOperation()
} else {
    $progressTracker.CurrentStep++ # Skip Windows 11 optimizations
}

# Install packages
if (-not $SkipPackages) {
    # Check admin privileges only when installing packages
    if (-not (Test-IsAdmin)) {
        Write-Log "Package installation requires administrator privileges. Please run as administrator or use -SkipPackages." Red
        exit 1
    }

    $progressTracker.StartOperation("Installing package managers and packages")

    Write-Log "Installing package managers and packages..." Cyan

    # Ensure Chocolatey is installed
    $chocoInstalled = Install-Chocolatey

    if ($chocoInstalled) {
        $packageListPath = Join-Path $PSScriptRoot "packageList.json"
        Install-Packages -PackageListPath $packageListPath

        # Refresh environment variables after package installation
        Write-Log "Refreshing environment variables..." Cyan
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
    } else {
        Write-Log "Cannot proceed without a package manager" Red
        exit 1
    }
    $progressTracker.CompleteOperation()
} else {
    Write-Log "Skipping package installation" Yellow
    $progressTracker.CurrentStep++ # Skip this step
}

# Run office.ps1 if it exists and not skipped
$officeScriptPath = Join-Path $PSScriptRoot "office.ps1"
if (Test-Path $officeScriptPath -and -not $SkipOffice) {
    $progressTracker.StartOperation("Running Office setup script")
    Write-Log "Running Office setup script: $officeScriptPath" Cyan
    try {
        . $officeScriptPath
    } catch {
        Write-Log "Failed to run Office setup script: $($_.Exception.Message)" Red
    }
    $progressTracker.CompleteOperation()
} else {
    if ($SkipOffice) {
        Write-Log "Skipping Office setup script as requested" Yellow
    } else {
        Write-Log "Office setup script not found: $officeScriptPath" Yellow
    }
    $progressTracker.CurrentStep++ # Skip this step
}

# Setup PowerShell profile
if (-not $SkipProfile) {
    $progressTracker.StartOperation("Setting up PowerShell profile")
    Write-Log "Setting up PowerShell profile..." Cyan
    Set-PowerShellProfile
    $progressTracker.CompleteOperation()
} else {
    Write-Log "Skipping PowerShell profile setup" Yellow
    $progressTracker.CurrentStep++ # Skip this step
}

$progressTracker.WriteSummary()
Write-Log "Setup completed successfully!" Green
Write-Log "Please restart your PowerShell session to apply profile changes." Cyan
