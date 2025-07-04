#!/usr/bin/env pwsh
# Elevation script for Windows
# Author: Damian Korver
# Description: Ensures the script is running with Administrator privileges
# ensureAdmin.ps1
param([string]$scriptToRun)

$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')

if ($IsAdmin) {
    Write-Host "Already running with Administrator privileges." -ForegroundColor Green
    exit 0
}

Write-Host "Elevating to Administrator..." -ForegroundColor Yellow

$shell = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh' } else { 'powershell' }

Start-Process -FilePath $shell `
    -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File `"$scriptToRun`"" `
    -Verb RunAs
exit 1
