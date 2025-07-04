#!/usr/bin/env pwsh
# Package Manager Bootstrap Script (WinGet + Chocolatey)
# Author: Damian Korver
# Description: Ensure package managers are installed and ready

Set-StrictMode -Version Latest

function Write-Log {
    param([string]$Message, [ConsoleColor]$Color='White')
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

function Test-Admin {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
}

if (-not (Test-Admin)) {
    Write-Log "Administrator privileges required. Please run as Administrator." Red
    exit 1
}

function Ensure-WinGet {
    Write-Log "=== Ensuring WinGet ===" Cyan

    if (-not (Get-Module -ListAvailable -Name Microsoft.WinGet.Client)) {
        Write-Log "Installing WinGet PowerShell module..." Yellow
        try {
            Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -Scope AllUsers
            Write-Log "WinGet PowerShell module installed." Green
        } catch {
            Write-Log "Failed to install WinGet PowerShell module: $($_.Exception.Message)" Red
        }
    }

    Import-Module Microsoft.WinGet.Client -ErrorAction SilentlyContinue

    try {
        Repair-WinGetPackageManager -Force
        Write-Log "WinGet repair attempted." Green
    } catch {
        Write-Log "Failed to repair WinGet: $($_.Exception.Message)" Red
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Log "WinGet is functional." Green
    } else {
        Write-Log "WinGet not found. Please install 'App Installer' from Microsoft Store manually." Red
    }
}

function Ensure-Chocolatey {
    Write-Log "=== Ensuring Chocolatey ===" Cyan

    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Log "Installing Chocolatey..." Yellow
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $installScript = Invoke-WebRequest -Uri "https://community.chocolatey.org/install.ps1" -UseBasicParsing
            Invoke-Expression $installScript.Content
            Write-Log "Chocolatey installed successfully." Green
        } catch {
            Write-Log "Failed to install Chocolatey: $($_.Exception.Message)" Red
            return
        }
    } else {
        Write-Log "Chocolatey is already installed." Green
    }

    # Optional Upgrade
    Write-Log "Upgrading Chocolatey to latest version..." Yellow
    try {
        choco upgrade chocolatey -y --no-progress
        Write-Log "Chocolatey upgraded." Green
    } catch {
        Write-Log "Chocolatey upgrade failed: $($_.Exception.Message)" Red
    }
}

Ensure-WinGet
Ensure-Chocolatey

Write-Log "Package managers setup complete!" Green
