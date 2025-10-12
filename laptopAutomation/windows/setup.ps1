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
    [switch] $RestrictedExecution,
    [switch] $Interactive,
    [switch] $TestInSandbox,
    [switch] $WhatIf
)

# DEBUG: Script started
Write-Host "DEBUG: Setup script started with WhatIf=$WhatIf" -ForegroundColor Yellow

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
Import-Module (Join-Path $modulesPath "InteractiveMode.psm1")
Import-Module (Join-Path $modulesPath "PluginSystem.psm1")
Import-Module (Join-Path $modulesPath "ContainerSupport.psm1")
Import-Module (Join-Path $modulesPath "ComprehensiveLogging.psm1")
Import-Module (Join-Path $modulesPath "PostInstallSummary.psm1")

# Initialize comprehensive logging
Initialize-Logging -Level "INFO" -ConsoleOutput -FileOutput -StructuredOutput

# Backward compatibility function for modules that still use Write-Log
function global:Write-Log {
    param([string]$Message, [ConsoleColor]$Color = 'White')
    $level = switch ($Color) {
        'Red' { 'ERROR' }
        'Yellow' { 'WARN' }
        'Cyan' { 'INFO' }
        'Green' { 'INFO' }
        'Gray' { 'DEBUG' }
        'White' { 'INFO' }
        default { 'INFO' }
    }
    $category = 'Legacy'
    
    switch ($level) {
        'ERROR' { Write-ErrorLog $Message -Category $category }
        'WARN' { Write-WarnLog $Message -Category $category }
        'DEBUG' { Write-DebugLog $Message -Category $category }
        default { Write-InfoLog $Message -Category $category }
    }
}

# Initialize post-installation summary
Initialize-PostInstallSummary -ProfileName $ConfigProfile

# Set log file paths for summary (use default paths from logging module)
Set-LogFilePaths -LogPath "$env:TEMP\WindowsAutomation.log" -StructuredLogPath "$env:TEMP\WindowsAutomation.json"

# Check if running as administrator
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Setup PowerShell profile
function Set-PowerShellProfile {
    param([switch]$WhatIf)

    $profilePath = $PROFILE
    $profileContentPath = Join-Path $PSScriptRoot "profile-content.ps1"

    if (-not (Test-Path $profileContentPath)) {
        Write-ErrorLog "Profile content file not found: $profileContentPath" -Category "Profile"
        return
    }

    # Create profile directory if it doesn't exist
    $profileDir = Split-Path $profilePath
    if (-not (Test-Path $profileDir)) {
        if ($WhatIf) {
            Write-WarnLog "DRY RUN: Would create profile directory: $profileDir" -Category "Profile"
        } else {
            Write-InfoLog "Creating profile directory: $profileDir" -Category "Profile"
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }
    }

    try {
        $profileContent = Get-Content $profileContentPath -Raw

        if ($WhatIf) {
            if ($Force -or -not (Test-Path $profilePath)) {
                Write-WarnLog "DRY RUN: Would create/update PowerShell profile: $profilePath" -Category "Profile"
            } else {
                Write-WarnLog "DRY RUN: Profile already exists, would skip (use -Force to overwrite)" -Category "Profile"
            }
        } else {
            if ($Force -or -not (Test-Path $profilePath)) {
                Write-InfoLog "Creating PowerShell profile: $profilePath" -Category "Profile"
                $profileContent | Set-Content -Path $profilePath -Encoding UTF8
                Write-InfoLog "PowerShell profile created successfully" -Category "Profile"
                Add-ComponentConfiguration -ComponentName "PowerShell Profile" -Description "Custom PowerShell profile with enhanced functionality" -FilesModified @($profilePath) -Category "Shell"
                Set-RestartRequired -Reason "PowerShell profile changes require session restart"
            } else {
                Write-WarnLog "Profile already exists. Use -Force to overwrite" -Category "Profile"
            }
        }
    } catch {
        Write-ErrorLog "Failed to setup PowerShell profile: $($_.Exception.Message)" -Category "Profile" -Context @{ Error = $_.Exception.Message; ProfilePath = $profilePath }
    }
}

