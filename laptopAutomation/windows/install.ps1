#!/usr/bin/env pwsh
# Windows Laptop Automation - One-Line Bootstrap
# Usage: iwr https://raw.githubusercontent.com/Damianko135/Damianko135/main/laptopAutomation/windows/install.ps1 | iex

param (
    [switch] $SkipPackages,
    [switch] $SkipProfile,
    [switch] $Force,
    [string] $Branch = "main"
)

$repo = "Damianko135/Damianko135"
$tempDir = Join-Path $env:TEMP "laptop-automation-$(Get-Random)"

function Write-Status($msg, $color = "White") {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg" -ForegroundColor $color
}

try {
    Write-Host ""
    Write-Host "🚀 Windows Laptop Automation - Quick Setup" -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor Cyan
    
    # Download latest files
    Write-Status "Downloading automation files..." "Cyan"
    $zipUrl = "https://github.com/$repo/archive/refs/heads/$Branch.zip"
    $zipFile = Join-Path $env:TEMP "laptop-automation.zip"
    
    try {
        (New-Object System.Net.WebClient).DownloadFile($zipUrl, $zipFile)
        Write-Status "Download completed" "Green"
    } catch {
        Write-Status "Failed to download from GitHub: $($_.Exception.Message)" "Red"
        Write-Status "This might be because the repository doesn't exist or is private." "Yellow"
        Write-Status "Please check the repository URL: https://github.com/$repo" "Yellow"
        throw "Download failed"
    }
    
    # Extract
    Write-Status "Extracting files..." "Cyan"
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile, $tempDir)
    
    # Find windows folder
    $windowsPath = $null
    
    # First try to find laptopAutomation/windows
    $windowsPath = Get-ChildItem $tempDir -Directory | 
        ForEach-Object { Join-Path $_.FullName "laptopAutomation\windows" } | 
        Where-Object { Test-Path $_ } | 
        Select-Object -First 1
    
    # Fallback to just windows folder
    if (-not $windowsPath) {
        $windowsPath = Get-ChildItem $tempDir -Directory | 
            ForEach-Object { Join-Path $_.FullName "windows" } | 
            Where-Object { Test-Path $_ } | 
            Select-Object -First 1
    }
    
    if (-not $windowsPath) {
        throw "Windows automation folder not found"
    }
    
    Write-Status "Found automation files at: $windowsPath" "Green"
    
    # Execute setup
    $setupScript = Join-Path $windowsPath "setup.ps1"
    if (-not (Test-Path $setupScript)) {
        throw "Setup script not found at: $setupScript"
    }
    
    Write-Status "Starting setup..." "Cyan"
    Push-Location $windowsPath
    
    $args = @()
    if ($SkipPackages) { $args += "-SkipPackages" }
    if ($SkipProfile) { $args += "-SkipProfile" }
    if ($Force) { $args += "-Force" }
    
    if ($args) {
        & $setupScript @args
    } else {
        & $setupScript
    }
    
    Pop-Location
    Write-Status "Setup completed! 🎉" "Green"
    
} catch {
    Write-Status "Error: $($_.Exception.Message)" "Red"
    exit 1
} finally {
    # Cleanup
    if (Test-Path $zipFile) { Remove-Item $zipFile -Force -ErrorAction SilentlyContinue }
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
}
