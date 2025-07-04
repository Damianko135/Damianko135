#!/usr/bin/env pwsh
# Bootstrap Script - Downloads and runs Windows Environment Setup from GitHub
# Author: Damian Korver
# Description: One-line setup that fetches and executes the complete automation from GitHub

Write-Host "Starting Windows Environment Bootstrap..." -ForegroundColor Green

# GitHub repository archive URL
$ZipURL = "https://github.com/Damianko135/laptopAutomation/archive/refs/heads/main.zip"

# Download the zip file
$ZipFile = "$env:TEMP\bootstrap.zip"
Invoke-WebRequest -Uri $ZipURL -OutFile $ZipFile
if (-not (Test-Path $ZipFile)) {
    Write-Host "Failed to download bootstrap.zip from GitHub." -ForegroundColor Red
    exit 1
}

# Extract the zip file
$ExtractPath = "$env:TEMP\bootstrap"
if (-not (Test-Path $ExtractPath)) {
    New-Item -ItemType Directory -Path $ExtractPath | Out-Null
}   
Expand-Archive -Path $ZipFile -DestinationPath $ExtractPath -Force

# The extracted setup.ps1 in '.\setup.ps1'
$SetupScript = Join-Path $ExtractPath ".\setup.ps1"
if (-not (Test-Path $SetupScript)) {
    Write-Host "Failed to extract setup.ps1 from bootstrap.zip." -ForegroundColor Red
    exit 1
}
# Run the setup script
& powershell.exe -ExecutionPolicy Bypass -File $SetupScript
if ($LASTEXITCODE -ne 0) {
    Write-Host "Setup script failed with exit code $LASTEXITCODE." -ForegroundColor Red
    exit $LASTEXITCODE
}
# Cleanup temporary files
Remove-Item -Path $ZipFile, $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Windows Environment Bootstrap completed successfully!" -ForegroundColor Green
exit 0