# Install packages from JSON file
function Install-Packages {
    param([string]$PackageListPath, [switch]$WhatIf)

    if (-not (Test-Path $PackageListPath)) {
        Write-ErrorLog "Package list not found: $PackageListPath" -Category "Packages"
        return
    }

    $packages = Get-Content $PackageListPath | ConvertFrom-Json
    $chocoAvailable = Get-Command choco -ErrorAction SilentlyContinue
    $wingetAvailable = Test-WinGet

    Write-InfoLog "Found $($packages.Count) packages to install" -Category "Packages" -Context @{ PackageCount = $packages.Count }
    Write-DebugLog "Chocolatey available: $($null -ne $chocoAvailable)" -Category "Packages"
    Write-DebugLog "WinGet available: $wingetAvailable" -Category "Packages"

    if ($WhatIf) {
        Write-WarnLog "DRY RUN: Would install the following packages:" -Category "Packages"
        foreach ($package in $packages) {
            $packageManager = if ($chocoAvailable -and $package.chocoId) { "Chocolatey" } elseif ($wingetAvailable -and $package.wingetId) { "WinGet" } else { "None available" }
            Write-DebugLog "  - $($package.Name) (via $packageManager)" -Category "Packages"
        }
        return
    }

    foreach ($package in $packages) {
        Write-InfoLog "Processing package: $($package.Name)" -Category "Packages"

        $installed = $false

        # Try Chocolatey first (primary package manager)
        if ($chocoAvailable -and $package.chocoId) {
            $installed = Install-ChocoPackage -PackageId $package.chocoId -PackageName $package.Name
            if ($installed) {
                Add-PackageInstallation -PackageName $package.Name -PackageManager "Chocolatey" -Category "Software"
            }
        }

        # Fallback to WinGet if Chocolatey failed or is not available
        if (-not $installed -and $wingetAvailable -and $package.wingetId) {
            Write-WarnLog "Falling back to WinGet for $($package.Name)" -Category "Packages" -Context @{ PackageName = $package.Name; Manager = "WinGet" }
            $installed = Install-WinGetPackage -PackageId $package.wingetId -PackageName $package.Name
            if ($installed) {
                Add-PackageInstallation -PackageName $package.Name -PackageManager "WinGet" -Category "Software"
            }
        }

        if (-not $installed) {
            Write-ErrorLog "Failed to install $($package.Name) with any package manager" -Category "Packages" -Context @{ PackageName = $package.Name; ChocoId = $package.chocoId; WinGetId = $package.wingetId }
            Add-PackageFailure -PackageName $package.Name -ErrorMessage "Failed to install with any available package manager" -Category "Software"
        }
    }
}

# Load configuration profile
function Get-ConfigurationProfile {
    param([string]$ProfileName)

    $configPath = Join-Path $PSScriptRoot "configs\$ProfileName.json"

    if (-not (Test-Path $configPath)) {
        Write-ErrorLog "Configuration profile not found: $configPath" -Category "Configuration"
        Write-WarnLog "Falling back to minimal profile" -Category "Configuration"
        $configPath = Join-Path $PSScriptRoot "configs\minimal.json"
    }

    try {
        $config = Get-Content $configPath | ConvertFrom-Json
        Write-InfoLog "Loaded configuration profile: $($config.name)" -Category "Configuration" -Context @{ ProfileName = $config.name; ConfigPath = $configPath }
        return $config
    } catch {
        Write-ErrorLog "Failed to load configuration profile: $($_.Exception.Message)" -Category "Configuration" -Context @{ ConfigPath = $configPath; Error = $_.Exception.Message }
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
            Write-InfoLog "Loaded stored credentials for $CredentialName" -Category "Credentials"
            return $credential
        } catch {
            Write-ErrorLog "Failed to load stored credentials: $($_.Exception.Message)" -Category "Credentials" -Context @{ CredentialName = $CredentialName; Error = $_.Exception.Message }
        }
    }

    Write-WarnLog "Prompting for credentials: $PromptMessage" -Category "Credentials"
    $credential = Get-Credential -Message $PromptMessage

    if ($credential) {
        # Create directory if it doesn't exist
        $credDir = Split-Path $credFile
        if (-not (Test-Path $credDir)) {
            New-Item -ItemType Directory -Path $credDir -Force | Out-Null
        }

        try {
            $credential | Export-Clixml -Path $credFile
            Write-InfoLog "Credentials stored securely for $CredentialName" -Category "Credentials" -Context @{ CredentialName = $CredentialName }
        } catch {
            Write-ErrorLog "Failed to store credentials: $($_.Exception.Message)" -Category "Credentials" -Context @{ CredentialName = $CredentialName; Error = $_.Exception.Message }
        }
    }

    return $credential
}

