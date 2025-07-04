#!/usr/bin/env pwsh
# Windows Environment Setup Script
# Author: Damian Korver
# Description: Orchestrates Windows dev environment setup (package managers, packages, profile)

Set-StrictMode -Version Latest

# ------------------------------
# Utility Functions
# ------------------------------

function Write-Log {
    param(
        [string]$Message,
        [ConsoleColor]$Color = 'White'
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
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

# ------------------------------
# Entry point
# ------------------------------

if (-not (Test-Admin)) { Restart-Elevated }

Write-Log "Starting Windows Environment Setup" Cyan
Write-Log "===================================" Cyan

# ------------------------------
# Run Package Manager Bootstrap
# ------------------------------

$packageManagersScript = Join-Path $PSScriptRoot "packageManagers.ps1"
if (-Not (Test-Path $packageManagersScript)) {
    Write-Log "Missing packageManagers.ps1 script. Cannot continue." Red
    exit 1
}

try {
    & $packageManagersScript
} catch {
    Write-Log "Error during package manager setup: $($_.Exception.Message)" Red
    exit 1
}

# ------------------------------
# Run Package Installation
# ------------------------------

$installPackagesScript = Join-Path $PSScriptRoot "installPackages.ps1"
if (-Not (Test-Path $installPackagesScript)) {
    Write-Log "Missing installPackages.ps1 script. Cannot continue." Red
    exit 1
}

try {
    & $installPackagesScript
} catch {
    Write-Log "Error during package installation: $($_.Exception.Message)" Red
    exit 1
}

# ------------------------------
# Run PowerShell Profile Setup
# ------------------------------

$profileSetupScript = Join-Path $PSScriptRoot "profile.ps1"
if (-Not (Test-Path $profileSetupScript)) {
    Write-Log "Missing profile.ps1 script. Skipping profile setup." Yellow
} else {
    try {
        # Force overwrite profile for idempotency
        & $profileSetupScript -Force
    } catch {
        Write-Log "Error during PowerShell profile setup: $($_.Exception.Message)" Red
    }
}

# ------------------------------
# Final Messages
# ------------------------------

Write-Log "===================================" Cyan
Write-Log "Windows Environment Setup Complete!" Green
Write-Log "💡 Please restart your PowerShell session to apply profile changes." Yellow
Write-Log "💡 Use aliases: ll, gs, gl, gb in your PowerShell sessions." Yellow
Write-Log "Setup finished successfully! 🎉" Green
