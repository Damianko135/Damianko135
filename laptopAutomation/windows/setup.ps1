#!/usr/bin/env pwsh
# Main Windows Development Environment Setup Script
# Author: Damian Korver
# Description: Orchestrates the setup of a complete Windows development environment

param(
    [ValidateSet('WinGet', 'Chocolatey')]
    [string]$PackageManager = 'WinGet',
    
    [ValidateSet('Essential', 'Languages', 'DevTools', 'Utilities', 'Browsers', 'Communication', 'Media', 'Cloud', 'Gaming')]
    [string[]]$Categories = @('Essential'),
    
    [switch]$SkipPackages,
    [switch]$SkipGitConfig,
    [switch]$SkipProfileConfig,
    [switch]$Interactive,
    [switch]$Help
)

function Show-Help {
    $helpText = @"
Windows Development Environment Setup Script
===========================================

This script automates the setup of a complete Windows development environment.

USAGE:
    .\setup.ps1 [PARAMETERS]

PARAMETERS:
    -PackageManager <WinGet|Chocolatey>    Package manager to use (default: WinGet)
    -Categories <array>                    Package categories to install (default: Essential)
    -SkipPackages                          Skip package installation
    -SkipGitConfig                        Skip Git configuration
    -SkipProfileConfig                    Skip PowerShell profile setup
    -Interactive                          Show interactive menus for all choices
    -Help                                 Show this help message

EXAMPLES:
    .\setup.ps1
    .\setup.ps1 -Interactive
    .\setup.ps1 -PackageManager Chocolatey -Categories Essential,DevTools
    .\setup.ps1 -SkipPackages -SkipGitConfig

PACKAGE CATEGORIES:
    Essential      Core development tools (Git, VS Code, Terminal, PowerShell)
    Languages      Programming languages and runtimes
    DevTools       Development utilities (Docker, GitHub Desktop, etc.)
    Utilities      General utilities (7-Zip, Notepad++, etc.)
    Browsers       Web browsers
    Communication  Team tools (Teams, Discord, Slack)
    Media          Media tools (VLC, OBS, GIMP)
    Cloud          Cloud storage solutions
    Gaming         Gaming platforms

"@
    Write-Host $helpText
}

function Get-InteractivePackageManager {
    $options = @(
        @{ Name = 'WinGet'; Description = 'Microsoft Windows Package Manager (Recommended)'; Color = 'Green' },
        @{ Name = 'Chocolatey'; Description = 'Community Package Manager'; Color = 'Yellow' }
    )
    
    Write-Host "Select package manager:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $options.Count; $i++) {
        $option = $options[$i]
        $color = if ($option.Color) {
            $option.Color 
        }
        else {
            'White' 
        }
        Write-Host "$(($i + 1)). $($option.Name)" -ForegroundColor $color
        if ($option.Description) {
            Write-Host "   $($option.Description)" -ForegroundColor Gray
        }
    }
    
    do {
        $choice = Read-Host "Enter your choice (1-$($options.Count))"
        $choiceNum = 0
        $validChoice = [int]::TryParse($choice, [ref]$choiceNum)
        
        if (-not $validChoice) {
            Write-Host 'Please enter a valid number.' -ForegroundColor Red
            continue
        }
        
        if ($choiceNum -lt 1 -or $choiceNum -gt $options.Count) {
            Write-Host "Please enter a number between 1 and $($options.Count)." -ForegroundColor Red
        }
    } while (-not $validChoice -or $choiceNum -lt 1 -or $choiceNum -gt $options.Count)
    
    return $options[$choiceNum - 1].Name
}

function Get-InteractiveCategories {
    $options = @(
        @{ Name = 'Essential'; Description = 'Core development tools (Git, VS Code, Terminal)' },
        @{ Name = 'Languages'; Description = 'Programming languages and runtimes' },
        @{ Name = 'DevTools'; Description = 'Development utilities (Docker, GitHub Desktop)' },
        @{ Name = 'Utilities'; Description = 'General utilities (7-Zip, Notepad++)' },
        @{ Name = 'Browsers'; Description = 'Web browsers (Firefox, Chrome)' },
        @{ Name = 'Communication'; Description = 'Team tools (Teams, Discord, Slack)' },
        @{ Name = 'Media'; Description = 'Media tools (VLC, OBS, GIMP)' },
        @{ Name = 'Cloud'; Description = 'Cloud storage (OneDrive, Google Drive)' },
        @{ Name = 'Gaming'; Description = 'Gaming platforms (Steam, Epic Games)' }
    )
    
    Write-Host "Select package categories to install (multiple allowed):" -ForegroundColor Yellow
    $selectedCategories = @()
    
    foreach ($option in $options) {
        $prompt = "Install $($option.Name)? ($($option.Description))"
        $choice = Read-Host "$prompt (y/N)"
        if ($choice -match '^[Yy]') {
            $selectedCategories += $option.Name
        }
    }
    
    if ($selectedCategories.Count -eq 0) {
        Write-Host "No categories selected, defaulting to Essential" -ForegroundColor Yellow
        return @('Essential')
    }
    
    return $selectedCategories
}