# Main execution
Write-InfoLog "Starting Windows Laptop Automation Setup" -Category "Setup"
Write-DebugLog "Script location: $PSScriptRoot" -Category "Setup"
Write-DebugLog "Configuration profile: $ConfigProfile" -Category "Setup"

# Handle WhatIf mode
if ($WhatIf) {
    Write-WarnLog "DRY RUN MODE - No changes will be made to your system" -Category "Setup"
    Write-WarnLog "This preview shows what would be installed and configured" -Category "Setup"
}

# Handle sandbox testing mode
if ($TestInSandbox) {
    Write-WarnLog "Sandbox testing mode enabled" -Category "Sandbox"

    if (-not (Test-WindowsSandbox)) {
        Write-ErrorLog "Windows Sandbox is not available. Cannot run in sandbox mode." -Category "Sandbox"
        Write-WarnLog "Make sure Windows Sandbox is enabled in Windows Features." -Category "Sandbox"
        exit 1
    }

    Write-InfoLog "Creating sandbox test configuration..." -Category "General"
    $sandboxConfig = New-AutomationTestSandbox -ProjectPath $PSScriptRoot `
                                             -ConfigProfile $ConfigProfile `
                                             -EnableNetworking `
                                             -SkipPackages:$SkipPackages `
                                             -SkipProfile:$SkipProfile

    if ($sandboxConfig) {
        Write-InfoLog "Starting Windows Sandbox for testing..." -Category "General"
        Write-WarnLog "The automation will run in the sandbox environment" -Category "General"
        Write-InfoLog "Close the sandbox window when testing is complete" -Category "General"

        Start-WindowsSandbox -ConfigPath $sandboxConfig -Wait

        Write-InfoLog "Sandbox testing completed" -Category "General"
        exit 0
    } else {
        Write-ErrorLog "Failed to create sandbox configuration" -Category "General"
        exit 1
    }
}

# Handle restricted execution policy
if ($RestrictedExecution) {
    Write-WarnLog "Running in restricted execution policy mode" -Category "General"
    try {
        Set-ExecutionPolicy -ExecutionPolicy Restricted -Scope Process -Force
        Write-WarnLog "Execution policy temporarily set to Restricted" -Category "General"
    } catch {
        Write-ErrorLog "Failed to set restricted execution policy: $($_.Exception.Message)" -Category "General"
    }
}

# Load configuration
$config = if ($Interactive) {
    Write-InfoLog "Interactive mode enabled - loading available packages..." -Category "General"
    $availablePackages = Get-AvailablePackages -PackageListPath (Join-Path $PSScriptRoot "packageList.json")

    # Start with developer profile as base
    $baseConfig = Get-ConfigurationProfile -ProfileName "developer"
    if (-not $baseConfig) {
        $baseConfig = @{
            packages = @()
            includeOffice = $false
            includeWSL = $false
            skipHeavyPackages = $false
        }
    }

    Show-InteractiveMenu -AvailablePackages $availablePackages -CurrentConfig $baseConfig
} else {
    Get-ConfigurationProfile -ProfileName $ConfigProfile
}

