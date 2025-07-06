#!/usr/bin/env pwsh
# Windows Laptop Automation Bootstrap Script
# Author: Damian Korver
# Description: Downloads the latest release and runs the setup automatically
# Usage: iwr https://raw.githubusercontent.com/Damianko135/Damianko135/main/laptopAutomation/windows/bootstrap.ps1 | iex

#Requires -Version 5.1 

param (
    [string] $GitHubRepo = "Damianko135/Damianko135",
    [string] $Branch = "main",
    [switch] $SkipPackages,
    [switch] $SkipProfile,
    [switch] $Force,
    [switch] $UseLatestRelease,
    [string] $TempDir = $env:TEMP
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Console colors and logging
function Write-Log {
    param([string]$Message, [ConsoleColor]$Color='White')
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

function Write-Banner {
    Write-Host ""
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host "    Windows Laptop Automation Bootstrap" -ForegroundColor Cyan
    Write-Host "    Author: Damian Korver" -ForegroundColor Cyan
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host ""
}

# Check if running as administrator
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Get latest release info from GitHub
function Get-LatestRelease {
    param([string]$Repository)
    
    try {
        Write-Log "Fetching latest release information..." Cyan
        $apiUrl = "https://api.github.com/repos/$Repository/releases/latest"
        $headers = @{
            'User-Agent' = 'PowerShell-Bootstrap-Script'
            'Accept' = 'application/vnd.github.v3+json'
        }
        
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop
        
        # Look for a zip asset
        $zipAsset = $response.assets | Where-Object { $_.name -like "*.zip" -and $_.name -like "*windows*" } | Select-Object -First 1
        
        if (-not $zipAsset) {
            # Fallback to any zip file
            $zipAsset = $response.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
        }
        
        if ($zipAsset) {
            return @{
                DownloadUrl = $zipAsset.browser_download_url
                FileName = $zipAsset.name
                Version = $response.tag_name
            }
        } else {
            throw "No zip asset found in latest release"
        }
    } catch {
        Write-Log "Failed to get latest release: $($_.Exception.Message)" Red
        return $null
    }
}

# Download and extract files
function Download-AndExtract {
    param(
        [string]$DownloadUrl,
        [string]$FileName,
        [string]$ExtractPath
    )
    
    try {
        $zipPath = Join-Path $TempDir $FileName
        
        Write-Log "Downloading $FileName..." Cyan
        Write-Log "From: $DownloadUrl" Gray
        Write-Log "To: $zipPath" Gray
        
        # Download with progress
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($DownloadUrl, $zipPath)
        
        Write-Log "Download completed successfully" Green
        
        # Extract ZIP file
        Write-Log "Extracting to: $ExtractPath..." Cyan
        
        if (Test-Path $ExtractPath) {
            Remove-Item $ExtractPath -Recurse -Force
        }
        New-Item -ItemType Directory -Path $ExtractPath -Force | Out-Null
        
        # Use built-in ZIP extraction
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $ExtractPath)
        
        Write-Log "Extraction completed successfully" Green
        
        # Clean up zip file
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
        
        return $true
    } catch {
        Write-Log "Failed to download and extract: $($_.Exception.Message)" Red
        return $false
    }
}

# Download from branch (fallback method)
function Download-FromBranch {
    param(
        [string]$Repository,
        [string]$Branch,
        [string]$ExtractPath
    )
    
    try {
        $zipUrl = "https://github.com/$Repository/archive/refs/heads/$Branch.zip"
        $fileName = "$Branch.zip"
        
        Write-Log "Downloading from branch $Branch..." Cyan
        $success = Download-AndExtract -DownloadUrl $zipUrl -FileName $fileName -ExtractPath $ExtractPath
        
        if ($success) {
            # GitHub archives extract to a subfolder, find the windows folder
            $extractedFolders = Get-ChildItem $ExtractPath -Directory
            $windowsPath = $null
            
            foreach ($folder in $extractedFolders) {
                # Look for laptopAutomation/windows path
                $potentialLaptopPath = Join-Path $folder.FullName "laptopAutomation"
                if (Test-Path $potentialLaptopPath) {
                    $potentialWindowsPath = Join-Path $potentialLaptopPath "windows"
                    if (Test-Path $potentialWindowsPath) {
                        $windowsPath = $potentialWindowsPath
                        break
                    }
                }
                
                # Fallback: look for just windows folder
                $potentialWindowsPath = Join-Path $folder.FullName "windows"
                if (Test-Path $potentialWindowsPath) {
                    $windowsPath = $potentialWindowsPath
                    break
                }
            }
            
            if ($windowsPath) {
                Write-Log "Found windows folder at: $windowsPath" Green
                return $windowsPath
            } else {
                Write-Log "Windows folder not found in extracted archive" Red
                return $null
            }
        }
        
        return $null
    } catch {
        Write-Log "Failed to download from branch: $($_.Exception.Message)" Red
        return $null
    }
}

# Find setup script in extracted files
function Find-SetupScript {
    param([string]$ExtractPath)
    
    # Look for setup.ps1 in various locations
    $possiblePaths = @(
        (Join-Path $ExtractPath "setup.ps1"),
        (Join-Path $ExtractPath "windows\setup.ps1"),
        (Join-Path $ExtractPath "laptopAutomation\windows\setup.ps1"),
        (Join-Path $ExtractPath "*\laptopAutomation\windows\setup.ps1"),
        (Join-Path $ExtractPath "*\windows\setup.ps1")
    )
    
    foreach ($path in $possiblePaths) {
        $found = Get-ChildItem $path -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            Write-Log "Found setup script at: $($found.FullName)" Green
            return $found.FullName
        }
    }
    
    # Search recursively as last resort
    Write-Log "Searching recursively for setup.ps1..." Yellow
    $found = Get-ChildItem $ExtractPath -Name "setup.ps1" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $fullPath = Join-Path $ExtractPath $found
        Write-Log "Found setup script at: $fullPath" Green
        return $fullPath
    }
    
    return $null
}

