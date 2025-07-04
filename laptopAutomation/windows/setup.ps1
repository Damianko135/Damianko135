#!/usr/bin/env pwsh
# Main Windows Development Environment Setup Script
# Author: Damian Korver
# Description: Orchestrates the setup of a complete Windows development environment

Set-StrictMode -Version Latest

function Write-Log {
    param([string]$Message, [ConsoleColor]$Color='White')
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

Write-Log "Starting Windows Environment Setup" Green
Write-Log "===================================" Green

# Ensure we're running as administrator
Write-Log "=== Ensuring Administrator Privileges ===" Yellow
& "$PSScriptRoot\ensureAdmin.ps1"

# Setup package managers
Write-Log "=== Setting up Package Managers ===" Yellow
& "$PSScriptRoot\packageManagers.ps1"

# Install packages
Write-Log "=== Installing Packages ===" Yellow
& "$PSScriptRoot\installPackages.ps1"

# Setup PowerShell profile
Write-Log "=== Setting up PowerShell Profile ===" Yellow
& "$PSScriptRoot\profile.ps1"

Write-Log "Windows Environment Setup Complete!" Green
Write-Log "===================================" Green