if (-not $config) {
    Write-ErrorLog "Failed to load configuration. Exiting." -Category "General"
    exit 1
}

# Initialize progress tracker
# $progressTracker = New-ProgressTracker -TotalSteps 8

# Initialize plugin system
# # $progressTracker.StartOperation("Initializing plugin system")
$pluginsPath = Join-Path $PSScriptRoot "plugins"
$loadedPlugins = Initialize-PluginSystem -PluginsPath $pluginsPath
Write-InfoLog "Loaded $($loadedPlugins.Count) plugins" -Category "General"
# $progressTracker.CompleteOperation()

# Create backups before making changes
# $progressTracker.StartOperation("Creating system backups")
if ($WhatIf) {
    Write-WarnLog "DRY RUN: Would create system restore point" -Category "General"
    Write-WarnLog "DRY RUN: Would backup user configurations" -Category "General"
    Write-WarnLog "DRY RUN: Would export user preferences" -Category "General"
} else {
    New-SystemRestorePoint -Description "Before Windows Laptop Automation Setup"
    $backupPath = Backup-UserConfigurations
    $preferencesPath = Export-UserPreferences
    Write-DebugLog "Backup created at: $backupPath" -Category "General"
    Write-DebugLog "Preferences exported to: $preferencesPath" -Category "General"
    Add-BackupLocation -BackupPath $backupPath -Description "User configurations backup"
    Add-BackupLocation -BackupPath $preferencesPath -Description "User preferences export"
    Add-ComponentConfiguration -ComponentName "System Backup" -Description "System restore point and configuration backup" -Category "Backup"
}
# $progressTracker.CompleteOperation()

# Detect hardware
# $progressTracker.StartOperation("Detecting hardware specifications")
$systemSpecs = Get-SystemSpecs
$windowsVersion = Get-WindowsVersion
Write-DebugLog "System: $($systemSpecs.Manufacturer) $($systemSpecs.Model)" -Category "General"
Write-DebugLog "Memory: $($systemSpecs.TotalMemoryGB) GB" -Category "General"
Write-DebugLog "Processor: $($systemSpecs.ProcessorName)" -Category "General"
Write-DebugLog "OS: $($windowsVersion.Caption) (Build $($windowsVersion.BuildNumber))" -Category "General"
# $progressTracker.CompleteOperation()

# Apply Windows 11 optimizations if applicable
if ($windowsVersion.IsWindows11) {
    # $progressTracker.StartOperation("Applying Windows 11 optimizations")
    if ($WhatIf) {
        Write-WarnLog "DRY RUN: Would enable Windows 11 features" -Category "General"
        Write-WarnLog "DRY RUN: Would set Windows 11 settings" -Category "General"
        Write-WarnLog "DRY RUN: Would optimize Windows Package Manager" -Category "General"
        if ($config.includeWSL) {
            Write-WarnLog "DRY RUN: Would install WSL2 integration" -Category "General"
        }
    } else {
        Enable-Windows11Features
        Set-Windows11Settings
        Optimize-WindowsPackageManager

        # Setup WSL2 if configured in profile
        if ($config.includeWSL) {
            Install-WSL2Integration
        }

        Add-ComponentConfiguration -ComponentName "Windows 11 Optimizations" -Description "Enabled Windows 11 features, settings, and package manager optimizations" -Category "System"
        if ($config.includeWSL) {
            Add-ComponentConfiguration -ComponentName "WSL2 Integration" -Description "Windows Subsystem for Linux 2 integration" -Category "Development"
        }
    }
    # $progressTracker.CompleteOperation()
} else {
    # $progressTracker.CurrentStep++ # Skip Windows 11 optimizations
}

