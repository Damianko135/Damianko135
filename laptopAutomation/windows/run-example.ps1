#!/usr/bin/env pwsh
# Example usage script for Windows Laptop Automation
# Author: Damian Korver
# Description: Demonstrates different ways to run the setup

Write-Host "Windows Laptop Automation - Usage Examples" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Full Setup (Recommended):" -ForegroundColor Green
Write-Host "   .\setup.ps1" -ForegroundColor White
Write-Host "   - Installs all packages from packageList.json"
Write-Host "   - Sets up PowerShell profile with aliases and functions"
Write-Host ""

Write-Host "2. Packages Only:" -ForegroundColor Green
Write-Host "   .\setup.ps1 -SkipProfile" -ForegroundColor White
Write-Host "   - Installs packages but skips profile setup"
Write-Host ""

Write-Host "3. Profile Only:" -ForegroundColor Green
Write-Host "   .\setup.ps1 -SkipPackages" -ForegroundColor White
Write-Host "   - Sets up PowerShell profile but skips package installation"
Write-Host ""

Write-Host "4. Force Profile Overwrite:" -ForegroundColor Green
Write-Host "   .\setup.ps1 -Force" -ForegroundColor White
Write-Host "   - Forces overwrite of existing PowerShell profile"
Write-Host ""

Write-Host "5. Legacy Profile Setup:" -ForegroundColor Green
Write-Host "   .\profile.ps1" -ForegroundColor White
Write-Host "   - Uses the original profile setup script"
Write-Host ""

Write-Host "Prerequisites:" -ForegroundColor Yellow
Write-Host "- Run PowerShell as Administrator"
Write-Host "- Ensure internet connection for package downloads"
Write-Host "- PowerShell 7.0 or later recommended"
Write-Host ""

$choice = Read-Host "Would you like to run the full setup now? (y/N)"
if ($choice -eq 'y' -or $choice -eq 'Y') {
    Write-Host "Starting full setup..." -ForegroundColor Cyan
    .\setup.ps1
} else {
    Write-Host "Setup skipped. Run any of the above commands when ready." -ForegroundColor Gray
}