# Main execution
Write-Banner

Write-Log "Starting Windows Laptop Automation Bootstrap" Cyan
Write-Log "Repository: $GitHubRepo" Gray
Write-Log "Branch: $Branch" Gray
Write-Log "Use Latest Release: $UseLatestRelease" Gray

# Create unique temp directory for this session
$sessionId = [System.Guid]::NewGuid().ToString().Substring(0, 8)
$workingDir = Join-Path $TempDir "laptop-automation-$sessionId"
New-Item -ItemType Directory -Path $workingDir -Force | Out-Null
Write-Log "Working directory: $workingDir" Gray

$setupScriptPath = $null

try {
    if ($UseLatestRelease) {
        # Try to get latest release
        Write-Log "Attempting to download from latest release..." Cyan
        $releaseInfo = Get-LatestRelease -Repository $GitHubRepo
        
        if ($releaseInfo) {
            Write-Log "Latest release: $($releaseInfo.Version)" Green
            $success = Download-AndExtract -DownloadUrl $releaseInfo.DownloadUrl -FileName $releaseInfo.FileName -ExtractPath $workingDir
            
            if ($success) {
                $setupScriptPath = Find-SetupScript -ExtractPath $workingDir
            }
        }
    }
    
    # Fallback to branch download if release method failed
    if (-not $setupScriptPath) {
        Write-Log "Falling back to branch download method..." Yellow
        $windowsPath = Download-FromBranch -Repository $GitHubRepo -Branch $Branch -ExtractPath $workingDir
        
        if ($windowsPath) {
            $setupScriptPath = Join-Path $windowsPath "setup.ps1"
            if (-not (Test-Path $setupScriptPath)) {
                $setupScriptPath = Find-SetupScript -ExtractPath $workingDir
            }
        }
    }
    
    if (-not $setupScriptPath -or -not (Test-Path $setupScriptPath)) {
        throw "Could not find setup.ps1 script in downloaded files"
    }
    
    # Prepare setup arguments
    $setupArgs = @()
    if ($SkipPackages) { $setupArgs += "-SkipPackages" }
    if ($SkipProfile) { $setupArgs += "-SkipProfile" }
    if ($Force) { $setupArgs += "-Force" }
    
    Write-Log "Executing setup script..." Cyan
    Write-Log "Script: $setupScriptPath" Gray
    Write-Log "Arguments: $($setupArgs -join ' ')" Gray
    
    # Check if we need admin privileges
    if (-not $SkipPackages -and -not (Test-IsAdmin)) {
        Write-Log "Package installation requires administrator privileges." Yellow
        Write-Log "Current session is not running as administrator." Yellow
        Write-Log "Options:" Yellow
        Write-Log "  1. Restart PowerShell as Administrator and run this script again" Yellow
        Write-Log "  2. Add -SkipPackages to only setup the PowerShell profile" Yellow
        Write-Log "  3. Continue anyway (setup script will handle admin check)" Yellow
        
        $choice = Read-Host "Continue anyway? (y/N)"
        if ($choice -ne 'y' -and $choice -ne 'Y') {
            Write-Log "Setup cancelled by user" Yellow
            exit 0
        }
    }
    
    # Change to script directory for execution
    $scriptDir = Split-Path $setupScriptPath
    Push-Location $scriptDir
    
    try {
        # Execute setup script
        if ($setupArgs.Count -gt 0) {
            & $setupScriptPath @setupArgs
        } else {
            & $setupScriptPath
        }
        
        Write-Log "Setup script execution completed" Green
    } finally {
        Pop-Location
    }
    
} catch {
    Write-Log "Bootstrap failed: $($_.Exception.Message)" Red
    Write-Log "Stack trace: $($_.ScriptStackTrace)" Red
    exit 1
} finally {
    # Cleanup
    Write-Log "Cleaning up temporary files..." Gray
    try {
        if (Test-Path $workingDir) {
            Remove-Item $workingDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Log "Could not clean up temporary directory: $workingDir" Yellow
    }
}

Write-Log "Bootstrap completed successfully!" Green
Write-Log "If profile was configured, restart PowerShell to apply changes." Cyan
