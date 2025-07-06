#!/usr/bin/env pwsh
# Bootstrap Script for Windows Laptop Automation
# Author: Damian Korver
# Description: Downloads the latest release and runs the setup script

#Requires -Version 7.0

param (
    [switch] $SkipPackages,
    [switch] $SkipProfile,
    [switch] $Force,
    [string] $DownloadPath = $env:TEMP
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Logging function
function Write-Log {
    param([string]$Message, [ConsoleColor]$Color='White')
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

# GitHub repository information
$repoOwner = "Damianko135"
$repoName = "Damianko135"
$apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/releases/latest"

Write-Log "Bootstrap: Windows Laptop Automation Setup" Cyan
Write-Log "Repository: $repoOwner/$repoName" Gray

try {
    # Get latest release information
    Write-Log "Fetching latest release information..." Cyan
    $latestRelease = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell-Bootstrap" }
    
    $tagName = $latestRelease.tag_name
    $releaseName = $latestRelease.name
    Write-Log "Latest release: $releaseName ($tagName)" Green
    
    # Find the Windows automation zip asset
    $windowsAsset = $latestRelease.assets | Where-Object { $_.name -like "*windows*" -or $_.name -like "*laptopAutomation*" }
    
    if (-not $windowsAsset) {
        # Fallback to any zip asset
        $windowsAsset = $latestRelease.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
    }
    
    if (-not $windowsAsset) {
        Write-Log "No suitable zip asset found in release. Available assets:" Yellow
        $latestRelease.assets | ForEach-Object { Write-Log "  - $($_.name)" Gray }
        throw "No zip asset found in the latest release"
    }
    
    # Use the release asset download URL
    $downloadUrl = $windowsAsset.browser_download_url
    $zipFileName = $windowsAsset.name
    $zipFilePath = Join-Path $DownloadPath $zipFileName
    
    Write-Log "Selected asset: $($windowsAsset.name)" Green
    
    # Download the latest release
    Write-Log "Downloading release from: $downloadUrl" Cyan
    Write-Log "Saving to: $zipFilePath" Gray
    
    # Remove existing zip if it exists
    if (Test-Path $zipFilePath) {
        Write-Log "Removing existing zip file..." Yellow
        Remove-Item $zipFilePath -Force
    }
    
    # Download with progress
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($downloadUrl, $zipFilePath)
    
    if (-not (Test-Path $zipFilePath)) {
        throw "Failed to download the release zip file"
    }
    
    Write-Log "Download completed successfully" Green
    
    # Extract the zip file
    $extractPath = Join-Path $DownloadPath "laptop-automation-temp"
    
    # Remove existing extraction directory
    if (Test-Path $extractPath) {
        Write-Log "Removing existing extraction directory..." Yellow
        Remove-Item $extractPath -Recurse -Force
    }
    
    Write-Log "Extracting to: $extractPath" Cyan
    Expand-Archive -Path $zipFilePath -DestinationPath $extractPath -Force
    
    # Find the setup script (look for it in the extracted contents)
    Write-Log "Searching for setup.ps1..." Cyan
    $setupScriptPath = Get-ChildItem $extractPath -Recurse -Name "setup.ps1" | Select-Object -First 1
    
    if ($setupScriptPath) {
        $setupScriptPath = Join-Path $extractPath $setupScriptPath
        Write-Log "Found setup script: $setupScriptPath" Green
    } else {
        Write-Log "Setup script not found. Listing extracted contents:" Yellow
        Get-ChildItem $extractPath -Recurse | ForEach-Object {
            Write-Log "  $($_.FullName)" Gray
        }
        throw "Could not find setup.ps1 in the extracted files"
    }
    
    # Build arguments for the setup script
    $arguments = @()
    if ($SkipPackages) { $arguments += "-SkipPackages" }
    if ($SkipProfile) { $arguments += "-SkipProfile" }
    if ($Force) { $arguments += "-Force" }
    
    # Run the setup script
    Write-Log "Running setup script with arguments: $($arguments -join ' ')" Cyan
    Write-Log "Working directory: $(Split-Path $setupScriptPath)" Gray
    
    # Change to the script directory and run it
    Push-Location (Split-Path $setupScriptPath)
    try {
        if ($arguments.Count -gt 0) {
            & $setupScriptPath @arguments
        } else {
            & $setupScriptPath
        }
        $setupExitCode = $LASTEXITCODE
    } finally {
        Pop-Location
    }
    
    if ($setupExitCode -eq 0 -or $null -eq $setupExitCode) {
        Write-Log "Setup completed successfully!" Green
    } else {
        Write-Log "Setup script exited with code: $setupExitCode" Red
        exit $setupExitCode
    }
    
} catch {
    Write-Log "Bootstrap failed: $($_.Exception.Message)" Red
    Write-Log "Error details: $($_.ScriptStackTrace)" Red
    exit 1
} finally {
    # Cleanup downloaded files
    try {
        if (Test-Path $zipFilePath) {
            Write-Log "Cleaning up downloaded zip file..." Gray
            Remove-Item $zipFilePath -Force
        }
        
        if (Test-Path $extractPath) {
            Write-Log "Cleaning up extracted files..." Gray
            Remove-Item $extractPath -Recurse -Force
        }
    } catch {
        Write-Log "Warning: Could not clean up temporary files: $($_.Exception.Message)" Yellow
    }
}

Write-Log "Bootstrap completed!" Green
