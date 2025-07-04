#!/usr/bin/env pwsh
# Bootstrap Script - Downloads and runs Windows Environment Setup from GitHub
# Author: Damian Korver
# Description: One-line setup that fetches and executes the complete automation from GitHub

Write-Host "Starting Windows Environment Bootstrap..." -ForegroundColor Green

# GitHub repository base URL
$BaseURL = "https://raw.githubusercontent.com/Damianko135/laptopAutomation/refs/heads/main/windows"

# Create temporary directory
$TempDir = Join-Path $env:TEMP "WindowsSetup"
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

# All files to download
$FilesToDownload = @(
    "packagelist.json",
    "packageManagers.json",
    "ensureAdmin.ps1",
    "packageManagers.ps1", 
    "installPackages.ps1",
    "profile.ps1"
)

try {
    # Download all files to temp directory
    foreach ($file in $FilesToDownload) {
        Write-Host "Downloading $file..." -ForegroundColor Yellow
        $filePath = Join-Path $TempDir $file
        Invoke-WebRequest -Uri "$BaseURL/$file" -OutFile $filePath -UseBasicParsing
    }
    
    # Change to temp directory and execute scripts in order
    Push-Location $TempDir
    
    Write-Host "Ensuring administrator privileges..." -ForegroundColor Cyan
    & ".\ensureAdmin.ps1"
    
    Write-Host "Setting up package managers..." -ForegroundColor Cyan
    & ".\packageManagers.ps1"
    
    Write-Host "Installing packages..." -ForegroundColor Cyan
    & ".\installPackages.ps1"
    
    Write-Host "Setting up PowerShell profile..." -ForegroundColor Cyan
    & ".\profile.ps1"
    
    Write-Host "Bootstrap setup completed!" -ForegroundColor Green
    
} catch {
    Write-Host "Bootstrap failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    # Cleanup
    Pop-Location
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}