function Main {
    # Show help if requested
    if ($Help) {
        Show-Help
        return
    }
    
    # Import required modules first
    $ScriptRoot = $PSScriptRoot
    $requiredModules = @(
        'Core.psm1',
        'WinGet.psm1', 
        'Chocolatey.psm1',
        'Configuration.psm1'
    )
    
    Write-Host "Loading required modules..." -ForegroundColor Gray
    
    foreach ($module in $requiredModules) {
        $modulePath = Join-Path $ScriptRoot "modules\$module"
        
        if (-not (Test-Path $modulePath)) {
            Write-Host "Module not found: $modulePath" -ForegroundColor Red
            exit 1
        }
        
        try {
            Import-Module $modulePath -Force -Scope Global -ErrorAction Stop
            Write-Host "✓ Loaded: $module" -ForegroundColor Green
        } 
        catch {
            Write-Host "✗ Failed to load $module : $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    }
    
    # Check for Administrator privileges
    Assert-Administrator
    
    # Show banner
    Show-Banner -Title "Windows Development Environment Setup" -Subtitle "Automated setup script by Damian Korver"
    
    # Interactive mode
    if ($Interactive) {
        Write-Host "Interactive Setup Mode" -ForegroundColor Cyan
        Write-Host "====================" -ForegroundColor Cyan
        
        $PackageManager = Get-InteractivePackageManager
        $Categories = Get-InteractiveCategories
        
        $skipPackages = (Read-Host "Skip package installation? (y/N)") -match '^[Yy]'
        $skipGitConfig = (Read-Host "Skip Git configuration? (y/N)") -match '^[Yy]'
        $skipProfileConfig = (Read-Host "Skip PowerShell profile setup? (y/N)") -match '^[Yy]'
        
        $SkipPackages = $skipPackages
        $SkipGitConfig = $skipGitConfig
        $SkipProfileConfig = $skipProfileConfig
    }
    
    # Create log file
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $logFile = "$env:TEMP\dev-setup-$timestamp.log"
    
    Write-Host "Setup started at $(Get-Date)" | Tee-Object -FilePath $logFile -Append
    Write-Host "Selected package manager: $PackageManager" | Tee-Object -FilePath $logFile -Append
    Write-Host "Selected categories: $($Categories -join ', ')" | Tee-Object -FilePath $logFile -Append
    
    # Initialize development folders
    Write-Host "`nInitializing development environment..." -ForegroundColor Cyan
    Initialize-DevelopmentFolders | Tee-Object -FilePath $logFile -Append
    
    # Install packages if not skipped
    if (-not $SkipPackages) {
        Write-Host "`nInstalling packages..." -ForegroundColor Cyan
        
        switch ($PackageManager.ToLower()) {
            'winget' {
                & "$ScriptRoot\packages\Install-WinGet.ps1" -Categories $Categories | Tee-Object -FilePath $logFile -Append
            }
            'chocolatey' {
                & "$ScriptRoot\packages\Install-Chocolatey.ps1" -Categories $Categories | Tee-Object -FilePath $logFile -Append
            }
        }
    }
    else {
        Write-Host "Package installation skipped" -ForegroundColor Yellow | Tee-Object -FilePath $logFile -Append
    }
    
    # Configure Git if not skipped
    if (-not $SkipGitConfig) {
        Write-Host "`nConfiguring Git..." -ForegroundColor Cyan
        & "$ScriptRoot\config\Configure-Git.ps1" | Tee-Object -FilePath $logFile -Append
    }
    else {
        Write-Host "Git configuration skipped" -ForegroundColor Yellow | Tee-Object -FilePath $logFile -Append
    }
    
    # Configure PowerShell profiles if not skipped
    if (-not $SkipProfileConfig) {
        Write-Host "`nConfiguring PowerShell profiles..." -ForegroundColor Cyan
        & "$ScriptRoot\config\Configure-PowerShell.ps1" | Tee-Object -FilePath $logFile -Append
    }
    else {
        Write-Host "PowerShell profile configuration skipped" -ForegroundColor Yellow | Tee-Object -FilePath $logFile -Append
    }
    
    # Set environment variables
    Write-Host "`nConfiguring environment variables..." -ForegroundColor Cyan
    Set-EnvironmentVariables | Tee-Object -FilePath $logFile -Append
    
    # Completion
    Write-Host ("`n" + ("=" * 60)) -ForegroundColor Green
    Write-Host "🎉 Setup completed successfully!" -ForegroundColor Green
    Write-Host "Log file saved to: $logFile" -ForegroundColor Gray
    Write-Host "`nRecommended next steps:" -ForegroundColor Cyan
    Write-Host "1. Restart your terminal to apply profile changes" -ForegroundColor White
    Write-Host "2. Configure additional Git settings if needed" -ForegroundColor White
    Write-Host "3. Install additional VS Code extensions" -ForegroundColor White
    Write-Host ("=" * 60) -ForegroundColor Green
}

# Run main function
Main
