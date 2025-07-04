#!/usr/bin/env pwsh
# PowerShell Profile Setup Script
# Author: Damian Korver
# Description: Sets up PowerShell profile with aliases and useful functions

Set-StrictMode -Version Latest

param(
    [switch]$Force,
    [switch]$Append
)

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

# Define the profile content to add
$profileContent = @"
# PowerShell Profile setup by Damian Korver

# Enable Windows Console Colors
if ($Host.Name -eq 'ConsoleHost') {
    $Host.UI.RawUI.ForegroundColor = 'White'
    $Host.UI.RawUI.BackgroundColor = 'Black'
    Clear-Host
}

# Git Aliases
Set-Alias gs git status
Set-Alias gb git branch
Set-Alias gl git log
Set-Alias gc git commit
Set-Alias gp git push
Set-Alias gco git checkout

# General Aliases
Set-Alias ll Get-ChildItem

# Network helpers
function myip { Invoke-RestMethod http://ipinfo.io/json | Select-Object -ExpandProperty ip }
function flushdns { ipconfig /flushdns }

# Import posh-git module if installed
if (Get-Module -ListAvailable posh-git) {
    Import-Module posh-git
}

# Custom prompt
function prompt {
    "$(Get-Location)> "
}

"@

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
