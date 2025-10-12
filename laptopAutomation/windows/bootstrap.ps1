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
    [switch] $SkipChecksumVerification
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
    # Get latest release information
    Write-Log "Fetching latest release information..." Cyan
    $latestRelease = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell-Bootstrap" }
    
    $tagName = $latestRelease.tag_name
    $releaseName = $latestRelease.name
    Write-Log "Latest release: $releaseName ($tagName)" Green
    
    # Find the Windows automation zip asset
    $windowsAsset = $latestRelease.assets | Where-Object { $_.name -like "*Bootstrap*" }
    
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

    # Check for checksum file
    $expectedHash = $null
    if (-not $SkipChecksumVerification) {
        $checksumAsset = $latestRelease.assets | Where-Object { $_.name -eq "$zipFileName.sha256" -or $_.name -eq "$zipFileName.SHA256" }
        if ($checksumAsset) {
            Write-Log "Found checksum file: $($checksumAsset.name)" Green
            Write-SecurityAuditLog -Event "ChecksumFileFound" -Details "Checksum file located: $($checksumAsset.name)" -Severity "Info"
            $checksumUrl = $checksumAsset.browser_download_url
            $checksumPath = Join-Path $DownloadPath "$zipFileName.sha256"

            if (Invoke-SecureWebRequest -Uri $checksumUrl -OutFile $checksumPath) {
                $expectedHash = Get-Content $checksumPath | Select-Object -First 1
                Write-Log "Expected SHA256: $expectedHash" Gray
            }
        } else {
            Write-Log "No checksum file found, skipping integrity verification" Yellow
            Write-SecurityAuditLog -Event "ChecksumFileMissing" -Details "No checksum file found for $zipFileName" -Severity "Warning"
        }
    }

    # Download with security validation
    Write-Log "Downloading release from: $downloadUrl" Cyan
    Write-Log "Saving to: $zipFilePath" Gray

    # Remove existing zip if it exists
    if (Test-Path $zipFilePath) {
        Write-Log "Removing existing zip file..." Yellow
        Remove-Item $zipFilePath -Force
    }

    # Validate certificate before download
    if (-not (Test-CertificateValidation -Uri $downloadUrl)) {
        Write-SecurityAuditLog -Event "CertificateValidationFailed" -Details "Certificate validation failed for $downloadUrl" -Severity "Error"
        throw "Certificate validation failed for download URL"
    }

    Write-SecurityAuditLog -Event "DownloadStarted" -Details "Starting download from $downloadUrl" -Severity "Info"

    # Use secure download function
    $downloadSuccess = Invoke-SecureWebRequest -Uri $downloadUrl -OutFile $zipFilePath -ExpectedHash $expectedHash
    if (-not $downloadSuccess) {
        Write-SecurityAuditLog -Event "DownloadFailed" -Details "Download or verification failed for $zipFilePath" -Severity "Error"
        throw "Failed to download or verify the release zip file"
    }

    Write-SecurityAuditLog -Event "DownloadCompleted" -Details "Successfully downloaded and verified $zipFilePath" -Severity "Info"
    
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
    
    # Use Expand-Archive with PowerShell 5.1+ compatibility
    if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
        Expand-Archive -Path $zipFilePath -DestinationPath $extractPath -Force
    } else {
        # Fallback for very old PowerShell versions
        Write-Log "Expand-Archive not available, using .NET extraction..." Yellow
        if (-not ("System.IO.Compression.ZipFile" -as [type])) {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
        }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFilePath, $extractPath)
    }
    
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
    
    # Run the setup script
        if ($arguments.Count -gt 0) {
            & $setupScriptPath @arguments
        } else {
            & $setupScriptPath
        }
        $setupSucceeded = $?
    } finally {
        Pop-Location
    }
    
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
