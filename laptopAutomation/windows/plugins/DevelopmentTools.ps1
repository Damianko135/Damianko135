#!/usr/bin/env pwsh
# DevelopmentTools Plugin
# Installs additional development tools and utilities

param(
    [Parameter(Mandatory=$true)]
    [PSCustomObject]$Plugin,

    [Parameter(Mandatory=$true)]
    [PSCustomObject]$SystemSpecs,

    [Parameter(Mandatory=$true)]
    [PSCustomObject]$WindowsVersion,

    [Parameter(Mandatory=$true)]
    [PSCustomObject]$Config
)

# Plugin execution logic
function Invoke-PluginExecution {
    Write-Host "Executing DevelopmentTools plugin v$($Plugin.version)" -ForegroundColor Cyan

    # Check if we're on a supported platform
    if ($Plugin.platforms -notcontains "Windows") {
        Write-Host "Plugin not supported on this platform" -ForegroundColor Yellow
        return
    }

    # Check Windows version requirement
    if ([version]$WindowsVersion.Version -lt [version]$Plugin.minWindowsVersion) {
        Write-Host "Plugin requires Windows $($Plugin.minWindowsVersion) or higher" -ForegroundColor Yellow
        return
    }

    # Install Git extensions if enabled
    if ($Plugin.parameters.installGitExtensions) {
        Write-Host "Installing Git extensions..." -ForegroundColor Cyan

        # Install Git LFS
        try {
            choco install git-lfs -y
            Write-Host "Git LFS installed successfully" -ForegroundColor Green
        } catch {
            Write-Host "Failed to install Git LFS: $($_.Exception.Message)" -ForegroundColor Red
        }

        # Install GitHub CLI
        try {
            choco install gh -y
            Write-Host "GitHub CLI installed successfully" -ForegroundColor Green
        } catch {
            Write-Host "Failed to install GitHub CLI: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # Install Docker tools if enabled
    if ($Plugin.parameters.installDockerTools) {
        Write-Host "Installing Docker tools..." -ForegroundColor Cyan

        # Install Docker Desktop
        try {
            choco install docker-desktop -y
            Write-Host "Docker Desktop installed successfully" -ForegroundColor Green
        } catch {
            Write-Host "Failed to install Docker Desktop: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # Install cloud tools if enabled
    if ($Plugin.parameters.installCloudTools) {
        Write-Host "Installing cloud development tools..." -ForegroundColor Cyan

        # Install Azure CLI
        try {
            choco install azure-cli -y
            Write-Host "Azure CLI installed successfully" -ForegroundColor Green
        } catch {
            Write-Host "Failed to install Azure CLI: $($_.Exception.Message)" -ForegroundColor Red
        }

        # Install AWS CLI
        try {
            choco install awscli -y
            Write-Host "AWS CLI installed successfully" -ForegroundColor Green
        } catch {
            Write-Host "Failed to install AWS CLI: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # Install additional development utilities
    Write-Host "Installing additional development utilities..." -ForegroundColor Cyan

    $additionalPackages = @(
        "vscode-insiders",  # VS Code Insiders
        "postman",          # API testing tool
        "insomnia-rest-api-client",  # Alternative API client
        "dbeaver",          # Database management tool
        "winmerge",         # File comparison tool
        "notepadplusplus",  # Enhanced text editor
        "7zip",             # File archiver
        "sysinternals",     # System utilities
        "processhacker",    # Process manager
        "wireshark"         # Network protocol analyzer
    )

    foreach ($package in $additionalPackages) {
        try {
            Write-Host "Installing $package..." -ForegroundColor Gray
            choco install $package -y
            Write-Host "$package installed successfully" -ForegroundColor Green
        } catch {
            Write-Host "Failed to install $package`: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host "DevelopmentTools plugin execution completed" -ForegroundColor Green
}

# Execute the plugin
Invoke-PluginExecution