# Install packages
if (-not $SkipPackages) {
    # Check admin privileges only when installing packages
    if (-not (Test-IsAdmin)) {
        Write-ErrorLog "Package installation requires administrator privileges. Please run as administrator or use -SkipPackages." -Category "General"
        exit 1
    }

    # $progressTracker.StartOperation("Installing package managers and packages")

    Write-InfoLog "Installing package managers and packages..." -Category "General"

    # Ensure Chocolatey is installed
    $chocoInstalled = Install-Chocolatey

    if ($chocoInstalled) {
        $packageListPath = Join-Path $PSScriptRoot "packageList.json"
        Install-Packages -PackageListPath $packageListPath -WhatIf:$WhatIf

        # Refresh environment variables after package installation
        Write-InfoLog "Refreshing environment variables..." -Category "General"
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
    } else {
        Write-ErrorLog "Cannot proceed without a package manager" -Category "General"
        exit 1
    }
    # $progressTracker.CompleteOperation()
} else {
    Write-WarnLog "Skipping package installation" -Category "General"
    # $progressTracker.CurrentStep++ # Skip this step
}

# Run office.ps1 if it exists and not skipped
$officeScriptPath = Join-Path $PSScriptRoot "office.ps1"
if ((Test-Path $officeScriptPath) -and -not $SkipOffice) {
    # $progressTracker.StartOperation("Running Office setup script")
    Write-InfoLog "Running Office setup script: $officeScriptPath" -Category "General"
    try {
        . $officeScriptPath
    } catch {
        Write-ErrorLog "Failed to run Office setup script: $($_.Exception.Message)" -Category "General"
    }
    # $progressTracker.CompleteOperation()
} else {
    if ($SkipOffice) {
        Write-WarnLog "Skipping Office setup script as requested" -Category "General"
    } else {
        Write-WarnLog "Office setup script not found: $officeScriptPath" -Category "General"
    }
    # $progressTracker.CurrentStep++ # Skip this step
}

# Setup PowerShell profile
if (-not $SkipProfile) {
    # $progressTracker.StartOperation("Setting up PowerShell profile")
    Write-InfoLog "Setting up PowerShell profile..." -Category "General"
    Set-PowerShellProfile -WhatIf:$WhatIf
    # $progressTracker.CompleteOperation()
} else {
    Write-WarnLog "Skipping PowerShell profile setup" -Category "General"
    # $progressTracker.CurrentStep++ # Skip this step
}

# Execute plugins
if ($loadedPlugins.Count -gt 0) {
    # $progressTracker.StartOperation("Executing plugins")
    if ($WhatIf) {
        Write-WarnLog "DRY RUN: Would execute $($loadedPlugins.Count) plugins:" -Category "General"
        foreach ($plugin in $loadedPlugins) {
            Write-DebugLog "  - $($plugin.Name): $($plugin.Description)" -Category "General"
        }
    } else {
        Write-InfoLog "Executing $($loadedPlugins.Count) plugins..." -Category "General"
        foreach ($plugin in $loadedPlugins) {
            try {
                Write-InfoLog "Executing plugin: $($plugin.Name)" -Category "General"
                Invoke-Plugin -Plugin $plugin -SystemSpecs $systemSpecs -WindowsVersion $windowsVersion -Config $config
            } catch {
                Write-ErrorLog "Failed to execute plugin $($plugin.Name): $($_.Exception.Message)" -Category "General"
            }
        }
    }
    # $progressTracker.CompleteOperation()
} else {
    Write-DebugLog "No plugins to execute" -Category "General"
    # $progressTracker.CurrentStep++ # Skip this step
}

# $progressTracker.WriteSummary()

if ($WhatIf) {
    Write-WarnLog "DRY RUN COMPLETED - No changes were made to your system" -Category "General"
    Write-InfoLog "Run without -WhatIf to apply these changes" -Category "General"
} else {
    # Finalize and display post-installation summary
    Complete-PostInstallSummary
    Show-PostInstallSummary
}

