#!/usr/bin/env pwsh
# PowerShell Profile Setup Script
# Author: Damian Korver
# Description: Sets up PowerShell profile with aliases and useful functions

param (
    [switch] $Force,
    [switch] $Append
)

Set-StrictMode -Version Latest

function Write-Log {
    param([string]$Message, [ConsoleColor]$Color='White')
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

# PowerShell profile path for current user
$profilePath = $PROFILE

if (-not (Test-Path (Split-Path $profilePath))) {
    New-Item -ItemType Directory -Path (Split-Path $profilePath) -Force | Out-Null
}

# Load profile content from external file
$profileContentPath = Join-Path $PSScriptRoot "profile-content.txt"

if (-not (Test-Path $profileContentPath)) {
    Write-Log "Profile content file not found: $profileContentPath" Red
    Write-Log "Please ensure profile-content.txt exists in the same directory as this script." Red
    exit 1
}

$profileContent = Get-Content $profileContentPath -Raw

try {
    if ($Force) {
        Write-Log "Writing PowerShell profile (force overwrite): $profilePath" Cyan
        $profileContent | Set-Content -Path $profilePath -Encoding UTF8
    } elseif ($Append) {
        Write-Log "Appending to PowerShell profile: $profilePath" Cyan
        $profileContent | Add-Content -Path $profilePath -Encoding UTF8
    } else {
        if (-not (Test-Path $profilePath)) {
            Write-Log "Profile does not exist. Creating new profile at $profilePath" Cyan
            $profileContent | Set-Content -Path $profilePath -Encoding UTF8
        } else {
            Write-Log "Profile exists. Use -Force to overwrite or -Append to add content." Yellow
        }
    }
} catch {
    Write-Log "Failed to write profile: $($_.Exception.Message)" Red
    exit 1
}

Write-Log "PowerShell profile setup complete." Green
