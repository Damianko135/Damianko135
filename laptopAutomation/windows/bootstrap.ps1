#!/usr/bin/env pwsh
# Bootstrap Script for Windows Laptop Automation
# Author: Damian Korver
# Description: Downloads the latest release and runs the setup script
# This script is designed to be run in PowerShell 5.1 or later.
# Use the following command to run it on a fresh Windows installation:
# Aliases: IWR (Invoke-WebRequest); IEX (Invoke-Expression)
# iwr "https://raw.githubusercontent.com/Damianko135/Damianko135/main/laptopAutomation/windows/bootstrap.ps1" -OutFile "$env:TEMP\bootstrap.ps1"; powershell -nop -ep Bypass -f "$env:TEMP\bootstrap.ps1"
# Or use this one-liner:
# iwr "https://raw.githubusercontent.com/Damianko135/Damianko135/main/laptopAutomation/windows/bootstrap.ps1" | iex


#Requires -Version 5.1

param (
    [switch] $SkipPackages,
    [switch] $SkipProfile,
    [switch] $Force,
    [string] $DownloadPath = $env:TEMP,
    [switch] $SkipChecksumVerification,
    [switch] $EnableUpdateManagement,
    [switch] $SkipWindowsUpdates,
    [switch] $SkipPackageUpdates,
    [switch] $SkipStoreUpdates,
    [switch] $RebootIfRequired
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Security functions (inlined for bootstrap)
function Get-FileHashSHA256 {
    param([string]$FilePath)

    if (-not (Test-Path $FilePath)) {
        throw "File not found: $FilePath"
    }

    try {
        $hash = Get-FileHash -Path $FilePath -Algorithm SHA256
        return $hash.Hash.ToLower()
    } catch {
        # Fallback for older PowerShell versions
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $fileStream = [System.IO.File]::OpenRead($FilePath)
        try {
            $hashBytes = $sha256.ComputeHash($fileStream)
            return [BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()
        } finally {
            $fileStream.Close()
        }
    }
}

function Test-FileIntegrity {
    param([string]$FilePath, [string]$ExpectedHash)

    if (-not (Test-Path $FilePath)) {
        Write-Log "File not found for integrity check: $FilePath" Red
        return $false
    }

    try {
        $actualHash = Get-FileHashSHA256 -FilePath $FilePath
        $match = $actualHash -eq $ExpectedHash.ToLower()

        if ($match) {
            Write-Log "File integrity verified: $FilePath" Green
        } else {
            Write-Log "File integrity check failed for $FilePath" Red
            Write-Log "Expected: $ExpectedHash" Red
            Write-Log "Actual: $actualHash" Red
        }

        return $match
    } catch {
        Write-Log "Error during integrity check: $($_.Exception.Message)" Red
        return $false
    }
}

function Invoke-SecureWebRequest {
    param([string]$Uri, [string]$OutFile, [string]$ExpectedHash = $null)

    try {
        Write-Log "Downloading securely from: $Uri" Cyan

        # Use TLS 1.2 or higher
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

        # Disable progress bar for performance
        $oldProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'

        try {
            Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing
        } finally {
            $ProgressPreference = $oldProgressPreference
        }

        if ($ExpectedHash) {
            return Test-FileIntegrity -FilePath $OutFile -ExpectedHash $ExpectedHash
        }

        Write-Log "Download completed successfully" Green
        return $true
    } catch {
        Write-Log "Secure download failed: $($_.Exception.Message)" Red
        return $false
    }
}

function Test-CertificateValidation {
    param([string]$Uri)

    try {
        $request = [System.Net.WebRequest]::Create($Uri)
        $request.Method = "HEAD"
        $response = $request.GetResponse()
        $response.Close()
        Write-Log "Certificate validation passed for $Uri" Green
        return $true
    } catch {
        Write-Log "Certificate validation failed for $Uri : $($_.Exception.Message)" Red
        return $false
    }
}

# Logging function
function Write-Log {
    param([string]$Message, [ConsoleColor]$Color='White')
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

# Security audit logging
function Write-SecurityAuditLog {
    param([string]$Event, [string]$Details = "", [string]$Severity = "Info")

    $logEntry = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Event = $Event
        Details = $Details
        Severity = $Severity
        User = $env:USERNAME
        Computer = $env:COMPUTERNAME
    }

    $logFile = Join-Path $env:TEMP "bootstrap-security-audit.log"
    $logLine = "$($logEntry.Timestamp)|$($logEntry.Severity)|$($logEntry.Event)|$($logEntry.Details)|$($logEntry.User)|$($logEntry.Computer)"
    Add-Content -Path $logFile -Value $logLine

    Write-Log "Security Audit: $Event - $Details" Yellow
}

# Set the GitHub repository owner (username or organization)
$repoOwner = "Damianko135"
# Set the GitHub repository name
$repoName = "Damianko135"
$apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/releases/latest"
# NOTE: If the repository owner and name differ, update these variables accordingly.

Write-Log "Bootstrap: Windows Laptop Automation Setup" Cyan
Write-Log "Repository: $repoOwner/$repoName" Gray

try {
    # Download files directly from GitHub repository main branch
    Write-Log "Downloading automation files from GitHub repository..." Cyan

    $extractPath = Join-Path $DownloadPath "laptop-automation-temp"

    # Remove existing extraction directory
    if (Test-Path $extractPath) {
        Write-Log "Removing existing extraction directory..." Yellow
        Remove-Item $extractPath -Recurse -Force
    }

    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null

    # List of files to download
    $filesToDownload = @(
        "setup.ps1",
        "modules/BackupRestore.psm1",
        "modules/ComprehensiveLogging.psm1",
        "modules/ContainerSupport.psm1",
        "modules/HardwareDetector.psm1",
        "modules/InteractiveMode.psm1",
        "modules/PackageInstaller.psm1",
        "modules/PluginSystem.psm1",
        "modules/PostInstallSummary.psm1",
        "modules/ProgressTracker.psm1",
        "modules/SecurityValidator.psm1",
        "modules/Windows11Optimizer.psm1",
        "modules/ComplianceSecurity.psm1",
        "modules/UpdateManagement.psm1",
        "modules/InventoryManagement.psm1",
        "configs/custom.json",
        "configs/developer.json",
        "configs/gaming.json",
        "configs/minimal.json",
        "plugins/DevelopmentTools.json",
        "plugins/DevelopmentTools.ps1",
        "plugins/README.md",
        "packageList.json",
        "office-configuration.xml",
        "office.ps1",
        "profile-content.ps1",
        "Test-Automation.ps1"
    )

    foreach ($file in $filesToDownload) {
        $githubUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/main/laptopAutomation/windows/$file"
        $localPath = Join-Path $extractPath $file

        # Create directory if it doesn't exist
        $localDir = Split-Path $localPath -Parent
        if (-not (Test-Path $localDir)) {
            New-Item -ItemType Directory -Path $localDir -Force | Out-Null
        }

        Write-Log "Downloading $file..." Gray

        # Validate certificate before download
        if (-not (Test-CertificateValidation -Uri $githubUrl)) {
            Write-SecurityAuditLog -Event "CertificateValidationFailed" -Details "Certificate validation failed for $githubUrl" -Severity "Error"
            throw "Certificate validation failed for $githubUrl"
        }

        # Download the file
        if (-not (Invoke-SecureWebRequest -Uri $githubUrl -OutFile $localPath)) {
            throw "Failed to download $file"
        }
    }

    Write-Log "All files downloaded successfully" Green
    
    # Find the setup script (look for it in the extracted contents)
    Write-Log "Searching for setup.ps1..." Cyan
    $setupScript = Get-ChildItem $extractPath -Recurse -File -Filter "setup.ps1" | Select-Object -First 1
    
    if ($setupScript) {
        $setupScriptPath = $setupScript.FullName
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
    if ($EnableUpdateManagement) { $arguments += "-EnableUpdateManagement" }
    if ($SkipWindowsUpdates) { $arguments += "-SkipWindowsUpdates" }
    if ($SkipPackageUpdates) { $arguments += "-SkipPackageUpdates" }
    if ($SkipStoreUpdates) { $arguments += "-SkipStoreUpdates" }
    if ($RebootIfRequired) { $arguments += "-RebootIfRequired" }
    
    # Run the setup script
    if ($arguments.Count -gt 0) {
        & $setupScriptPath @arguments
    } else {
        & $setupScriptPath
    }
    $setupSucceeded = $?
    
    if ($setupSucceeded) {
        Write-Log "Setup completed successfully!" Green
    } else {
        Write-Log "Setup script failed to complete successfully." Red
        exit 1
    }
} catch {
    Write-Log "Bootstrap failed: $($_.Exception.Message)" Red
    Write-Log "Error details: $($_.ScriptStackTrace)" Red
    exit 1
} finally {
    # Cleanup downloaded files
    try {
        if (Test-Path $extractPath) {
            Write-Log "Cleaning up downloaded files..." Gray
            Remove-Item $extractPath -Recurse -Force
        }
    } catch {
        Write-Log "Warning: Could not clean up temporary files: $($_.Exception.Message)" Yellow
    }
}

Write-Log "Bootstrap completed!" Green
